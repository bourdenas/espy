use crate::espy;
use crate::recon;
use crate::steam;
use crate::util;
use std::collections::HashSet;
use std::sync::Arc;

pub struct LibraryManager {
    pub library: espy::Library,
    user_id: String,
    recon_service: recon::reconciler::Reconciler,
    steam_api: Option<Arc<steam::api::SteamApi>>,
}

impl LibraryManager {
    // Creates a LibraryManager instance for a unique user_id id.
    pub fn new(user_id: &str, recon_service: recon::reconciler::Reconciler) -> LibraryManager {
        LibraryManager {
            library: espy::Library {
                ..Default::default()
            },
            user_id: String::from(user_id),
            recon_service: recon_service,
            steam_api: None,
        }
    }

    // Build LibraryManager from local stored library if available and by
    // syncing external storefronts.
    pub async fn build(
        &mut self,
        steam_api: Option<steam::api::SteamApi>,
    ) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        if let Some(steam_api) = steam_api {
            self.steam_api = Some(Arc::new(steam_api));
        }

        // Retrieve Steam games if steam_api is available.
        let steam_entries_future = match &self.steam_api {
            Some(steam_api) => {
                let steam_api = Arc::clone(&steam_api);
                Some(tokio::spawn(async move {
                    steam_api.get_owned_games().await.unwrap()
                }))
            }
            None => None,
        };

        // Load local game library.
        let path = format!("target/{}.bin", self.user_id);
        self.library = load_local_library(&path);

        // Try to reconcile entries that do not exist in local library and merge them.
        if let Some(steam_entries_future) = steam_entries_future {
            let new_entries = get_unreconciled_entries(&self.library, steam_entries_future.await?);
            self.update_library(self.recon_service.reconcile(&new_entries).await?);

            // Save changes in local library.
            util::proto::save(&path, &self.library)?;
            util::proto::save_text(&format!("target/{}.asciipb", self.user_id), &self.library)?;
        }

        Ok(())
    }

    // Incorporates library update to the existing library.
    fn update_library(&mut self, update: espy::Library) {
        self.library.unreconciled_steam_game = update.unreconciled_steam_game;
        if !update.entry.is_empty() {
            self.library.entry.extend(update.entry);
        }
    }
}

// Filters Steam game entries that are not included in the manager's library.
fn get_unreconciled_entries(
    library: &espy::Library,
    entries: espy::SteamList,
) -> Vec<espy::SteamEntry> {
    // Collect steam ids of reconciled entries.
    let lib_ids = library
        .entry
        .iter()
        .filter_map(|e| {
            // Find Steam entry in stores owned and returns the game's steam id.
            match e
                .store_owned
                .iter()
                .find(|store| store.store_id == espy::game_entry::store::StoreId::Steam as i32)
            {
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

// Load a user game library from path.
fn load_local_library(path: &str) -> espy::Library {
    match util::proto::load(&path) {
        Ok(lib) => lib,
        Err(_) => {
            eprintln!("Local library '{}' not found.\nStarting a new one.", path);
            espy::Library {
                ..Default::default()
            }
        }
    }
}
