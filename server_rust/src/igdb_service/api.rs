pub struct IgdbApi {
  client_id: String,
  secret: String,
  oauth_token: Option<String>,
}

static TWITCH_OAUTH_URL: &'static str = "https://id.twitch.tv/oauth2/token";

impl IgdbApi {
  pub fn new(client_id: &str, secret: &str) -> IgdbApi {
    IgdbApi {
      client_id: String::from(client_id),
      secret: String::from(secret),
      oauth_token: None,
    }
  }

  pub async fn connect(&mut self) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
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
}

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct TwitchOAuthResponse {
  access_token: String,
  expires_in: i32,
}
