use serde::{Deserialize, Serialize};

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

impl GameEntry {
    pub fn merge(&mut self, other: GameEntry) {
        if other.cover.is_some() {
            self.cover = other.cover;
        }
        if !other.genres.is_empty() {
            self.genres.extend(other.genres);
        }
        if !other.keywords.is_empty() {
            self.keywords.extend(other.keywords);
        }
        if !other.collections.is_empty() {
            self.collections.extend(other.collections);
        }
        if other.parent.is_some() {
            self.parent = other.parent;
        }
        if !other.developers.is_empty() {
            self.developers.extend(other.developers);
        }
        if !other.publishers.is_empty() {
            self.publishers.extend(other.publishers);
        }
        if !other.expansions.is_empty() {
            self.expansions.extend(other.expansions);
        }
        if !other.dlcs.is_empty() {
            self.dlcs.extend(other.dlcs);
        }
        if !other.remakes.is_empty() {
            self.remakes.extend(other.remakes);
        }
        if !other.remasters.is_empty() {
            self.remasters.extend(other.remasters);
        }
        if !other.screenshots.is_empty() {
            self.screenshots.extend(other.screenshots);
        }
        if !other.artwork.is_empty() {
            self.artwork.extend(other.artwork);
        }
        if !other.websites.is_empty() {
            self.websites.extend(other.websites);
        }
    }
}
