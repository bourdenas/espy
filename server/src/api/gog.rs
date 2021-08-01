use crate::api;
use crate::models::StoreEntry;
use crate::Status;

pub struct GogApi {
    token: api::GogToken,
}

impl GogApi {
    pub fn new(token: api::GogToken) -> GogApi {
        GogApi { token }
    }

    pub async fn get_game_ids(&self) -> Result<GogGamesList, Status> {
        let uri = format!("{}/user/data/games", GOG_API_HOST);

        let game_list = reqwest::Client::new()
            .get(&uri)
            .header(
                "Authorization",
                format!("Bearer {}", &self.token.access_token),
            )
            .send()
            .await?
            .json::<GogGamesList>()
            .await?;

        Ok(game_list)
    }

    pub async fn get_owned_games(&self) -> Result<Vec<StoreEntry>, Status> {
        let mut store_entries: Vec<StoreEntry> = vec![];

        for page in 1.. {
            let uri = format!(
                "{}/account/getFilteredProducts?mediaType=1&page={}",
                GOG_API_HOST, page
            );
            let resp = reqwest::Client::new()
                .get(&uri)
                .header(
                    "Authorization",
                    format!("Bearer {}", &self.token.access_token),
                )
                .send()
                .await?
                .json::<GogProductListResponse>()
                .await?;

            let product_list_page = match resp {
                GogProductListResponse::Ok(pl) => pl,
                GogProductListResponse::Err(gog_err) => {
                    return Err(Status::internal("Failed to retrieve GOG entries", gog_err));
                }
            };

            store_entries.extend(product_list_page.products.into_iter().map(|product| {
                StoreEntry {
                    id: product.id as i64,
                    title: product.title,
                    storefront_name: String::from("gog"),
                    url: product.url,
                    image: product.image,
                }
            }));

            if page >= product_list_page.total_pages {
                break;
            }
        }
        Ok(store_entries)
    }
}

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct GogGamesList {
    owned: Vec<u32>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(untagged)]
enum GogProductListResponse {
    Ok(GogProductList),
    Err(GogError),
}

#[derive(Debug, Serialize, Deserialize, Default)]
struct GogError {
    error: String,
    error_description: String,
}

use std::fmt;
impl fmt::Display for GogError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "GOG response error: '{}' -- {}",
            self.error, self.error_description
        )
    }
}

use std::error::Error;
impl Error for GogError {}

#[derive(Debug, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
struct GogProductList {
    page: u32,
    total_pages: u32,
    total_products: u32,
    products_per_page: u32,
    products: Vec<GogProduct>,
}

#[derive(Debug, Serialize, Deserialize, Default)]
struct GogProduct {
    id: u32,
    title: String,
    image: String,
    url: String,
}

const GOG_API_HOST: &str = "https://embed.gog.com";
