use crate::espy;
use crate::gog;
use crate::recon;
use crate::steam;
use crate::util;
use std::collections::HashSet;

pub struct LibraryManager {
    pub library: espy::Library,

    user_id: String,

    recon_service: recon::reconciler::Reconciler,
    steam_api: Option<steam::api::SteamApi>,
    gog_api: Option<gog::api::GogApi>,
}

impl LibraryManager {
    // Creates a LibraryManager instance for a unique user_id id.
    pub fn new(user_id: &str, recon_service: recon::reconciler::Reconciler) -> LibraryManager {
        LibraryManager {
            library: espy::Library::default(),
            user_id: String::from(user_id),
            recon_service: recon_service,
            steam_api: None,
            gog_api: None,
        }
    }

    // Build LibraryManager from local stored library if available and by
    // syncing external storefronts.
    pub async fn build(
        &mut self,
        steam_api: Option<steam::api::SteamApi>,
        gog_api: Option<gog::api::GogApi>,
    ) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        // Load local game library.
        let path = format!("target/{}.bin", self.user_id);
        self.library = load_local_library(&path);

        self.steam_api = steam_api;
        let steam_entries = self.get_steam_entries().await;

        self.gog_api = gog_api;
        let gog_entries = self.get_gog_entries().await;

        let mut new_entries = Vec::<espy::StoreEntry>::new();

        if let Some(steam_entries) = steam_entries {
            new_entries.extend(self.collect_new_entries(steam_entries, &get_steam_id));
        }

        if let Some(gog_entries) = gog_entries {
            new_entries.extend(self.collect_new_entries(gog_entries, &get_gog_id));
        }

        // Try to reconcile entries that do not exist in local library and merge them.
        self.update_library(self.recon_service.reconcile(&new_entries).await?);

        // Save changes in local library.
        util::proto::save(&path, &self.library)?;

        Ok(())
    }

    pub async fn save(&self) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let path = format!("target/{}.bin", self.user_id);
        util::proto::save(&path, &self.library)?;
        Ok(())
    }

    async fn get_steam_entries(&self) -> Option<espy::StoreEntryList> {
        match &self.steam_api {
            Some(steam_api) => Some(steam_api.get_owned_games().await.unwrap()),
            None => None,
        }
    }

    async fn get_gog_entries(&self) -> Option<espy::StoreEntryList> {
        match &self.gog_api {
            Some(gog_api) => Some(gog_api.get_game_entries().await.unwrap()),
            None => None,
        }
    }

    // Returns store entries that are not already contained in the reconciled
    // set of the library.
    fn collect_new_entries(
        &self,
        store_entries: espy::StoreEntryList,
        filter: &dyn Fn(&espy::StoreEntry) -> Option<i64>,
    ) -> Vec<espy::StoreEntry> {
        get_new_entries(
            self.library
                .entry
                .iter()
                .flat_map(|entry| {
                    entry
                        .store_entry
                        .iter()
                        .filter_map(filter)
                        .collect::<Vec<_>>()
                })
                .collect(),
            store_entries,
        )
    }

    // Incorporates library update to the existing library.
    fn update_library(&mut self, update: espy::Library) {
        self.library.unreconciled_store_entry = update.unreconciled_store_entry;
        if !update.entry.is_empty() {
            self.library.entry.extend(update.entry);
        }
    }
}

// Filters Store game entries that are not already included in the input IDs set.
fn get_new_entries(
    existing_ids: HashSet<i64>,
    store_entries: espy::StoreEntryList,
) -> Vec<espy::StoreEntry> {
    store_entries
        .entry
        .into_iter()
        .filter(|store_entry| !existing_ids.contains(&store_entry.id))
        .collect()
}

// Returns the store id if StoreEntry belong to Steam.
fn get_steam_id(store_entry: &espy::StoreEntry) -> Option<i64> {
    if store_entry.store == espy::store_entry::Store::Steam as i32 {
        return Some(store_entry.id);
    }
    None
}

// Returns the store id if StoreEntry belong to GOG.
fn get_gog_id(store_entry: &espy::StoreEntry) -> Option<i64> {
    if store_entry.store == espy::store_entry::Store::Gog as i32 {
        return Some(store_entry.id);
    }
    None
}

// Load a user game library from path.
fn load_local_library(path: &str) -> espy::Library {
    match util::proto::load(&path) {
        Ok(lib) => lib,
        Err(_) => {
            eprintln!("Local library '{}' not found.\nStarting a new one.", path);
            espy::Library::default()
        }
    }
}
