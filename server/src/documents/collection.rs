use serde::{Deserialize, Serialize};

use super::GameDigest;

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct IgdbCollection {
    pub id: u64,

    #[serde(default)]
    pub name: String,

    #[serde(default)]
    pub slug: String,

    #[serde(default)]
    pub url: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub games: Vec<GameDigest>,
}
