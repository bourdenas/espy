use crate::espy;
use crate::Status;
use serde::{Deserialize, Serialize};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

/// Creates a GogToken for authenticating a user to the service. The
/// authentication code is used to retrieve an access token that is used when
/// calling any GOG API for retrieving user information.
///
/// Retrieve GOG authentication code by loging in to:
/// https://auth.gog.com/auth?client_id=46899977096215655&redirect_uri=https%3A%2F%2Fembed.gog.com%2Fon_login_success%3Forigin%3Dclient&response_type=code&layout=client2
pub async fn create_from_oauth_code(oauth_code: &str) -> Result<espy::GogToken, Status> {
    let params = format!(
            "/token?client_id={}&client_secret={}&grant_type=authorization_code&code={}&redirect_uri={}%2Ftoken", 
            GOG_GALAXY_CLIENT_ID, GOG_GALAXY_SECRET, oauth_code, GOG_GALAXY_REDIRECT_URI);
    let uri = format!("{}{}", GOG_AUTH_HOST, params);

    let token = reqwest::get(&uri).await?.json::<GogToken>().await?;
    Ok(token.to_proto(oauth_code))
}

/// Validates that the access token contained in a user's GogToken is still
/// valid. If the access token is expired this will try to refresh it (without
/// requiring any user interaction).
///
/// Validation needs to happen before any request to GOG APIs. If an expired
/// access token is used, then the user needs to manually authenticate with GOG,
/// retrieve a new oauth code and provide it to the `create_from_oauth_code`
/// function to produce a new GogToken.
pub async fn validate(token: &mut espy::GogToken) -> Result<(), Status> {
    if is_fresh_token(token) {
        return Ok(());
    }

    let params = format!(
        "/token?client_id={}&client_secret={}&grant_type=refresh_token&refresh_token={}&%2Ftoken",
        GOG_GALAXY_CLIENT_ID, GOG_GALAXY_SECRET, &token.refresh_token
    );
    let uri = format!("{}{}", GOG_AUTH_HOST, params);

    let new_token = reqwest::get(&uri).await?.json::<GogToken>().await?;
    *token = new_token.to_proto(&token.oauth_code);

    Ok(())
}

/// Returns true if the current user GOG access token has not expired yet.
/// Typically, it is valid for 2 hours.
fn is_fresh_token(token: &espy::GogToken) -> bool {
    let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap();
    now.as_secs() < token.expires_at
}

/// Intermediate GogToken struct used for serialisation/deserialisation to/from
/// JSON for requests to GOG auth servers.
#[derive(Debug, Serialize, Deserialize, Default)]
struct GogToken {
    access_token: String,
    refresh_token: String,
    expires_in: u64,
    user_id: String,
    session_id: String,
}

impl GogToken {
    // Converts intermediate GogToken struct into a protobuf GogToken that is
    // used for persistent storage.
    fn to_proto(self, oauth_code: &str) -> espy::GogToken {
        espy::GogToken {
            oauth_code: String::from(oauth_code),
            access_token: self.access_token,
            refresh_token: self.refresh_token,
            expires_at: SystemTime::now()
                .checked_add(Duration::from_secs(self.expires_in))
                .unwrap()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_secs(),
            user_id: self.user_id,
            session_id: self.session_id,
        }
    }
}

const GOG_AUTH_HOST: &str = "https://auth.gog.com";
const GOG_GALAXY_CLIENT_ID: &str = "46899977096215655";
const GOG_GALAXY_SECRET: &str = "9d85c43b1482497dbbce61f6e4aa173a433796eeae2ca8c5f6129f2dc4de46d9";
const GOG_GALAXY_REDIRECT_URI: &str =
    "https%3A%2F%2Fembed.gog.com%2Fon_login_success%3Forigin%3Dclient";
