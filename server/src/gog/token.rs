use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct GogToken {
    pub access_token: String,
    refresh_token: String,
    expires_in: u32,
    user_id: String,
    session_id: String,
}

impl GogToken {
    pub async fn from_code(code: &str) -> Result<Self, Box<dyn std::error::Error + Send + Sync>> {
        let params = format!(
            "/token?client_id={}&client_secret={}&grant_type=authorization_code&code={}&redirect_uri={}%2Ftoken", 
            GOG_GALAXY_CLIENT_ID, GOG_GALAXY_SECRET, code, GOG_GALAXY_REDIRECT_URI);
        let uri = format!("{}{}", GOG_AUTH_HOST, params);
        println!("GET: {}", uri);

        let resp = reqwest::get(&uri).await?.json::<GogToken>().await?;
        println!("GOG token resp: {:#?}", resp);

        Ok(resp)
    }

    pub fn from_token(token: &str) -> Self {
        GogToken {
            access_token: String::from(token),
            ..Default::default()
        }
    }

    pub async fn from_refresh(
        refresh_token: &str,
    ) -> Result<Self, Box<dyn std::error::Error + Send + Sync>> {
        let params = format!(
            "/token?client_id={}&client_secret={}&grant_type=refresh_token&refresh_token={}&%2Ftoken",
            GOG_GALAXY_CLIENT_ID, GOG_GALAXY_SECRET, refresh_token);
        let uri = format!("{}{}", GOG_AUTH_HOST, params);
        println!("GET: {}", uri);

        let resp = reqwest::get(&uri).await?.json::<GogToken>().await?;
        println!("GOG refresh token resp: {:#?}", resp);

        Ok(resp)
    }
}

const GOG_AUTH_HOST: &str = "https://auth.gog.com";
const GOG_GALAXY_CLIENT_ID: &str = "46899977096215655";
const GOG_GALAXY_SECRET: &str = "9d85c43b1482497dbbce61f6e4aa173a433796eeae2ca8c5f6129f2dc4de46d9";
const GOG_GALAXY_REDIRECT_URI: &str =
    "https%3A%2F%2Fembed.gog.com%2Fon_login_success%3Forigin%3Dclient";
