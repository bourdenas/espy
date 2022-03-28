use crate::api;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct UserData {
    pub uid: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub keys: Option<Keys>,

    #[serde(default)]
    pub version: u64,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Keys {
    #[serde(default)]
    #[serde(skip_serializing_if = "String::is_empty")]
    pub steam_user_id: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub gog_token: Option<api::GogToken>,
}
