use crate::api;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct UserData {
    pub uid: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub keys: Option<Keys>,
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct Keys {
    #[serde(default)]
    #[serde(skip_serializing_if = "String::is_empty")]
    pub gog_auth_code: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub gog_token: Option<api::GogToken>,

    #[serde(default)]
    #[serde(skip_serializing_if = "String::is_empty")]
    pub steam_user_id: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "String::is_empty")]
    pub egs_auth_code: String,
}
