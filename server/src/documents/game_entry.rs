use serde::{Deserialize, Serialize};

use crate::api::IgdbGame;

use super::{GameDigest, SteamData};

/// Document type under 'users/{user_id}/games' that represents a game entry in
/// IGDB.
#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct GameEntry {
    pub id: u64,
    pub name: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "String::is_empty")]
    pub summary: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "String::is_empty")]
    pub storyline: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub release_date: Option<i64>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub igdb_rating: Option<f64>,

    #[serde(default)]
    pub igdb_follows: i64,

    #[serde(default)]
    pub igdb_hypes: i64,

    #[serde(default)]
    pub category: GameCategory,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cover: Option<Image>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub steam_data: Option<SteamData>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub genres: Vec<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub keywords: Vec<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub collections: Vec<Collection>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub developers: Vec<Company>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub publishers: Vec<Company>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub expansions: Vec<GameDigest>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parent: Option<GameDigest>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub dlcs: Vec<GameDigest>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub remakes: Vec<GameDigest>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub remasters: Vec<GameDigest>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub screenshots: Vec<Image>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub artwork: Vec<Image>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub websites: Vec<Website>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum GameCategory {
    Main,
    Dlc,
    Expansion,
    StandaloneExpansion,
    Episode,
    Season,
    Remake,
    Remaster,
    ExpandedGame,
    Ignore,
}

impl Default for GameCategory {
    fn default() -> Self {
        GameCategory::Main
    }
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct Image {
    pub image_id: String,
    pub height: i32,
    pub width: i32,
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct Company {
    pub id: u64,
    pub name: String,

    #[serde(default)]
    pub slug: String,

    #[serde(default)]
    pub role: CompanyRole,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub logo: Option<Image>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum CompanyRole {
    Unknown = 0,
    Developer = 1,
    Publisher = 2,
    Porting = 3,
    Support = 4,
}

impl Default for CompanyRole {
    fn default() -> Self {
        CompanyRole::Unknown
    }
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct Collection {
    pub id: u64,
    pub name: String,

    #[serde(default)]
    pub slug: String,

    pub igdb_type: CollectionType,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum CollectionType {
    Null = 0,
    Collection = 1,
    Franchise = 2,
}

impl Default for CollectionType {
    fn default() -> Self {
        CollectionType::Null
    }
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct Website {
    pub url: String,
    pub authority: WebsiteAuthority,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum WebsiteAuthority {
    Null = 0,
    Official = 1,
    Wikipedia = 2,
    Igdb = 3,
    Gog = 4,
    Steam = 5,
    Egs = 6,
    Youtube = 7,
}

impl Default for WebsiteAuthority {
    fn default() -> Self {
        WebsiteAuthority::Null
    }
}

impl From<IgdbGame> for GameEntry {
    fn from(igdb_game: IgdbGame) -> Self {
        GameEntry {
            id: igdb_game.id,
            name: igdb_game.name,
            summary: igdb_game.summary,
            storyline: igdb_game.storyline,
            release_date: igdb_game.first_release_date,
            igdb_rating: igdb_game.aggregated_rating,
            igdb_follows: igdb_game.follows,
            igdb_hypes: igdb_game.hypes,
            category: match igdb_game.category {
                0 => GameCategory::Main,
                1 => GameCategory::Dlc,
                2 => GameCategory::Expansion,
                4 => GameCategory::StandaloneExpansion,
                6 => GameCategory::Episode,
                7 => GameCategory::Season,
                8 => GameCategory::Remake,
                9 => GameCategory::Remaster,
                _ => GameCategory::Ignore,
            },

            websites: vec![Website {
                url: igdb_game.url,
                authority: WebsiteAuthority::Igdb,
            }],

            ..Default::default()
        }
    }
}

impl From<&IgdbGame> for GameEntry {
    fn from(igdb_game: &IgdbGame) -> Self {
        GameEntry {
            id: igdb_game.id,
            name: igdb_game.name.clone(),
            summary: igdb_game.summary.clone(),
            storyline: igdb_game.storyline.clone(),
            release_date: igdb_game.first_release_date,
            igdb_rating: igdb_game.aggregated_rating,
            igdb_follows: igdb_game.follows,
            igdb_hypes: igdb_game.hypes,
            category: match igdb_game.category {
                0 => GameCategory::Main,
                1 => GameCategory::Dlc,
                2 => GameCategory::Expansion,
                4 => GameCategory::StandaloneExpansion,
                6 => GameCategory::Episode,
                7 => GameCategory::Season,
                8 => GameCategory::Remake,
                9 => GameCategory::Remaster,
                _ => GameCategory::Ignore,
            },

            websites: vec![Website {
                url: igdb_game.url.clone(),
                authority: WebsiteAuthority::Igdb,
            }],

            ..Default::default()
        }
    }
}
