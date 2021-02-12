use crate::espy;

pub struct SteamApi {
  steam_key: String,
  steam_user_id: String,
}

static STEAM_HOST: &'static str = "http://api.steampowered.com";
static STEAM_GETOWNEDGAMES_SERVICE: &'static str = "/IPlayerService/GetOwnedGames/v0001/";

impl SteamApi {
  pub fn new(steam_key: &str, steam_user_id: &str) -> SteamApi {
    SteamApi {
      steam_key: String::from(steam_key),
      steam_user_id: String::from(steam_user_id),
    }
  }

  // Returns the list of games owned by the user in Steam.
  pub async fn get_owned_games(
    &self,
  ) -> Result<espy::SteamList, Box<dyn std::error::Error + Send + Sync>> {
    let uri = format!(
      "{}{}?key={}&steamid={}&include_appinfo=true&format=json",
      STEAM_HOST, STEAM_GETOWNEDGAMES_SERVICE, self.steam_key, self.steam_user_id
    );

    let resp = reqwest::get(&uri).await?.json::<SteamResponse>().await?;
    println!("steam games: {}", resp.response.game_count);

    Ok(espy::SteamList {
      game: resp
        .response
        .games
        .into_iter()
        .map(|entry| espy::SteamEntry {
          id: entry.appid,
          title: entry.name,
        })
        .collect(),
    })
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
