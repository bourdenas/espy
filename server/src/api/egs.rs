use crate::documents::StoreEntry;
use crate::traits::Storefront;
use crate::Status;
use async_trait::async_trait;
use egs_api::EpicGames;

pub struct EgsApi {
    games: Vec<StoreEntry>,
}

impl EgsApi {
    pub async fn connect(code: &str) -> Result<Self, Status> {
        let mut egs = EpicGames::new();
        egs.auth_code(None, Some(code.to_owned())).await;
        egs.login().await;

        match egs.library_items(true).await {
            Some(library) => Ok(Self {
                games: library
                    .records
                    .into_iter()
                    .map(|record| StoreEntry {
                        id: record.catalog_item_id,
                        title: record.sandbox_name,
                        storefront_name: EgsApi::id(),
                        ..Default::default()
                    })
                    .collect(),
            }),
            None => Err(Status::new("Failed to retrieve games from EgsApi.")),
        }
    }
}

/// Implements Storefront trait game retrieval for EgsApi.
///
/// Implementation of EgsApi is very weird and inefficient because egs-api needs
/// (for some reason) mutating refs, which makes it incompatible with the rest
/// of the APIs.
#[async_trait]
impl Storefront for EgsApi {
    fn id() -> String {
        String::from("egs")
    }

    async fn get_owned_games(&self) -> Result<Vec<StoreEntry>, Status> {
        println!("epic games: {}", self.games.len());
        Ok(self.games.clone())
    }
}
