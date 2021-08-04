use crate::igdb;
use crate::models::StoreEntry;
use crate::util::rate_limiter::RateLimiter;
use crate::Status;
use prost::Message;
use serde::{Deserialize, Serialize};

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

    // Authenticate with twtich/igdb OAuth2 server and retrieve session token.
    // Authentication is valid for the lifetime of this instane or until the
    // retrieved token expires.
    pub async fn connect(&mut self) -> Result<(), Status> {
        let uri = format!(
            "{}?client_id={}&client_secret={}&grant_type=client_credentials",
            TWITCH_OAUTH_URL, self.client_id, self.secret
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

    // Returns matching candidates by searching based on game title from the
    // igdb/games endpoint.
    pub async fn search_by_title(&self, title: &str) -> Result<igdb::GameResult, Status> {
        Ok(self
            .post(GAMES_ENDPOINT, &format!("search \"{}\"; fields *;", title))
            .await?)
    }

    pub async fn match_external(
        &self,
        store_entry: &StoreEntry,
    ) -> Result<Option<igdb::ExternalGame>, Status> {
        let category: u8 = match store_entry.storefront_name.as_ref() {
            "steam" => 1,
            "gog" => 5,
            _ => 0,
        };

        let mut result: igdb::ExternalGameResult = self
            .post(
                EXTERNAL_GAMES_ENDPOINT,
                &format!(
                    "fields *; where uid = \"{}\" & category = {};",
                    store_entry.id, category
                ),
            )
            .await?;

        match result.externalgames.is_empty() {
            false => Ok(Some(result.externalgames.remove(0))),
            true => Ok(None),
        }
    }

    pub async fn get_game_by_id(&self, id: u64) -> Result<Option<igdb::Game>, Status> {
        let mut result: igdb::GameResult = self
            .post(GAMES_ENDPOINT, &format!("fields *; where id={};", id))
            .await?;

        match result.games.is_empty() {
            false => Ok(Some(result.games.remove(0))),
            true => Ok(None),
        }
    }

    /// Retrieves igdb.Game fields that are relevant to espy. For instance, cover
    /// images, screenshots, franchise info, etc.
    ///
    /// IGDB returns Game entries only with relevant IDs for such items that need
    /// subsequent lookups in corresponding IGDB tables.
    pub async fn retrieve_game_info(&self, game: &mut igdb::Game) -> Result<(), Status> {
        if let Some(cover) = &game.cover {
            if let Some(cover) = self.get_cover(cover.id).await? {
                game.cover = Some(Box::new(cover));
            }
        }
        if let Some(collection) = &game.collection {
            game.collection = self.get_collection(collection.id).await?;
        }
        if game.franchises.len() > 0 {
            game.franchises = self
                .get_franchises(&game.franchises.iter().map(|f| f.id).collect::<Vec<_>>())
                .await?
                .franchises;
        }
        if game.involved_companies.len() > 0 {
            game.involved_companies = self
                .get_companies(
                    &game
                        .involved_companies
                        .iter()
                        .map(|f| f.id)
                        .collect::<Vec<_>>(),
                )
                .await?
                .involvedcompanies;
        }
        if game.artworks.len() > 0 {
            game.artworks = self
                .get_artwork(&game.artworks.iter().map(|f| f.id).collect::<Vec<_>>())
                .await?
                .artworks;
        }
        if game.screenshots.len() > 0 {
            game.screenshots = self
                .get_screenshots(&game.screenshots.iter().map(|f| f.id).collect::<Vec<_>>())
                .await?
                .screenshots;
        }

        Ok(())
    }

    // Returns game image cover based on id from the igdb/covers endpoint.
    pub async fn get_cover(&self, cover_id: u64) -> Result<Option<igdb::Cover>, Status> {
        let mut result: igdb::CoverResult = self
            .post(
                COVERS_ENDPOINT,
                &format!("fields *; where id={};", cover_id),
            )
            .await?;

        match result.covers.is_empty() {
            false => Ok(Some(result.covers.remove(0))),
            true => Ok(None),
        }
    }

    // Returns game collection based on id from the igdb/collections endpoint.
    async fn get_collection(&self, collection_id: u64) -> Result<Option<igdb::Collection>, Status> {
        let mut result: igdb::CollectionResult = self
            .post(
                COLLECTIONS_ENDPOINT,
                &format!("fields *; where id={};", collection_id),
            )
            .await?;

        match result.collections.is_empty() {
            false => Ok(Some(result.collections.remove(0))),
            true => Ok(None),
        }
    }

    // Returns game screenshots based on id from the igdb/screenshots endpoint.
    async fn get_artwork(&self, artwork_ids: &[u64]) -> Result<igdb::ArtworkResult, Status> {
        Ok(self
            .post(
                ARTWORKS_ENDPOINT,
                &format!(
                    "fields *; where id = ({});",
                    artwork_ids
                        .iter()
                        .map(|id| id.to_string())
                        .collect::<Vec<String>>()
                        .join(",")
                ),
            )
            .await?)
    }

    // Returns game screenshots based on id from the igdb/screenshots endpoint.
    async fn get_screenshots(
        &self,
        screenshot_ids: &[u64],
    ) -> Result<igdb::ScreenshotResult, Status> {
        Ok(self
            .post(
                SCREENSHOTS_ENDPOINT,
                &format!(
                    "fields *; where id = ({});",
                    screenshot_ids
                        .iter()
                        .map(|id| id.to_string())
                        .collect::<Vec<String>>()
                        .join(",")
                ),
            )
            .await?)
    }

    // Returns game franchices based on id from the igdb/frachises endpoint.
    async fn get_franchises(&self, franchise_ids: &[u64]) -> Result<igdb::FranchiseResult, Status> {
        Ok(self
            .post(
                FRANCHISES_ENDPOINT,
                &format!(
                    "fields *; where id = ({});",
                    franchise_ids
                        .iter()
                        .map(|id| id.to_string())
                        .collect::<Vec<String>>()
                        .join(",")
                ),
            )
            .await?)
    }

    // Returns game companies involved in the making of the game.
    async fn get_companies(
        &self,
        company_ids: &[u64],
    ) -> Result<igdb::InvolvedCompanyResult, Status> {
        let mut ic_result: igdb::InvolvedCompanyResult = self
            .post(
                INVOLVED_COMPANIES_ENDPOINT,
                &format!(
                    "fields *; where id = ({});",
                    company_ids
                        .iter()
                        .map(|id| id.to_string())
                        .collect::<Vec<_>>()
                        .join(",")
                ),
            )
            .await?;

        let company_result: igdb::CompanyResult = self
            .post(
                COMPANIES_ENDPOINT,
                &format!(
                    "fields *; where id = ({});",
                    ic_result
                        .involvedcompanies
                        .iter()
                        .filter_map(|ic| match ic.developer {
                            true => match &ic.company {
                                Some(c) => Some(c.id.to_string()),
                                None => None,
                            },
                            false => None,
                        })
                        .collect::<Vec<_>>()
                        .join(",")
                ),
            )
            .await?;

        for company in company_result.companies {
            let ic = ic_result
                .involvedcompanies
                .iter_mut()
                .find(|ic| ic.company.as_ref().unwrap().id == company.id);
            if let Some(ic) = ic {
                ic.company = Some(company);
            }
        }

        Ok(ic_result)
    }

    // Sends a POST request to an IGDB service endpoint. It expects to reach a
    // protobuf endpoint and tries to decode the response into a protobuf Message.
    async fn post<T: Message + Default>(&self, endpoint: &str, body: &str) -> Result<T, Status> {
        let token = self
            .oauth_token
            .as_ref()
            .ok_or(Status::new("IgdbApi endpoint is not connected."))?;

        self.qps.wait();
        let uri = format!("{}/{}/", IGDB_SERVICE_URL, endpoint);
        let bytes = reqwest::Client::new()
            .post(&uri)
            .header("Client-ID", &self.client_id)
            .header("Authorization", format!("Bearer {}", &token))
            .body(String::from(body))
            .send()
            .await?
            .bytes()
            .await?;

        match T::decode(bytes.clone()) {
            Ok(msg) => Ok(msg),
            Err(err) => {
                eprintln!("IGDB.POST error: {}", std::str::from_utf8(&bytes).unwrap());
                Err(Status::internal("Failed to decode IGDB response", err))
            }
        }
    }
}

const TWITCH_OAUTH_URL: &str = "https://id.twitch.tv/oauth2/token";
const IGDB_SERVICE_URL: &str = "https://api.igdb.com/v4";
const GAMES_ENDPOINT: &str = "games.pb";
const EXTERNAL_GAMES_ENDPOINT: &str = "external_games.pb";
const COVERS_ENDPOINT: &str = "covers.pb";
const FRANCHISES_ENDPOINT: &str = "franchises.pb";
const COLLECTIONS_ENDPOINT: &str = "collections.pb";
const ARTWORKS_ENDPOINT: &str = "artworks.pb";
const SCREENSHOTS_ENDPOINT: &str = "screenshots.pb";
const COMPANIES_ENDPOINT: &str = "companies.pb";
const INVOLVED_COMPANIES_ENDPOINT: &str = "involved_companies.pb";

#[derive(Debug, Serialize, Deserialize)]
struct TwitchOAuthResponse {
    access_token: String,
    expires_in: i32,
}
