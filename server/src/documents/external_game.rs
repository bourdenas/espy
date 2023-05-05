use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Default, Debug, Clone)]
pub struct ExternalGame {
    pub igdb_id: u64,
    pub store_id: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub store_url: Option<String>,
}

impl ExternalGame {
    pub fn new(igdb_id: u64, store_id: String, store_url: Option<String>) -> Self {
        ExternalGame {
            igdb_id,
            store_id,
            store_url,
        }
    }
}
