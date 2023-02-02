use crate::{
    documents::{SteamData, StoreEntry},
    traits::Storefront,
    Status,
};
use async_trait::async_trait;
use std::collections::HashMap;
use tracing::{info, instrument};

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

    #[instrument(level = "trace")]
    pub async fn get_app_details(steam_appid: u64) -> Result<SteamData, Status> {
        let uri = format!(
            "https://store.steampowered.com/api/appdetails?appids={}&l=english",
            steam_appid
        );

        let resp = reqwest::get(&uri).await?;
        let text = resp.text().await?;
        let (_, resp) = serde_json::from_str::<HashMap<String, SteamAppDetailsResponse>>(&text)
            .map_err(|e| {
                let msg = format!(
                    "({steam_appid}) Parse error: {}\n Steam response: {}",
                    e, &text
                );
                Status::internal(msg)
            })?
            .into_iter()
            .next()
            .unwrap();

        Ok(resp.data)
    }
}

#[async_trait]
impl Storefront for SteamApi {
    fn id() -> String {
        String::from("steam")
    }

    async fn get_owned_games(&self) -> Result<Vec<StoreEntry>, Status> {
        let uri = format!(
            "{STEAM_HOST}{STEAM_GETOWNEDGAMES_SERVICE}?key={}&steamid={}&include_appinfo=true&format=json",
            self.steam_key, self.steam_user_id
        );

        let resp = reqwest::get(&uri).await?.json::<SteamResponse>().await?;
        info! {
            "steam games: {}", resp.response.game_count
        }

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
}

#[derive(Serialize, Deserialize, Default, Debug)]
struct SteamAppDetailsResponse {
    success: bool,
    data: SteamData,
}

const STEAM_HOST: &str = "http://api.steampowered.com";
const STEAM_GETOWNEDGAMES_SERVICE: &str = "/IPlayerService/GetOwnedGames/v0001/";
