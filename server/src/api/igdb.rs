use super::{
    igdb_docs::{self, Annotation},
    igdb_ranking,
};
use crate::{
    documents::{
        Collection, CollectionType, Company, CompanyRole, GameEntry, Image, StoreEntry, Website,
        WebsiteAuthority,
    },
    util::rate_limiter::RateLimiter,
    Status,
};
use async_recursion::async_recursion;
use serde::{de::DeserializeOwned, Deserialize, Serialize};
use std::{
    sync::{Arc, Mutex},
    time::Duration,
};
use tokio::task::JoinHandle;
use tracing::{error, instrument, trace_span, Instrument};

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
            qps: RateLimiter::new(4, Duration::from_secs(1), 4),
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
    /// followed up and thus it is not fully resolved. Use `resolve()` for fully
    /// resolved lookups.
    #[instrument(level = "trace", skip(self))]
    pub async fn get(&self, id: u64) -> Result<Option<GameEntry>, Status> {
        let igdb_state = self.igdb_state()?;
        let result: Vec<igdb_docs::IgdbGame> = post(
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
    /// followed up and thus it is not fully resolved. Use `resolve()` for fully
    /// resolved lookups.
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

    /// Returns candidate GameEntries by searching IGDB based on game title.
    ///
    /// The returned GameEntries are shallow lookups. Reference ids are not
    /// followed up and thus they are not fully resolved. Use `resolve()` for
    /// fully resolved lookups.
    #[instrument(level = "trace", skip(self))]
    pub async fn get_by_title(&self, title: &str) -> Result<Vec<GameEntry>, Status> {
        Ok(igdb_ranking::sorted_by_relevance(
            title,
            self.search(title)
                .await?
                .into_iter()
                .map(|igdb_game| GameEntry::from(igdb_game))
                .collect(),
        ))
    }

    /// Returns a fully resolved GameEntry based on its IGDB `id`.
    #[instrument(level = "trace", skip(self))]
    pub async fn resolve(&self, id: u64) -> Result<Option<GameEntry>, Status> {
        let igdb_state = self.igdb_state()?;
        resolve_game(igdb_state, id).await
    }

    /// Returns candidate GameEntries by searching IGDB based on game title.
    ///
    /// The returned GameEntries are shallow lookups similar to
    /// `get_by_title()`, but have their cover image resolved.
    #[instrument(level = "trace", skip(self))]
    pub async fn get_by_title_with_cover(&self, title: &str) -> Result<Vec<GameEntry>, Status> {
        let igdb_games = self.search(title).await?;

        let igdb_state = self.igdb_state()?;
        let mut handles = vec![];
        for game in igdb_games {
            let igdb_state = Arc::clone(&igdb_state);
            handles.push(tokio::spawn(
                async move {
                    let cover = match game.cover {
                        Some(id) => match get_cover(igdb_state, id).await {
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

        Ok(igdb_ranking::sorted_by_relevance(
            title,
            futures::future::join_all(handles)
                .await
                .into_iter()
                .filter_map(|x| x.ok())
                .collect::<Vec<_>>(),
        ))
    }

    async fn search(&self, title: &str) -> Result<Vec<igdb_docs::IgdbGame>, Status> {
        let igdb_state = self.igdb_state()?;
        post::<Vec<igdb_docs::IgdbGame>>(
            &igdb_state,
            GAMES_ENDPOINT,
            &format!("search \"{title}\"; fields *;"),
        )
        .await
    }
}

/// Returns a fully resolved IGDB Game matching the input IGDB Game id.
#[instrument(level = "trace", skip(igdb_state))]
async fn resolve_game(igdb_state: Arc<IgdbApiState>, id: u64) -> Result<Option<GameEntry>, Status> {
    let result: Vec<igdb_docs::IgdbGame> = post(
        &igdb_state,
        GAMES_ENDPOINT,
        &format!("fields *; where id={id};"),
    )
    .await?;

    match result.into_iter().next() {
        Some(game) => match retrieve_game_info(igdb_state, game).await {
            Ok(game) => Ok(Some(game)),
            Err(e) => Err(e),
        },
        None => Ok(None),
    }
}

/// Retrieves Game fields from IGDB that are relevant to espy. For instance,
/// cover images, screenshots, expansions, etc.
///
/// IGDB returns shallow info for Game and uses reference ids as foreign keys to
/// other tables. This call joins and attaches all information that is relevent
/// to espy by issuing follow-up lookups.
#[async_recursion]
#[instrument(
    level = "trace",
    skip(igdb_state, igdb_game),
    fields(
        game_id = %igdb_game.id,
        game_name = %igdb_game.name,
    )
)]
async fn retrieve_game_info(
    igdb_state: Arc<IgdbApiState>,
    igdb_game: igdb_docs::IgdbGame,
) -> Result<GameEntry, Status> {
    let game = Arc::new(Mutex::new(GameEntry::from(&igdb_game)));

    let mut handles: Vec<JoinHandle<Result<(), Status>>> = vec![];
    if let Some(cover) = igdb_game.cover {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                game.lock().unwrap().cover = get_cover(igdb_state, cover).await?;
                Ok(())
            }
            .instrument(trace_span!("spawn_get_cover")),
        ));
    }
    if let Some(collection) = igdb_game.collection {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                if let Some(collection) = get_collection(&igdb_state, collection).await? {
                    game.lock().unwrap().collections.push(collection);
                }
                Ok(())
            }
            .instrument(trace_span!("spawn_get_collection")),
        ));
    }
    if igdb_game.franchises.len() > 0 {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                let franchise = get_franchises(&igdb_state, &igdb_game.franchises).await?;
                game.lock().unwrap().collections.extend(franchise);
                Ok(())
            }
            .instrument(trace_span!("spawn_get_franchises")),
        ));
    }
    if igdb_game.involved_companies.len() > 0 {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                game.lock().unwrap().companies =
                    get_companies(&igdb_state, &igdb_game.involved_companies).await?;
                Ok(())
            }
            .instrument(trace_span!("spawn_get_companies")),
        ));
    }
    if !igdb_game.genres.is_empty() {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                game.lock().unwrap().genres = get_genres(&igdb_state, &igdb_game.genres).await?;
                Ok(())
            }
            .instrument(trace_span!("spawn_get_genres")),
        ));
    }
    if !igdb_game.keywords.is_empty() {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                game.lock().unwrap().keywords =
                    get_keywords(&igdb_state, &igdb_game.keywords).await?;
                Ok(())
            }
            .instrument(trace_span!("spawn_get_keywords")),
        ));
    }
    if !igdb_game.artworks.is_empty() {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                game.lock().unwrap().artwork =
                    get_artwork(&igdb_state, &igdb_game.artworks).await?;
                Ok(())
            }
            .instrument(trace_span!("spawn_get_artwork")),
        ));
    }
    if igdb_game.screenshots.len() > 0 {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                game.lock().unwrap().screenshots =
                    get_screenshots(&igdb_state, &igdb_game.screenshots).await?;
                Ok(())
            }
            .instrument(trace_span!("spawn_get_screenshots")),
        ));
    }
    if igdb_game.websites.len() > 0 {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                let websites = get_websites(&igdb_state, &igdb_game.websites).await?;
                game.lock()
                    .unwrap()
                    .websites
                    .extend(websites.into_iter().map(|website| Website {
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
                    }));
                Ok(())
            }
            .instrument(trace_span!("spawn_get_websites")),
        ));
    }

    for expansion in igdb_game.expansions.into_iter() {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                if let Some(expansion) = resolve_game(igdb_state, expansion).await? {
                    game.lock().unwrap().expansions.push(expansion);
                }
                Ok(())
            }
            .instrument(trace_span!("spawn_get_expansions")),
        ));
    }
    for dlc in igdb_game.dlcs.into_iter() {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                if let Some(dlc) = resolve_game(igdb_state, dlc).await? {
                    game.lock().unwrap().dlcs.push(dlc);
                }
                Ok(())
            }
            .instrument(trace_span!("spawn_get_dlcs")),
        ));
    }
    for remake in igdb_game.remakes.into_iter() {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                if let Some(remake) = resolve_game(igdb_state, remake).await? {
                    game.lock().unwrap().remakes.push(remake);
                }
                Ok(())
            }
            .instrument(trace_span!("spawn_get_remakes")),
        ));
    }
    for remaster in igdb_game.remasters.into_iter() {
        let igdb_state = Arc::clone(&igdb_state);
        let game = Arc::clone(&game);
        handles.push(tokio::spawn(
            async move {
                if let Some(remaster) = resolve_game(igdb_state, remaster).await? {
                    game.lock().unwrap().remasters.push(remaster);
                }
                Ok(())
            }
            .instrument(trace_span!("spawn_get_remasters")),
        ));
    }

    for result in futures::future::join_all(handles).await {
        match result {
            Ok(result) => {
                if let Err(e) = result {
                    return Err(e);
                }
            }
            Err(e) => return Err(Status::Internal(format!("{}", e))),
        }
    }

    Ok(Arc::try_unwrap(game).unwrap().into_inner().unwrap())
}

