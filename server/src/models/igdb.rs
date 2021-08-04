use serde::{Deserialize, Serialize};

/// Document type under 'games/{game_id}' that represents an IGDB game entry.
#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Entry {
    pub id: u64,
    pub name: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cover: Option<Image>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub collection: Option<Collection>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub franchises: Vec<Franchise>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub companies: Vec<Company>,

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
    pub width: i32,
    pub height: i32,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Collection {
    pub id: u64,
    pub name: String,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Franchise {
    pub id: u64,
    pub name: String,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Company {
    pub id: u64,
    pub name: String,
}
