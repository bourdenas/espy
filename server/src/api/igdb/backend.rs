use crate::Status;
use serde::de::DeserializeOwned;
use tracing::error;

use super::state::IgdbApiState;

/// Sends a POST request to an IGDB service endpoint.
pub async fn post<T: DeserializeOwned>(
    igdb_state: &IgdbApiState,
    endpoint: &str,
    body: &str,
) -> Result<T, Status> {
    igdb_state.qps.wait();

    let _permit = igdb_state.qps.connection().await;
    let uri = format!("{IGDB_SERVICE_URL}/{endpoint}/");
    let resp = reqwest::Client::new()
        .post(&uri)
        .header("Client-ID", &igdb_state.client_id)
        .header(
            "Authorization",
            format!("Bearer {}", &igdb_state.oauth_token),
        )
        .body(String::from(body))
        .send()
        .await?;

    let text = resp.text().await?;
    let resp = serde_json::from_str::<T>(&text).map_err(|_| {
        let msg = format!("Received unexpected response: {text}\nuri: {uri}\nquery: {body}");
        error!(msg);
        Status::internal(msg)
    });

    resp
}

const IGDB_SERVICE_URL: &str = "https://api.igdb.com/v4";
