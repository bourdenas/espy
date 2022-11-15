use serde::Deserialize;

#[derive(Deserialize, Default, Debug, Clone)]
pub struct IgdbGame {
    // #[serde(default)]
    pub id: u64,
    pub name: String,
    pub url: String,

    #[serde(default)]
    pub summary: String,

    #[serde(default)]
    pub storyline: String,

    #[serde(default)]
    pub first_release_date: Option<i64>,

    #[serde(default)]
    pub total_rating: Option<f64>,

    #[serde(default)]
    pub genres: Vec<u64>,

    #[serde(default)]
    pub keywords: Vec<u64>,

    #[serde(default)]
    pub expansions: Vec<u64>,

    #[serde(default)]
    pub dlcs: Vec<u64>,

    #[serde(default)]
    pub remakes: Vec<u64>,

    #[serde(default)]
    pub remasters: Vec<u64>,

    #[serde(default)]
    pub bundles: Vec<u64>,

    #[serde(default)]
    pub parent_game: Option<u64>,

    #[serde(default)]
    pub version_parent: Option<u64>,

    #[serde(default)]
    pub collection: Option<u64>,

    #[serde(default)]
    pub franchises: Vec<u64>,

    #[serde(default)]
    pub involved_companies: Vec<u64>,

    #[serde(default)]
    pub cover: Option<u64>,

    #[serde(default)]
    pub screenshots: Vec<u64>,

    #[serde(default)]
    pub artworks: Vec<u64>,

    #[serde(default)]
    pub websites: Vec<u64>,
}

#[derive(Deserialize, Default, Debug, Clone)]
pub struct ExternalGame {
    pub id: u64,
    pub game: u64,
}

#[derive(Deserialize, Default, Debug, Clone)]
pub struct InvolvedCompany {
    pub id: u64,

    #[serde(default)]
    pub company: Option<u64>,

    #[serde(default)]
    pub developer: bool,

    #[serde(default)]
    pub publisher: bool,

    #[serde(default)]
    pub porting: bool,

    #[serde(default)]
    pub supporting: bool,
}

#[derive(Deserialize, Default, Debug, Clone)]
pub struct Company {
    pub id: u64,

    #[serde(default)]
    pub name: String,

    #[serde(default)]
    pub slug: String,

    #[serde(default)]
    pub logo: Option<u64>,
}

#[derive(Deserialize, Default, Debug)]
pub struct Collection {
    pub id: u64,

    #[serde(default)]
    pub name: String,

    #[serde(default)]
    pub slug: String,
}

#[derive(Deserialize, Default, Debug, Clone)]
pub struct Website {
    pub id: u64,
    pub category: i32,
    pub url: String,
}

#[derive(Deserialize, Default, Debug, Clone)]
pub struct Annotation {
    pub id: u64,

    #[serde(default)]
    pub name: String,

    #[serde(default)]
    pub slug: String,
}
