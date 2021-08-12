use crate::documents::Annotation;
use serde::{Deserialize, Serialize};

/// Document type under 'users/{user_id}/games' that represents a game entry in
/// IGDB.
#[derive(Serialize, Deserialize, Default, Debug)]
pub struct GameEntry {
    pub id: u64,
    pub name: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "String::is_empty")]
    pub summary: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub release_date: Option<i64>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub collection: Option<Annotation>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub franchises: Vec<Annotation>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub companies: Vec<Annotation>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cover: Option<Image>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub screenshots: Vec<Image>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub artwork: Vec<Image>,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Image {
    pub image_id: String,
    pub height: i32,
    pub width: i32,
}
