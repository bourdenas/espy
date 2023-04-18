use crate::{
    documents::{GameEntry, StoreEntry},
    util::rate_limiter::RateLimiter,
    Status,
};
use serde::{Deserialize, Serialize};
use std::{sync::Arc, time::Duration};
use tracing::{error, instrument, trace_span, Instrument};

use super::{
    backend::post,
    docs, ranking,
    resolve::{
        get_cover, resolve_game_digest, resolve_game_info, EXTERNAL_GAMES_ENDPOINT, GAMES_ENDPOINT,
    },
    IgdbConnection, IgdbGame,
};

#[derive(Clone)]
pub struct IgdbApi {
    secret: String,
    client_id: String,
    connection: Option<Arc<IgdbConnection>>,
}

impl IgdbApi {
    pub fn new(client_id: &str, secret: &str) -> IgdbApi {
        IgdbApi {
            secret: String::from(secret),
            client_id: String::from(client_id),
            connection: None,
        }
    }

    /// Authenticate with twtich/igdb OAuth2 server and retrieve session token.
    /// Authentication is valid for the lifetime of this instane or until the
    /// retrieved token expires.
    pub async fn connect(&mut self) -> Result<(), Status> {
        let uri = format!(
            "{TWITCH_OAUTH_URL}?client_id={}&client_secret={}&grant_type=client_credentials",
            self.client_id, self.secret
        );

        let resp = reqwest::Client::new()
            .post(&uri)
            .send()
            .await?
            .json::<TwitchOAuthResponse>()
            .await?;

        self.connection = Some(Arc::new(IgdbConnection {
            client_id: self.client_id.clone(),
            oauth_token: resp.access_token,
            qps: RateLimiter::new(4, Duration::from_secs(1), 6),
        }));

        Ok(())
    }

    pub fn connection(&self) -> Result<Arc<IgdbConnection>, Status> {
        match &self.connection {
            Some(connection) => Ok(Arc::clone(connection)),
            None => Err(Status::internal(
                "Connection with IGDB was not established.",
            )),
        }
    }

    /// Returns a GameEntry based on its IGDB `id`.
    ///
    /// The returned GameEntry is a shallow lookup. Reference ids are not
    /// followed up and thus it is not fully resolved.
    #[instrument(level = "trace", skip(self))]
    pub async fn get(&self, id: u64) -> Result<IgdbGame, Status> {
        let connection = self.connection()?;
        let result: Vec<IgdbGame> = post(
            &connection,
            GAMES_ENDPOINT,
            &format!("fields *; where id={id};"),
        )
        .await?;

        match result.into_iter().next() {
            Some(igdb_game) => Ok(igdb_game),
            None => Err(Status::not_found("IgdbGame with id={id} was not found.")),
        }
    }

    /// Returns a GameEntry based on external id info in IGDB.
    ///
    /// The returned GameEntry is a shallow lookup. Reference ids are not
    /// followed up and thus it is not fully resolved.
    #[instrument(level = "trace", skip(self))]
    pub async fn get_by_store_entry(
        &self,
        store_entry: &StoreEntry,
    ) -> Result<Option<GameEntry>, Status> {
        let category: u8 = match store_entry.storefront_name.as_ref() {
            "steam" => 1,
            "gog" => 5,
            // "egs" => 26,
            "egs" => return Ok(None),
            _ => return Ok(None),
        };

        let connection = self.connection()?;
        let result: Vec<docs::ExternalGame> = post(
            &connection,
            EXTERNAL_GAMES_ENDPOINT,
            &format!(
                "fields *; where uid = \"{}\" & category = {category};",
                store_entry.id
            ),
        )
        .await?;

        match result.into_iter().next() {
            Some(external_game) => Ok(Some(GameEntry::from(self.get(external_game.game).await?))),
            None => Ok(None),
        }
    }

    /// Returns a GameEntry based on its IGDB `id`.
    ///
    /// The returned GameEntry is a shallow copy but it contains a game cover image.
    #[instrument(level = "trace", skip(self))]
    pub async fn get_with_cover(&self, id: u64) -> Result<Option<GameEntry>, Status> {
        let connection = self.connection()?;

        let result: Vec<IgdbGame> = post(
            &connection,
            GAMES_ENDPOINT,
            &format!("fields *; where id={id};"),
        )
        .await?;

        match result.into_iter().next() {
            Some(igdb_game) => {
                let cover = match igdb_game.cover {
                    Some(cover_id) => get_cover(&connection, cover_id).await?,
                    None => None,
                };

                let mut game_entry = GameEntry::from(igdb_game);
                game_entry.cover = cover;
                Ok(Some(game_entry))
            }
            None => Ok(None),
        }
    }

    /// Returns candidate GameEntries by searching IGDB based on game title.
    ///
    /// The returned GameEntries are shallow lookups. Reference ids are not
    /// followed up and thus they are not fully resolved.
    #[instrument(level = "trace", skip(self))]
    pub async fn search_by_title(&self, title: &str) -> Result<Vec<GameEntry>, Status> {
        Ok(ranking::sorted_by_relevance(
            title,
            self.search(title)
                .await?
                .into_iter()
                .map(|igdb_game| GameEntry::from(igdb_game))
                .collect(),
        ))
    }

    /// Returns candidate GameEntries by searching IGDB based on game title.
    ///
    /// The returned GameEntries are shallow lookups similar to
    /// `search_by_title()`, but have their cover image resolved.
    #[instrument(level = "trace", skip(self))]
    pub async fn search_by_title_with_cover(
        &self,
        title: &str,
        base_games_only: bool,
    ) -> Result<Vec<GameEntry>, Status> {
        let mut igdb_games = self.search(title).await?;
        if base_games_only {
            igdb_games.retain(|game| game.parent_game.is_none());
        }

        let connection = self.connection()?;
        let mut handles = vec![];
        for game in igdb_games {
            let connection = Arc::clone(&connection);
            handles.push(tokio::spawn(
                async move {
                    let cover = match game.cover {
                        Some(id) => match get_cover(&connection, id).await {
                            Ok(cover) => cover,
                            Err(e) => {
                                error!("Failed to retrieve cover: {e}");
                                None
                            }
                        },
                        None => None,
                    };

                    let mut game_entry = GameEntry::from(game);
                    game_entry.cover = cover;
                    game_entry
                }
                .instrument(trace_span!("spawn_get_cover")),
            ));
        }

        Ok(ranking::sorted_by_relevance_with_threshold(
            title,
            futures::future::join_all(handles)
                .await
                .into_iter()
                .filter_map(|x| x.ok())
                .collect::<Vec<_>>(),
            1.0,
        ))
    }

    async fn search(&self, title: &str) -> Result<Vec<IgdbGame>, Status> {
        let title = title.replace("\"", "");
        let connection = self.connection()?;
        post::<Vec<IgdbGame>>(
            &connection,
            GAMES_ENDPOINT,
            &format!("search \"{title}\"; fields *; where platforms = (6);"),
        )
        .await
    }

    #[instrument(level = "trace", skip(self))]
    pub async fn resolve(&self, igdb_game: IgdbGame) -> Result<GameEntry, Status> {
        let connection = self.connection()?;

        let mut game_entry = resolve_game_digest(Arc::clone(&connection), &igdb_game).await?;
        resolve_game_info(connection, igdb_game, &mut game_entry).await?;

        Ok(game_entry)
    }
}

pub const TWITCH_OAUTH_URL: &str = "https://id.twitch.tv/oauth2/token";

#[derive(Debug, Serialize, Deserialize)]
struct TwitchOAuthResponse {
    access_token: String,
    expires_in: i32,
}
