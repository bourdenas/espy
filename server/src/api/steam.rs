use crate::documents::StoreEntry;
use crate::traits::Storefront;
use crate::Status;
use async_trait::async_trait;

pub struct SteamApi {
    steam_key: String,
    steam_user_id: String,
}

impl SteamApi {
    pub fn new(steam_key: &str, steam_user_id: &str) -> SteamApi {
        SteamApi {
            steam_key: String::from(steam_key),
            steam_user_id: String::from(steam_user_id),
        }
    }
}

#[async_trait]
impl Storefront for SteamApi {
    fn id() -> String {
        String::from("steam")
    }

    async fn get_owned_games(&self) -> Result<Vec<StoreEntry>, Status> {
        let uri = format!(
            "{}{}?key={}&steamid={}&include_appinfo=true&format=json",
            STEAM_HOST, STEAM_GETOWNEDGAMES_SERVICE, self.steam_key, self.steam_user_id
        );

        let resp = reqwest::get(&uri).await?.json::<SteamResponse>().await?;
        println!("steam games: {}", resp.response.game_count);

        Ok(resp
            .response
            .games
            .into_iter()
            .map(|entry| StoreEntry {
                id: format!("{}", entry.appid),
                title: entry.name,
                storefront_name: SteamApi::id(),
                ..Default::default()
            })
            .collect())
    }
}

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct SteamResponse {
    response: GetOwnedGamesResponse,
}

#[derive(Debug, Serialize, Deserialize)]
struct GetOwnedGamesResponse {
    game_count: i32,
    games: Vec<GameEntry>,
}

#[derive(Debug, Serialize, Deserialize)]
struct GameEntry {
    appid: i64,
    name: String,
    playtime_forever: i32,
    img_icon_url: String,
    img_logo_url: String,
}

const STEAM_HOST: &str = "http://api.steampowered.com";
const STEAM_GETOWNEDGAMES_SERVICE: &str = "/IPlayerService/GetOwnedGames/v0001/";
