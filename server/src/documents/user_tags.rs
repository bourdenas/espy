use serde::{Deserialize, Serialize};

/// Document type under 'users/{user_id}/user_data/tags'.
#[derive(Serialize, Deserialize, Default, Debug)]
pub struct UserTags {
    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub tags: Vec<Tag>,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Tag {
    pub name: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub games: Vec<u64>,
}
