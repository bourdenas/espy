use crate::api::GogToken;
use crate::espy;
use crate::Status;

pub struct GogApi {
    token: GogToken,
}

impl GogApi {
    pub fn new(token: GogToken) -> GogApi {
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

    pub async fn get_game_entries(&self) -> Result<espy::StoreEntryList, Status> {
        let mut gog_list = espy::StoreEntryList {
            ..Default::default()
        };

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

            gog_list
                .entry
                .extend(
                    product_list_page
                        .products
                        .into_iter()
                        .map(|product| espy::StoreEntry {
                            id: product.id as i64,
                            title: product.title,
                            store: espy::store_entry::Store::Gog as i32,
                            url: product.url,
                            image: product.image,
                        }),
                );

            if page >= product_list_page.total_pages {
                break;
            }
        }
        Ok(gog_list)
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
