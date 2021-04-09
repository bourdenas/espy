use serde::{Deserialize, Serialize};
use std::fs;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct GogToken {
    pub access_token: String,
    refresh_token: String,
    expires_in: u64,
    user_id: String,
    session_id: String,

    #[serde(skip)]
    path: String,
}

impl GogToken {
    // Retrieve GOG authentication code by loging in to:
    // https://auth.gog.com/auth?client_id=46899977096215655&redirect_uri=https%3A%2F%2Fembed.gog.com%2Fon_login_success%3Forigin%3Dclient&response_type=code&layout=client2
    pub async fn from_code(
        code: &str,
        path: &str,
    ) -> Result<Self, Box<dyn std::error::Error + Send + Sync>> {
        let params = format!(
            "/token?client_id={}&client_secret={}&grant_type=authorization_code&code={}&redirect_uri={}%2Ftoken", 
            GOG_GALAXY_CLIENT_ID, GOG_GALAXY_SECRET, code, GOG_GALAXY_REDIRECT_URI);
        let uri = format!("{}{}", GOG_AUTH_HOST, params);
        println!("GET: {}", uri);

        let mut token = reqwest::get(&uri).await?.json::<GogToken>().await?;
        println!("GOG token resp: {:#?}", token);

        token.expires_in = SystemTime::now()
            .checked_add(Duration::from_secs(token.expires_in))
            .unwrap()
            .duration_since(UNIX_EPOCH)?
            .as_secs();
        token.path = String::from(path);
        token.save(path)?;

        Ok(token)
    }

    pub fn from_token(token: &str) -> Self {
        GogToken {
            access_token: String::from(token),
            ..Default::default()
        }
    }

    pub async fn from_refresh(
        refresh_token: &str,
        path: &str,
    ) -> Result<Self, Box<dyn std::error::Error + Send + Sync>> {
        let mut token = GogToken::default();
        token.refresh_token = String::from(refresh_token);
        token.path = String::from(path);
        token.refresh().await?;

        Ok(token)
    }

    pub fn from_file(path: &str) -> Result<Self, Box<dyn std::error::Error + Send + Sync>> {
        let bytes = std::fs::read(path)?;
        let token: GogToken = serde_json::from_slice(&bytes)?;

        Ok(token)
    }

    pub async fn get_token<'a>(&'a mut self) -> &'a str {
        match self.is_fresh() {
            true => &self.access_token,
            false => {
                self.refresh().await.expect("Failed to refresh GOG token.");
                &self.access_token
            }
        }
    }

    fn is_fresh(&self) -> bool {
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap();
        now.as_secs() < self.expires_in
    }

    async fn refresh(&mut self) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let params = format!(
            "/token?client_id={}&client_secret={}&grant_type=refresh_token&refresh_token={}&%2Ftoken",
            GOG_GALAXY_CLIENT_ID, GOG_GALAXY_SECRET, &self.refresh_token);
        let uri = format!("{}{}", GOG_AUTH_HOST, params);
        println!("GET: {}", uri);

        let path = self.path.clone();

        *self = reqwest::get(&uri).await?.json::<GogToken>().await?;
        self.expires_in = SystemTime::now()
            .checked_add(Duration::from_secs(self.expires_in))
            .unwrap()
            .duration_since(UNIX_EPOCH)?
            .as_secs();
        self.save(&path)?;

        Ok(())
    }

    fn save(&self, path: &str) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let text = serde_json::to_string(self).expect("Failed to serialise GOG Token.");
        fs::write(path, text)?;
        Ok(())
    }
}

const GOG_AUTH_HOST: &str = "https://auth.gog.com";
const GOG_GALAXY_CLIENT_ID: &str = "46899977096215655";
const GOG_GALAXY_SECRET: &str = "9d85c43b1482497dbbce61f6e4aa173a433796eeae2ca8c5f6129f2dc4de46d9";
const GOG_GALAXY_REDIRECT_URI: &str =
    "https%3A%2F%2Fembed.gog.com%2Fon_login_success%3Forigin%3Dclient";