/// Returns game image cover based on id from the igdb/covers endpoint.
#[instrument(level = "trace", skip(igdb_state))]
async fn get_cover(igdb_state: Arc<IgdbApiState>, id: u64) -> Result<Option<Image>, Status> {
    let result: Vec<Image> = post(
        &igdb_state,
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
        let msg = format!("Received unexpected response: {}", &text);
        error!(msg);
        Status::internal(msg)
    });

    resp
}

impl From<igdb_docs::IgdbGame> for GameEntry {
    fn from(igdb_game: igdb_docs::IgdbGame) -> Self {
        GameEntry {
            id: igdb_game.id,
            name: igdb_game.name,
            summary: igdb_game.summary,
            storyline: igdb_game.storyline,
            release_date: igdb_game.first_release_date,

            versions: igdb_game.bundles,
            parent: match igdb_game.parent_game {
                Some(parent) => Some(parent),
                None => match igdb_game.version_parent {
                    Some(parent) => Some(parent),
                    None => None,
                },
            },

            websites: vec![Website {
                url: igdb_game.url,
                authority: WebsiteAuthority::Igdb,
            }],

            ..Default::default()
        }
    }
}

impl From<&igdb_docs::IgdbGame> for GameEntry {
    fn from(igdb_game: &igdb_docs::IgdbGame) -> Self {
        GameEntry {
            id: igdb_game.id,
            name: igdb_game.name.clone(),
            summary: igdb_game.summary.clone(),
            storyline: igdb_game.storyline.clone(),
            release_date: igdb_game.first_release_date,
            igdb_rating: igdb_game.total_rating,

            versions: igdb_game.bundles.clone(),
            parent: match igdb_game.parent_game {
                Some(parent) => Some(parent),
                None => match igdb_game.version_parent {
                    Some(parent) => Some(parent),
                    None => None,
                },
            },

            websites: vec![Website {
                url: igdb_game.url.clone(),
                authority: WebsiteAuthority::Igdb,
            }],

            ..Default::default()
        }
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
