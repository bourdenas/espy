use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct SteamData {
    pub name: String,
    pub steam_appid: u64,
    pub detailed_description: String,
    pub short_description: String,
    pub about_the_game: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub header_image: Option<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub background_raw: Option<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub developers: Vec<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub publishers: Vec<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub dlc: Vec<u64>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub genres: Vec<Genre>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub screenshots: Vec<Screenshot>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub movies: Vec<Movie>,
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct Genre {
    pub id: String,
    pub description: String,
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct Screenshot {
    pub id: u64,
    pub path_thumbnail: String,
    pub path_full: String,
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct Movie {
    pub id: u64,
    pub name: String,
    pub thumbnail: String,
    pub webm: WebM,
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct WebM {
    pub max: String,
}
