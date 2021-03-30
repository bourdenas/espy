pub struct GogApi {
    token: String,
}

impl GogApi {
    pub fn new(token: &str) -> GogApi {
        GogApi {
            token: String::from(token),
        }
    }

    pub async fn get_games(
        &self,
    ) -> Result<GogGamesList, Box<dyn std::error::Error + Send + Sync>> {
        let uri = format!("{}/user/data/games", GOG_API_HOST);

        let game_list = reqwest::Client::new()
            .get(&uri)
            .header("Authorization", format!("Bearer {}", &self.token))
            .send()
            .await?
            .json::<GogGamesList>()
            .await?;
        println!("steam games: {:#?}", game_list);

        Ok(game_list)
    }

    pub async fn get_filtered_products(
        &self,
    ) -> Result<GogProductList, Box<dyn std::error::Error + Send + Sync>> {
        let mut product_list = GogProductList {
            ..Default::default()
        };

        for page in 1.. {
            let uri = format!(
                "{}/account/getFilteredProducts?mediaType=1&page={}",
                GOG_API_HOST, page
            );
            let product_list_page = reqwest::Client::new()
                .get(&uri)
                .header("Authorization", format!("Bearer {}", &self.token))
                .send()
                .await?
                .json::<GogProductList>()
                .await?;
            println!("steam games: {:#?}", product_list_page);

            if page == 1 {
                product_list = product_list_page;
            } else {
                product_list
                    .products
                    .extend(product_list_page.products.into_iter());
            }

            if page >= product_list.total_pages {
                break;
            }
        }
        Ok(product_list)
    }
}

pub async fn get_token(code: &str) -> Result<String, Box<dyn std::error::Error + Send + Sync>> {
    let params = format!(
        "/token?client_id={}&client_secret={}&grant_type=authorization_code&code={}&redirect_uri={}%2Ftoken", 
        GOG_GALAXY_CLIENT_ID, GOG_GALAXY_SECRET, code, GOG_GALAXY_REDIRECT_URI);
    let uri = format!("{}{}", GOG_AUTH_HOST, params);
    println!("{}", uri);

    let resp = reqwest::get(&uri).await?.json::<GogTokenResponse>().await?;
    println!("gog token resp: {:#?}", resp);

    Ok(resp.access_token)
}

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct GogTokenResponse {
    expires_in: u32,
    access_token: String,
    user_id: String,
    refresh_token: String,
    session_id: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GogGamesList {
    owned: Vec<u32>,
}

#[derive(Debug, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct GogProductList {
    page: u32,
    total_pages: u32,
    total_products: u32,
    products_per_page: u32,
    products: Vec<GogProduct>,
}

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct GogProduct {
    id: u32,
    title: String,
    image: String,
    url: String,
}

const GOG_AUTH_HOST: &str = "https://auth.gog.com";
const GOG_API_HOST: &str = "https://embed.gog.com";
const GOG_GALAXY_CLIENT_ID: &str = "46899977096215655";
const GOG_GALAXY_SECRET: &str = "9d85c43b1482497dbbce61f6e4aa173a433796eeae2ca8c5f6129f2dc4de46d9";
const GOG_GALAXY_REDIRECT_URI: &str =
    "https%3A%2F%2Fembed.gog.com%2Fon_login_success%3Forigin%3Dclient";
