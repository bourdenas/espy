use super::igdb_docs::{self, ExternalGame, IgdbGame, InvolvedCompany};
use crate::documents::{Annotation, GameEntry, Image, StoreEntry, Website, WebsiteAuthority};
use crate::util::rate_limiter::RateLimiter;
use crate::Status;
use async_recursion::async_recursion;
use serde::{de::DeserializeOwned, Deserialize, Serialize};

pub struct IgdbApi {
    client_id: String,
    secret: String,
    oauth_token: Option<String>,
    qps: RateLimiter,
}

impl IgdbApi {
    pub fn new(client_id: &str, secret: &str) -> IgdbApi {
        IgdbApi {
            client_id: String::from(client_id),
            secret: String::from(secret),
            oauth_token: None,
            qps: RateLimiter::new(4),
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
        self.oauth_token = Some(resp.access_token);

        Ok(())
    }

    /// Returns matching candidates by searching based on game title from the
    /// igdb/games endpoint.
    ///
    /// Returns barebone candidates with not many of the relevant IGDB fields
    /// populated to save on extra queries.
    pub async fn search_by_title(&self, title: &str) -> Result<Vec<IgdbGame>, Status> {
        Ok(self
            .post(GAMES_ENDPOINT, &format!("search \"{title}\"; fields *;"))
            .await?)
    }

    /// Returns a fully resolved IGDB Game based on the provided storefront
    /// entry if found in IGDB.
    pub async fn match_store_entry(
        &self,
        store_entry: &StoreEntry,
    ) -> Result<Option<GameEntry>, Status> {
        let category: u8 = match store_entry.storefront_name.as_ref() {
            "steam" => 1,
            "gog" => 5,
            _ => return Ok(None),
        };

        let result: Vec<ExternalGame> = self
            .post(
                EXTERNAL_GAMES_ENDPOINT,
                &format!(
                    "fields *; where uid = \"{}\" & category = {category};",
                    store_entry.id
                ),
            )
            .await?;

        match result.into_iter().next() {
            Some(external_game) => self.get_game_by_id(external_game.game).await,
            None => Ok(None),
        }
    }

    /// Returns a fully resolved IGDB Game matching the input IGDB Game id.
    pub async fn get_game_by_id(&self, id: u64) -> Result<Option<GameEntry>, Status> {
        let result: Vec<IgdbGame> = self
            .post(GAMES_ENDPOINT, &format!("fields *; where id={id};"))
            .await?;

        match result.into_iter().next() {
            Some(game) => match self.retrieve_game_info(game).await {
                Ok(game) => Ok(Some(game)),
                Err(e) => Err(e),
            },
            None => Ok(None),
        }
    }

    /// Retrieves igdb.Game fields that are relevant to espy. For instance, cover
    /// images, screenshots, expansions, etc.
    ///
    /// IGDB returns Game entries only with relevant IDs for such items that need
    /// subsequent lookups in corresponding IGDB tables.
    #[async_recursion]
    async fn retrieve_game_info(&self, igdb_game: IgdbGame) -> Result<GameEntry, Status> {
        let mut game = GameEntry {
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
        };

        if let Some(cover) = igdb_game.cover {
            game.cover = self.get_cover(cover).await?;
        }
        if let Some(collection) = igdb_game.collection {
            if let Some(collection) = self.get_collection(collection).await? {
                game.collections.push(collection);
            }
        }
        if igdb_game.franchises.len() > 0 {
            game.collections
                .extend(self.get_franchises(&igdb_game.franchises).await?);
        }
        if igdb_game.involved_companies.len() > 0 {
            game.companies = self.get_companies(&igdb_game.involved_companies).await?;
        }
        if igdb_game.artworks.len() > 0 {
            game.artwork = self.get_artwork(&igdb_game.artworks).await?;
        }
        if igdb_game.screenshots.len() > 0 {
            game.screenshots = self.get_screenshots(&igdb_game.screenshots).await?;
        }
        if igdb_game.websites.len() > 0 {
            game.websites.extend(
                self.get_websites(&igdb_game.websites)
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
                    }),
            );
        }

        for expansion in igdb_game.expansions.into_iter() {
            if let Some(expansion) = self.get_game_by_id(expansion).await? {
                game.expansions.push(expansion);
            }
        }
        for dlc in igdb_game.dlcs.into_iter() {
            if let Some(dlc) = self.get_game_by_id(dlc).await? {
                game.dlcs.push(dlc);
            }
        }
        for remake in igdb_game.remakes.into_iter() {
            if let Some(remake) = self.get_game_by_id(remake).await? {
                game.remakes.push(remake);
            }
        }
        for remaster in igdb_game.remasters.into_iter() {
            if let Some(remaster) = self.get_game_by_id(remaster).await? {
                game.remasters.push(remaster);
            }
        }

