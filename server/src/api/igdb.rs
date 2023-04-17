use crate::{
    documents::{
        Collection, CollectionType, Company, CompanyRole, GameCategory, GameDigest, GameEntry,
        Image, StoreEntry, Website, WebsiteAuthority,
    },
    util::rate_limiter::RateLimiter,
    Status,
};
use async_recursion::async_recursion;
use serde::{de::DeserializeOwned, Deserialize, Serialize};
use std::{sync::Arc, time::Duration};
use tokio::sync::mpsc;
use tracing::{error, instrument, trace_span, Instrument};

use super::{
    igdb_docs::{self, Annotation},
    igdb_ranking, IgdbGame,
};

pub struct IgdbApi {
    secret: String,
    client_id: String,
    state: Option<Arc<IgdbApiState>>,
}

#[derive(Debug)]
struct IgdbApiState {
    client_id: String,
    oauth_token: String,
    qps: RateLimiter,
}

impl IgdbApi {
    pub fn new(client_id: &str, secret: &str) -> IgdbApi {
        IgdbApi {
            secret: String::from(secret),
            client_id: String::from(client_id),
            state: None,
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

        self.state = Some(Arc::new(IgdbApiState {
            client_id: self.client_id.clone(),
            oauth_token: resp.access_token,
            qps: RateLimiter::new(4, Duration::from_secs(1), 6),
        }));

        Ok(())
    }

    fn igdb_state(&self) -> Result<Arc<IgdbApiState>, Status> {
        match &self.state {
            Some(state) => Ok(Arc::clone(state)),
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
    pub async fn get(&self, id: u64) -> Result<Option<GameEntry>, Status> {
        let igdb_state = self.igdb_state()?;
        let result: Vec<IgdbGame> = post(
            &igdb_state,
            GAMES_ENDPOINT,
            &format!("fields *; where id={id};"),
        )
        .await?;

        match result.into_iter().next() {
            Some(igdb_game) => Ok(Some(GameEntry::from(igdb_game))),
            None => Ok(None),
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

        let igdb_state = self.igdb_state()?;
        let result: Vec<igdb_docs::ExternalGame> = post(
            &igdb_state,
            EXTERNAL_GAMES_ENDPOINT,
            &format!(
                "fields *; where uid = \"{}\" & category = {category};",
                store_entry.id
            ),
        )
        .await?;

        match result.into_iter().next() {
            Some(external_game) => self.get(external_game.game).await,
            None => Ok(None),
        }
    }

    /// Returns a GameEntry based on its IGDB `id`.
    ///
    /// The returned GameEntry is a shallow copy but it contains a game cover image.
    #[instrument(level = "trace", skip(self))]
    pub async fn get_with_cover(&self, id: u64) -> Result<Option<GameEntry>, Status> {
        let igdb_state = self.igdb_state()?;

        let result: Vec<IgdbGame> = post(
            &igdb_state,
            GAMES_ENDPOINT,
            &format!("fields *; where id={id};"),
        )
        .await?;

        match result.into_iter().next() {
            Some(igdb_game) => {
                let cover = match igdb_game.cover {
                    Some(cover_id) => get_cover(&igdb_state, cover_id).await?,
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
        Ok(igdb_ranking::sorted_by_relevance(
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

        let igdb_state = self.igdb_state()?;
        let mut handles = vec![];
        for game in igdb_games {
            let igdb_state = Arc::clone(&igdb_state);
            handles.push(tokio::spawn(
                async move {
                    let cover = match game.cover {
                        Some(id) => match get_cover(&igdb_state, id).await {
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

        Ok(igdb_ranking::sorted_by_relevance_with_threshold(
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
        let igdb_state = self.igdb_state()?;
        post::<Vec<IgdbGame>>(
            &igdb_state,
            GAMES_ENDPOINT,
            &format!("search \"{title}\"; fields *; where platforms = (6);"),
        )
        .await
    }

    #[instrument(level = "trace", skip(self))]
    pub async fn get_igdb_games(&self, page: u64) -> Result<Vec<IgdbGame>, Status> {
        let offset = page * 500;

        let igdb_state = self.igdb_state()?;
        post::<Vec<IgdbGame>>(
            &igdb_state,
            GAMES_ENDPOINT,
            &format!("fields *; sort first_release_date desc; where platforms = (6) & (category = 0 | category = 1 | category = 2 | category = 4 | category = 8 | category = 9); limit 500; offset {offset};"),
        )
        .await
    }

    #[instrument(level = "trace", skip(self))]
    pub async fn resolve(&self, igdb_game: IgdbGame) -> Result<GameEntry, Status> {
        let igdb_state = self.igdb_state()?;

        let mut game_entry = retrieve_game_digest(Arc::clone(&igdb_state), &igdb_game).await?;
        retrieve_game_info(igdb_state, igdb_game, &mut game_entry).await?;

        Ok(game_entry)
    }
}

#[instrument(level = "trace", skip(igdb_state))]
async fn get_game(igdb_state: &IgdbApiState, id: u64) -> Result<IgdbGame, Status> {
    let result: Vec<IgdbGame> = post(
        igdb_state,
        GAMES_ENDPOINT,
        &format!("fields *; where id={id};"),
    )
    .await?;

    match result.into_iter().next() {
        Some(igdb_game) => Ok(igdb_game),
        None => Err(Status::not_found(format!(
            "Failed to retrieve game with id={id}"
        ))),
    }
}

#[instrument(
    level = "trace",
    skip(igdb_state, igdb_game)
    fields(
        game_id = %igdb_game.id,
        game_name = %igdb_game.name,
    )
)]
async fn retrieve_game_digest(
    igdb_state: Arc<IgdbApiState>,
    igdb_game: &IgdbGame,
) -> Result<GameEntry, Status> {
    let mut game_entry = GameEntry::from(igdb_game);

    if let Some(cover) = igdb_game.cover {
        game_entry.cover = get_cover(&igdb_state, cover).await?;
    }

    if !igdb_game.genres.is_empty() {
        game_entry.genres = get_genres(&igdb_state, &igdb_game.genres).await?;
    }
    if !igdb_game.keywords.is_empty() {
        game_entry.keywords = get_keywords(&igdb_state, &igdb_game.keywords).await?;
    }

    if let Some(collection) = igdb_game.collection {
        if let Some(collection) = get_collection(&igdb_state, collection).await? {
            game_entry.collections = vec![collection];
        }
    }
    if !igdb_game.franchises.is_empty() {
        game_entry
            .collections
            .extend(get_franchises(&igdb_state, &igdb_game.franchises).await?);
    }

    if !igdb_game.involved_companies.is_empty() {
        let companies = get_companies(&igdb_state, &igdb_game.involved_companies).await?;
        game_entry.developers = companies
            .iter()
            .filter(|company| match company.role {
                CompanyRole::Developer => true,
                _ => false,
            })
            // NOTE: drain_filter() would prevent the cloning.
            .map(|company| company.clone())
            .collect();
        game_entry.publishers = companies
            .into_iter()
            .filter(|company| match company.role {
                CompanyRole::Publisher => true,
                _ => false,
            })
            .collect();
    }

    Ok(game_entry)
}

#[async_recursion]
#[instrument(
    level = "trace",
    skip(igdb_state, igdb_game, game_entry),
    fields(
        game_id = %igdb_game.id,
        game_name = %igdb_game.name,
    )
)]
async fn retrieve_game_info(
    igdb_state: Arc<IgdbApiState>,
    igdb_game: IgdbGame,
    game_entry: &mut GameEntry,
) -> Result<(), Status> {
    if !igdb_game.screenshots.is_empty() {
        game_entry.screenshots = get_screenshots(&igdb_state, &igdb_game.screenshots).await?;
    }
    if !igdb_game.artworks.is_empty() {
        game_entry.artwork = get_artwork(&igdb_state, &igdb_game.artworks).await?;
    }
    if igdb_game.websites.len() > 0 {
        game_entry.websites = get_websites(&igdb_state, &igdb_game.websites)
            .await?
            .into_iter()
            .map(|website| Website {
                url: website.url,
                authority: match website.category {
                    1 => WebsiteAuthority::Official,
                    3 => WebsiteAuthority::Wikipedia,
                    9 => WebsiteAuthority::Youtube,
                    13 => WebsiteAuthority::Steam,
                    16 => WebsiteAuthority::Egs,
                    17 => WebsiteAuthority::Gog,
                    _ => WebsiteAuthority::Null,
                },
            })
            .collect();
    }

    let parent_id = match igdb_game.parent_game {
        Some(parent) => Some(parent),
        None => match igdb_game.version_parent {
            Some(parent) => Some(parent),
            None => None,
        },
    };

    if let Some(parent_id) = parent_id {
        let parent = retrieve_game_digest(
            Arc::clone(&igdb_state),
            &get_game(&igdb_state, parent_id).await?,
        )
        .await?;
        game_entry.parent = Some(GameDigest::new(parent));
    }

    for expansion_id in igdb_game.expansions.into_iter() {
        let expansion = retrieve_game_digest(
            Arc::clone(&igdb_state),
            &get_game(&igdb_state, expansion_id).await?,
        )
        .await?;
        game_entry.expansions.push(GameDigest::new(expansion));
    }
    for dlc_id in igdb_game.dlcs.into_iter() {
        let dlc = retrieve_game_digest(
            Arc::clone(&igdb_state),
            &get_game(&igdb_state, dlc_id).await?,
        )
        .await?;
        game_entry.dlcs.push(GameDigest::new(dlc));
    }
    for remake_id in igdb_game.remakes.into_iter() {
        let remake = retrieve_game_digest(
            Arc::clone(&igdb_state),
            &get_game(&igdb_state, remake_id).await?,
        )
        .await?;
        game_entry.remakes.push(GameDigest::new(remake));
    }
    for remaster_id in igdb_game.remasters.into_iter() {
        let remaster = retrieve_game_digest(
            Arc::clone(&igdb_state),
            &get_game(&igdb_state, remaster_id).await?,
        )
        .await?;
        game_entry.remasters.push(GameDigest::new(remaster));
    }

    Ok(())
}

/// Returns game image cover based on id from the igdb/covers endpoint.
#[instrument(level = "trace", skip(igdb_state))]
async fn get_cover(igdb_state: &IgdbApiState, id: u64) -> Result<Option<Image>, Status> {
    let result: Vec<Image> = post(
        igdb_state,
        COVERS_ENDPOINT,
        &format!("fields *; where id={id};"),
    )
    .await?;

    Ok(result.into_iter().next())
}

/// Returns game image cover based on id from the igdb/covers endpoint.
#[instrument(level = "trace", skip(igdb_state))]
async fn get_company_logo(igdb_state: &IgdbApiState, id: u64) -> Result<Option<Image>, Status> {
    let result: Vec<Image> = post(
        igdb_state,
        COMPANY_LOGOS_ENDPOINT,
        &format!("fields *; where id={id};"),
    )
    .await?;

    Ok(result.into_iter().next())
}

/// Returns game genres based on id from the igdb/genres endpoint.
#[instrument(level = "trace", skip(igdb_state))]
async fn get_genres(igdb_state: &IgdbApiState, ids: &[u64]) -> Result<Vec<String>, Status> {
    Ok(post::<Vec<Annotation>>(
        igdb_state,
        GENRES_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<String>>()
                .join(",")
        ),
    )
    .await?
    .into_iter()
    .map(|genre| genre.name)
    .collect())
}

/// Returns game keywords based on id from the igdb/keywords endpoint.
#[instrument(level = "trace", skip(igdb_state))]
async fn get_keywords(igdb_state: &IgdbApiState, ids: &[u64]) -> Result<Vec<String>, Status> {
    Ok(post::<Vec<Annotation>>(
        igdb_state,
        KEYWORDS_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<String>>()
                .join(",")
        ),
    )
    .await?
    .into_iter()
    .map(|genre| genre.name)
    .collect())
}

/// Returns game screenshots based on id from the igdb/screenshots endpoint.
#[instrument(level = "trace", skip(igdb_state))]
async fn get_artwork(igdb_state: &IgdbApiState, ids: &[u64]) -> Result<Vec<Image>, Status> {
    Ok(post(
        igdb_state,
        ARTWORKS_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<String>>()
                .join(",")
        ),
    )
    .await?)
}

/// Returns game screenshots based on id from the igdb/screenshots endpoint.
#[instrument(level = "trace", skip(igdb_state))]
async fn get_screenshots(igdb_state: &IgdbApiState, ids: &[u64]) -> Result<Vec<Image>, Status> {
    Ok(post(
        &igdb_state,
        SCREENSHOTS_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<String>>()
                .join(",")
        ),
    )
    .await?)
}

/// Returns game websites based on id from the igdb/websites endpoint.
#[instrument(level = "trace", skip(igdb_state))]
async fn get_websites(
    igdb_state: &IgdbApiState,
    ids: &[u64],
) -> Result<Vec<igdb_docs::Website>, Status> {
    Ok(post(
        &igdb_state,
        WEBSITES_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<String>>()
                .join(",")
        ),
    )
    .await?)
}

/// Returns game collection based on id from the igdb/collections endpoint.
#[instrument(level = "trace", skip(igdb_state))]
async fn get_collection(igdb_state: &IgdbApiState, id: u64) -> Result<Option<Collection>, Status> {
    let result: Vec<igdb_docs::Collection> = post(
        &igdb_state,
        COLLECTIONS_ENDPOINT,
        &format!("fields *; where id={id};"),
    )
    .await?;

    match result.into_iter().next() {
        Some(collection) => Ok(Some(Collection {
            id: collection.id,
            name: collection.name,
            slug: collection.slug,
            igdb_type: CollectionType::Collection,
        })),
        None => Ok(None),
    }
}

/// Returns game franchices based on id from the igdb/frachises endpoint.
#[instrument(level = "trace", skip(igdb_state))]
async fn get_franchises(igdb_state: &IgdbApiState, ids: &[u64]) -> Result<Vec<Collection>, Status> {
    let result: Vec<igdb_docs::Collection> = post(
        &igdb_state,
        FRANCHISES_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<String>>()
                .join(",")
        ),
    )
    .await?;

    Ok(result
        .into_iter()
        .map(|collection| Collection {
            id: collection.id,
            name: collection.name,
            slug: collection.slug,
            igdb_type: CollectionType::Franchise,
        })
        .collect())
}

/// Returns game companies involved in the making of the game.
#[instrument(level = "trace", skip(igdb_state))]
async fn get_companies(igdb_state: &IgdbApiState, ids: &[u64]) -> Result<Vec<Company>, Status> {
    // Collect all involved companies for a game entry.
    let involved_companies: Vec<igdb_docs::InvolvedCompany> = post(
        &igdb_state,
        INVOLVED_COMPANIES_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<_>>()
                .join(",")
        ),
    )
    .await?;

    // Collect company data for involved companies.
    let igdb_companies = post::<Vec<igdb_docs::Company>>(
        &igdb_state,
        COMPANIES_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            involved_companies
                .iter()
                .map(|ic| match &ic.company {
                    Some(c) => c.to_string(),
                    None => "".to_string(),
                })
                .collect::<Vec<_>>()
                .join(",")
        ),
    )
    .await?;

    let mut companies = vec![];
    for company in igdb_companies {
        if company.name.is_empty() {
            continue;
        }

        let ic = involved_companies
            .iter()
            .filter(|ic| ic.company.is_some())
            .find(|ic| ic.company.unwrap() == company.id)
            .expect("Failed to find company in involved companies.");

        companies.push(Company {
            id: company.id,
            name: company.name,
            slug: company.slug,
            role: match ic.developer {
                true => CompanyRole::Developer,
                false => match ic.publisher {
                    true => CompanyRole::Publisher,
                    false => match ic.porting {
                        true => CompanyRole::Porting,
                        false => match ic.supporting {
                            true => CompanyRole::Support,
                            false => CompanyRole::Unknown,
                        },
                    },
                },
            },
            logo: match company.logo {
                Some(logo) => get_company_logo(&igdb_state, logo).await?,
                None => None,
            },
        });
    }

    Ok(companies)
}

/// Sends a POST request to an IGDB service endpoint.
async fn post<T: DeserializeOwned>(
    igdb_state: &IgdbApiState,
    endpoint: &str,
    body: &str,
) -> Result<T, Status> {
    igdb_state.qps.wait();

    let _permit = igdb_state.qps.connection().await;
    let uri = format!("{IGDB_SERVICE_URL}/{endpoint}/");
    let resp = reqwest::Client::new()
        .post(&uri)
        .header("Client-ID", &igdb_state.client_id)
        .header(
            "Authorization",
            format!("Bearer {}", &igdb_state.oauth_token),
        )
        .body(String::from(body))
        .send()
        .await?;

    let text = resp.text().await?;
    let resp = serde_json::from_str::<T>(&text).map_err(|_| {
        let msg = format!("Received unexpected response: {text}\nuri: {uri}\nquery: {body}");
        error!(msg);
        Status::internal(msg)
    });

    resp
}

impl From<IgdbGame> for GameEntry {
    fn from(igdb_game: IgdbGame) -> Self {
        GameEntry {
            id: igdb_game.id,
            name: igdb_game.name,
            summary: igdb_game.summary,
            storyline: igdb_game.storyline,
            release_date: igdb_game.first_release_date,
            igdb_rating: igdb_game.total_rating,
            category: match igdb_game.category {
                0 => GameCategory::Main,
                1 => GameCategory::Dlc,
                2 => GameCategory::Expansion,
                4 => GameCategory::StandaloneExpansion,
                6 => GameCategory::Episode,
                7 => GameCategory::Season,
                8 => GameCategory::Remake,
                9 => GameCategory::Remaster,
                _ => GameCategory::Ignore,
            },

            websites: vec![Website {
                url: igdb_game.url,
                authority: WebsiteAuthority::Igdb,
            }],

            ..Default::default()
        }
    }
}

impl From<&IgdbGame> for GameEntry {
    fn from(igdb_game: &IgdbGame) -> Self {
        GameEntry {
            id: igdb_game.id,
            name: igdb_game.name.clone(),
            summary: igdb_game.summary.clone(),
            storyline: igdb_game.storyline.clone(),
            release_date: igdb_game.first_release_date,
            igdb_rating: igdb_game.total_rating,
            category: match igdb_game.category {
                0 => GameCategory::Main,
                1 => GameCategory::Dlc,
                2 => GameCategory::Expansion,
                4 => GameCategory::StandaloneExpansion,
                6 => GameCategory::Episode,
                7 => GameCategory::Season,
                8 => GameCategory::Remake,
                9 => GameCategory::Remaster,
                _ => GameCategory::Ignore,
            },

            websites: vec![Website {
                url: igdb_game.url.clone(),
                authority: WebsiteAuthority::Igdb,
            }],

            ..Default::default()
        }
    }
}

impl From<mpsc::error::SendError<GameEntry>> for Status {
    fn from(err: mpsc::error::SendError<GameEntry>) -> Self {
        Self::new("reqwest error", err)
    }
}

const TWITCH_OAUTH_URL: &str = "https://id.twitch.tv/oauth2/token";
const IGDB_SERVICE_URL: &str = "https://api.igdb.com/v4";
const GAMES_ENDPOINT: &str = "games";
const EXTERNAL_GAMES_ENDPOINT: &str = "external_games";
const COVERS_ENDPOINT: &str = "covers";
const COMPANY_LOGOS_ENDPOINT: &str = "company_logos";
const FRANCHISES_ENDPOINT: &str = "franchises";
const COLLECTIONS_ENDPOINT: &str = "collections";
const ARTWORKS_ENDPOINT: &str = "artworks";
const GENRES_ENDPOINT: &str = "genres";
const KEYWORDS_ENDPOINT: &str = "keywords";
const SCREENSHOTS_ENDPOINT: &str = "screenshots";
const WEBSITES_ENDPOINT: &str = "websites";
const COMPANIES_ENDPOINT: &str = "companies";
const INVOLVED_COMPANIES_ENDPOINT: &str = "involved_companies";

#[derive(Debug, Serialize, Deserialize)]
struct TwitchOAuthResponse {
    access_token: String,
    expires_in: i32,
}
