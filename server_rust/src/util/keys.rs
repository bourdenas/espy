use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct Keys {
  pub igdb: IgdbKeys,
  pub steam: SteamKeys,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct IgdbKeys {
  pub client_id: String,
  pub secret: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SteamKeys {
  pub client_key: String,
  pub user_id: String,
}

impl Keys {
  pub fn from_file(path: &str) -> Result<Keys, Box<dyn std::error::Error + Send + Sync>> {
    let keys = std::fs::read(path)?;
    Ok(serde_json::from_slice(&keys)?)
  }
}
