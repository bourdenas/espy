use crate::espy;
use crate::recon;
use crate::steam;
use crate::util;
use std::collections::HashSet;

pub struct LibraryManager {
    pub library: espy::Library,
    user_id: String,
    steam_api: Option<steam::api::SteamApi>,
    recon_service: Option<recon::reconciler::Reconciler>,
}

impl LibraryManager {
    // Creates a LibraryManager instance for a unique user_id id.
    pub fn new(user_id: &str) -> LibraryManager {
        LibraryManager {
            library: espy::Library {
                ..Default::default()
            },
            user_id: String::from(user_id),
            steam_api: None,
            recon_service: None,
        }
    }

    // Build LibraryManager from local stored library if available and by
    // syncing external storefronts.
    pub async fn build(
        &mut self,
        steam_api: steam::api::SteamApi,
        recon_service: recon::reconciler::Reconciler,
    ) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        self.steam_api = Some(steam_api);
        self.recon_service = Some(recon_service);

        let path = format!("target/{}.bin", self.user_id);
        let lib_future = tokio::spawn(async move {
            match util::proto::load(&path) {
                Ok(lib) => lib,
                Err(_) => {
                    eprintln!("Local library not found:'{}'", path);
                    espy::Library {
                        ..Default::default()
                    }
                }
            }
        });

        let steam_entries = match &self.steam_api {
            Some(api) => api.get_owned_games().await?,
            None => espy::SteamList {
                ..Default::default()
            },
        };

        self.library = lib_future.await.unwrap();

        let non_lib_entries = self.get_non_library_entries(steam_entries);
        println!("non_lib_entries: {:?}", non_lib_entries);
        Ok(())
    }

    // Filters Steam game entries that are not included in the manager's library.
    fn get_non_library_entries(&self, entries: espy::SteamList) -> Vec<espy::SteamEntry> {
        // Collect steam ids of reconciled entries.
        let lib_ids =
            self.library
                .entry
                .iter()
                .filter_map(|e| {
                    // Find Steam entry in stores owned and returns the game's steam id.
                    match e.store_owned.iter().find(|store| {
                        store.store_id == espy::game_entry::store::StoreId::Steam as i32
                    }) {
                        Some(store) => Some(store.game_id),
                        None => None,
                    }
                })
                .collect::<HashSet<i64>>();

        entries
            .game
            .into_iter()
            .filter(|e| !lib_ids.contains(&e.id))
            .collect()
    }
}
