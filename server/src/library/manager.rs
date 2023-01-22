use crate::{
    api::{FirestoreApi, GogApi, IgdbApi, SteamApi},
    documents::{GameEntry, LibraryEntry, StoreEntry},
    games::{Archiver, ReconMatch, ReconReport, Reconciler, SteamDataApi},
    traits, Status,
};
use std::{
    collections::HashSet,
    sync::{Arc, Mutex},
};
use tokio::sync::mpsc;
use tracing::{instrument, trace_span, Instrument};

use super::firestore;

pub struct LibraryManager {
    user_id: String,
    firestore: Arc<Mutex<FirestoreApi>>,
}

impl LibraryManager {
    /// Creates a LibraryManager instance for a user.
    pub fn new(user_id: &str, firestore: Arc<Mutex<FirestoreApi>>) -> Self {
        LibraryManager {
            user_id: String::from(user_id),
            firestore,
        }
    }

    /// Retrieves new entries from remote storefronts the user has access to and
    /// expands existing library entries.
    #[instrument(
        level = "trace",
        skip(self, steam_api, gog_api, igdb, steam),
        fields(user_id = %self.user_id),
    )]
    pub async fn sync_library(
        &self,
        steam_api: Option<SteamApi>,
        gog_api: Option<GogApi>,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
    ) -> Result<ReconReport, Status> {
        if let Some(api) = steam_api {
            self.sync_storefront(&api).await?;
        }
        if let Some(api) = gog_api {
            self.sync_storefront(&api).await?;
        }

        let unmatched_entries =
            firestore::unmatched::list(&self.firestore.lock().unwrap(), &self.user_id)?;
        self.recon_store_entries(unmatched_entries, igdb, steam)
            .await
    }

    /// Reconciles `store_entries` and adds them in the user's library.
    #[instrument(
        level = "trace",
        skip(self, store_entries, igdb, steam),
        fields(
            user_id = %self.user_id,
            entries_num = %store_entries.len()
        ),
    )]
    pub async fn recon_store_entries(
        &self,
        store_entries: Vec<StoreEntry>,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
    ) -> Result<ReconReport, Status> {
        let (tx, rx) = mpsc::channel(32);

        tokio::spawn(
            async move {
                Reconciler::new(igdb, steam)
                    .reconcile(tx, store_entries)
                    .await;
            }
            .instrument(trace_span!("spawn recon job")),
        );

        Ok(self.receive_matches(rx).await)
    }

    /// Match a `StoreEntry` to a specified `GameEntry` and saving it in the
    /// user's library.
    #[instrument(level = "trace", skip(self, igdb, steam))]
    pub async fn manual_match(
        &self,
        store_entry: StoreEntry,
        game_entry: GameEntry,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
    ) -> Result<(), Status> {
        let owned_game_id = game_entry.id;
        let game_id = match game_entry.parent {
            Some(parent_id) => parent_id,
            None => game_entry.id,
        };

        let game_entry =
            Archiver::retrieve(game_id, igdb, steam, Arc::clone(&self.firestore)).await?;

        let firestore = &self.firestore.lock().unwrap();
        firestore::failed::remove_entry(firestore, &self.user_id, &store_entry)?;
        firestore::wishlist::remove_entry(firestore, &self.user_id, game_entry.id)?;
        firestore::library::add_entry(
            &firestore,
            &self.user_id,
            store_entry,
            owned_game_id,
            game_entry,
        )
    }

    /// Unmatch a `StoreEntry` from user's library. The StoreEntry is not
    /// deleted. Instead it is moved into the failed matches.
    #[instrument(level = "trace", skip(self, library_entry))]
    pub async fn unmatch_game(
        &self,
        store_entry: StoreEntry,
        library_entry: &LibraryEntry,
    ) -> Result<(), Status> {
        let firestore = &self.firestore.lock().unwrap();
        firestore::library::remove_entry(firestore, &self.user_id, &store_entry, library_entry)?;
        firestore::failed::add_entry(firestore, &self.user_id, store_entry)
    }

    /// Deletes a `StoreEntry` from user's library. The StoreEntry is completely
    /// removed.
    #[instrument(level = "trace", skip(self, library_entry))]
    pub async fn delete_game(
        &self,
        store_entry: &StoreEntry,
        library_entry: &LibraryEntry,
    ) -> Result<(), Status> {
        let firestore = &self.firestore.lock().unwrap();
        firestore::library::remove_entry(firestore, &self.user_id, store_entry, library_entry)?;
        firestore::storefront::remove(firestore, &self.user_id, store_entry)
    }

    #[instrument(level = "trace", skip(self, igdb, steam))]
    pub async fn rematch_game(
        &self,
        store_entry: StoreEntry,
        game_entry: GameEntry,
        existing_library_entry: &LibraryEntry,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
    ) -> Result<(), Status> {
        let game_entry =
            Archiver::retrieve(game_entry.id, igdb, steam, Arc::clone(&self.firestore)).await?;

        let firestore = &self.firestore.lock().unwrap();
        firestore::library::remove_entry(
            firestore,
            &self.user_id,
            &store_entry,
            existing_library_entry,
        )?;
        firestore::library::add_entry(
            firestore,
            &self.user_id,
            store_entry,
            game_entry.id,
            game_entry,
        )
    }

    async fn receive_matches(&self, mut rx: mpsc::Receiver<ReconMatch>) -> ReconReport {
        let mut report = ReconReport { lines: vec![] };

        while let Some(recon_match) = rx.recv().await {
            match &recon_match.game_entry {
                Some(entry) => report.lines.push(format!(
                    "matched '{}' ({}) with {}",
                    &recon_match.store_entry.title,
                    &recon_match.store_entry.storefront_name,
                    &entry.name,
                )),
                None => report.lines.push(format!(
                    "failed to match {} ({})",
                    &recon_match.store_entry.title, &recon_match.store_entry.storefront_name,
                )),
            };

            let firestore = Arc::clone(&self.firestore);
            let user_id = self.user_id.clone();
            tokio::spawn(
                async move {
                    let firestore = &firestore.lock().unwrap();
                    firestore::unmatched::delete(firestore, &user_id, &recon_match.store_entry)
                        .expect("firestore::unmatched::delete()");

                    match recon_match.game_entry {
                        Some(game_entry) => {
                            firestore::games::write(firestore, &game_entry)
                                .expect("firestore::games::write()");
                            firestore::library::add_entry(
                                firestore,
                                &user_id,
                                recon_match.store_entry,
                                game_entry.id,
                                game_entry,
                            )
                            .expect("firestore::library::add_entry()")
                        }
                        None => {
                            firestore::failed::add_entry(
                                firestore,
                                &user_id,
                                recon_match.store_entry,
                            )
                            .expect("firestore::failed::add_entry()");
                        }
                    }
                }
                .instrument(trace_span!("spawn handle match")),
            );
        }
        report
    }

    #[instrument(level = "trace", skip(self))]
    pub async fn add_to_wishlist(&self, library_entry: LibraryEntry) -> Result<(), Status> {
        firestore::wishlist::add_entry(
            &self.firestore.lock().unwrap(),
            &self.user_id,
            library_entry,
        )
    }

    #[instrument(level = "trace", skip(self))]
    pub async fn remove_from_wishlist(&self, game_id: u64) -> Result<(), Status> {
        firestore::wishlist::remove_entry(&self.firestore.lock().unwrap(), &self.user_id, game_id)
    }

    /// Retieves new game entries from the provided remote storefront and
    /// temporarily stores them in unmatched in Firestore.
    #[instrument(level = "trace", skip(self, api))]
    async fn sync_storefront<T: traits::Storefront>(&self, api: &T) -> Result<(), Status> {
        let store_entries = api.get_owned_games().await?;

        let firestore = &self.firestore.lock().unwrap();

        let mut game_ids = HashSet::<String>::from_iter(
            firestore::storefront::read(firestore, &self.user_id, &T::id()).into_iter(),
        );

        let mut store_entries = store_entries;
        store_entries.retain(|entry| !game_ids.contains(&entry.id));

        for entry in &store_entries {
            firestore::unmatched::write(firestore, &self.user_id, entry)?;
        }

        game_ids.extend(store_entries.into_iter().map(|store_entry| store_entry.id));
        firestore::storefront::write(
            firestore,
            &self.user_id,
            &T::id(),
            game_ids.into_iter().collect::<Vec<_>>(),
        )
    }
}