        Ok(game)
    }

    /// Returns game image cover based on id from the igdb/covers endpoint.
    pub async fn get_cover(&self, id: u64) -> Result<Option<Image>, Status> {
        let result: Vec<Image> = self
            .post(COVERS_ENDPOINT, &format!("fields *; where id={id};"))
            .await?;

        Ok(result.into_iter().next())
    }

    /// Returns game screenshots based on id from the igdb/screenshots endpoint.
    async fn get_artwork(&self, ids: &[u64]) -> Result<Vec<Image>, Status> {
        Ok(self
            .post(
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
    async fn get_screenshots(&self, ids: &[u64]) -> Result<Vec<Image>, Status> {
        Ok(self
            .post(
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
    async fn get_websites(&self, ids: &[u64]) -> Result<Vec<igdb_docs::Website>, Status> {
        Ok(self
            .post(
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
    async fn get_collection(&self, id: u64) -> Result<Option<Annotation>, Status> {
        let result: Vec<Annotation> = self
            .post(COLLECTIONS_ENDPOINT, &format!("fields *; where id={id};"))
            .await?;

        Ok(result.into_iter().next())
    }

    /// Returns game franchices based on id from the igdb/frachises endpoint.
    async fn get_franchises(&self, ids: &[u64]) -> Result<Vec<Annotation>, Status> {
        Ok(self
            .post(
                FRANCHISES_ENDPOINT,
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

    /// Returns game companies involved in the making of the game.
    async fn get_companies(&self, ids: &[u64]) -> Result<Vec<Annotation>, Status> {
        // Collect all involved companies for a game entry.
        let involved_companies: Vec<InvolvedCompany> = self
            .post(
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
        let companies: Vec<Annotation> = self
            .post::<Vec<Annotation>>(
                COMPANIES_ENDPOINT,
                &format!(
                    "fields *; where id = ({});",
                    involved_companies
                        .iter()
                        .map(|ic| match &ic.company {
                            Some(c) => c.to_string(),
                            None => "".to_string(),
                        })
                        // TODO: Due to incomplete IGDB data filtering can leave
                        // no company ids involved which results to a bad
                        // request to IGDB. Temporarily removing the developer
                        // requirement until fixing properly.
                        //
                        // .filter_map(|ic| match ic.developer {
                        //     true => match &ic.company {
                        //         Some(c) => Some(c.id.to_string()),
                        //         None => None,
                        //     },
                        //     false => None,
                        // })
                        .collect::<Vec<_>>()
                        .join(",")
                ),
            )
            .await?
            .into_iter()
            .filter(|company| !company.name.is_empty())
            .collect();

        Ok(companies)
    }

    /// Sends a POST request to an IGDB service endpoint.
    async fn post<T: DeserializeOwned>(&self, endpoint: &str, body: &str) -> Result<T, Status> {
        let token = self
            .oauth_token
            .as_ref()
            .ok_or(Status::internal("IgdbApi endpoint is not connected."))?;

        self.qps.wait();
        let uri = format!("{IGDB_SERVICE_URL}/{endpoint}/");
        let resp = reqwest::Client::new()
            .post(&uri)
            .header("Client-ID", &self.client_id)
            .header("Authorization", format!("Bearer {token}"))
            .body(String::from(body))
            .send()
            .await?
            .json::<T>()
            .await?;

        Ok(resp)
    }
}

const TWITCH_OAUTH_URL: &str = "https://id.twitch.tv/oauth2/token";
const IGDB_SERVICE_URL: &str = "https://api.igdb.com/v4";
const GAMES_ENDPOINT: &str = "games";
const EXTERNAL_GAMES_ENDPOINT: &str = "external_games";
const COVERS_ENDPOINT: &str = "covers";
const FRANCHISES_ENDPOINT: &str = "franchises";
const COLLECTIONS_ENDPOINT: &str = "collections";
const ARTWORKS_ENDPOINT: &str = "artworks";
const SCREENSHOTS_ENDPOINT: &str = "screenshots";
const WEBSITES_ENDPOINT: &str = "websites";
const COMPANIES_ENDPOINT: &str = "companies";
const INVOLVED_COMPANIES_ENDPOINT: &str = "involved_companies";

#[derive(Debug, Serialize, Deserialize)]
struct TwitchOAuthResponse {
    access_token: String,
    expires_in: i32,
}
