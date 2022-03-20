use crate::documents::Annotation;
use crate::igdb;
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
    #[serde(skip_serializing_if = "String::is_empty")]
    pub storyline: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub release_date: Option<i64>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub expansions: Vec<GameEntry>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub remasters: Vec<GameEntry>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub versions: Vec<u64>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parent: Option<u64>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub collections: Vec<Annotation>,

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

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub websites: Vec<Website>,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Image {
    pub image_id: String,
    pub height: i32,
    pub width: i32,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Website {
    pub url: String,
    pub authority: WebsiteAuthority,
}

#[derive(Serialize, Deserialize, Debug)]
pub enum WebsiteAuthority {
    Null = 0,
    Official = 1,
    Wikipedia = 2,
    Gog = 3,
    Steam = 4,
    Egs = 5,
    Youtube = 6,
}

impl Default for WebsiteAuthority {
    fn default() -> Self {
        WebsiteAuthority::Null
    }
}

impl GameEntry {
    pub fn new(igdb_game: igdb::Game) -> Self {
        GameEntry {
            id: igdb_game.id,
            name: igdb_game.name,
            summary: igdb_game.summary,
            storyline: igdb_game.storyline,
            release_date: match igdb_game.first_release_date {
                Some(date) => Some(date.seconds),
                None => None,
            },
            expansions: igdb_game
                .expansions
                .into_iter()
                .map(|expansion| GameEntry::new(expansion))
                .collect(),
            remasters: igdb_game
                .remasters
                .into_iter()
                .map(|remaster| GameEntry::new(remaster))
                .collect(),
            versions: igdb_game
                .bundles
                .into_iter()
                .map(|bundle| bundle.id)
                .collect(),
            parent: match igdb_game.parent_game {
                Some(parent) => Some(parent.id),
                None => match igdb_game.version_parent {
                    Some(parent) => Some(parent.id),
                    None => None,
                },
            },
            // Place both IGDB collection and franchises under a single collections
            // Annotation.
            collections: (match igdb_game.collection {
                Some(collection) => vec![Annotation {
                    id: collection.id,
                    name: collection.name,
                }],
                None => vec![],
            })
            .into_iter()
            .chain(
                igdb_game
                    .franchises
                    .into_iter()
                    .map(|franchise| Annotation {
                        id: franchise.id,
                        name: franchise.name,
                    }),
            )
            .collect(),
            companies: igdb_game
                .involved_companies
                .into_iter()
                .filter_map(|involved_company| match involved_company.company {
                    Some(company) => match company.name.is_empty() {
                        false => Some(Annotation {
                            id: company.id,
                            name: company.name,
                        }),
                        true => None,
                    },
                    None => None,
                })
                .collect(),
            cover: match igdb_game.cover {
                Some(cover) => Some(Image {
                    image_id: cover.image_id,
                    height: cover.height,
                    width: cover.width,
                }),
                None => None,
            },
            screenshots: igdb_game
                .screenshots
                .into_iter()
                .map(|image| Image {
                    image_id: image.image_id,
                    height: image.height,
                    width: image.width,
                })
                .collect(),
            artwork: igdb_game
                .artworks
                .into_iter()
                .map(|image| Image {
                    image_id: image.image_id,
                    height: image.height,
                    width: image.width,
                })
                .collect(),
            websites: vec![],
        }
    }
}
