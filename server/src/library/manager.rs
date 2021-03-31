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
        self.steam_api = steam_api;
        self.gog_api = gog_api;

        let steam_entries = self.get_steam_entries().await;
        // let _gog_entries = self.get_gog_entries().await;

        // Load local game library.
        let path = format!("target/{}.bin", self.user_id);
        self.library = load_local_library(&path);

        // Try to reconcile entries that do not exist in local library and merge them.
        if let Some(steam_entries) = steam_entries {
            let new_entries = get_new_steam_entries(&self.library, steam_entries);
            self.update_library(self.recon_service.reconcile(&new_entries).await?);

            // Save changes in local library.
            util::proto::save(&path, &self.library)?;
        }

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

    // Incorporates library update to the existing library.
    fn update_library(&mut self, update: espy::Library) {
        self.library.unreconciled_steam_game = update.unreconciled_steam_game;
        if !update.entry.is_empty() {
            self.library.entry.extend(update.entry);
        }
    }
}

// Filters Steam game entries that are not included in the manager's library.
fn get_new_steam_entries(
    library: &espy::Library,
    entries: espy::StoreEntryList,
) -> Vec<espy::StoreEntry> {
    // Collect steam ids of reconciled entries.
    let lib_ids = library
        .entry
        .iter()
        .filter_map(|e| match &e.steam_entry {
            Some(entry) => Some(entry.id),
            None => None,
        })
        .collect::<HashSet<i64>>();

    entries
        .entry
        .into_iter()
        .filter(|e| !lib_ids.contains(&e.id))
        .collect()
}

fn get_new_gog_entries(
    library: &espy::Library,
    entries: espy::StoreEntryList,
) -> Vec<espy::StoreEntry> {
    // Collect GOG ids of reconciled entries.
    let lib_ids = library
        .entry
        .iter()
        .filter_map(|e| match &e.gog_entry {
            Some(enyry) => Some(enyry.id),
            None => None,
        })
        .collect::<HashSet<i64>>();

    entries
        .entry
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
            espy::Library::default()
        }
    }
}
