use crate::{
    api::{FirestoreApi, IgdbApi},
    documents::{GameEntry, LibraryEntry, StoreEntry},
    games::{ReconMatch, ReconReport, Reconciler, Resolver, SteamDataApi},
    Status,
};
use std::sync::{Arc, Mutex};
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

    /// Reconciles store entries from the unmatched collection in Firestore.
    #[instrument(
        level = "trace",
        skip(self, igdb, steam),
        fields(user_id = %self.user_id),
    )]
    pub async fn recon_unmatched_collection(
        &self,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
    ) -> Result<ReconReport, Status> {
        let unmatched_entries =
            firestore::unmatched::list(&self.firestore.lock().unwrap(), &self.user_id)?;
        self.recon_store_entries(unmatched_entries, igdb, steam)
            .await
    }

    /// Reconciles `store_entries` and adds them in the library.
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

    /// Match a `StoreEntry` with a specified `GameEntry` and saving it in the
    /// library.
    #[instrument(level = "trace", skip(self, igdb, steam))]
    pub async fn match_game(
        &self,
        store_entry: StoreEntry,
        game_entry: GameEntry,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
        exact_match: bool,
    ) -> Result<(), Status> {
        let owned_game_id = game_entry.id;
        let game_id = match (exact_match, game_entry.parent) {
            (false, Some(parent_id)) => parent_id,
            _ => game_entry.id,
        };

        let game_entry =
            Resolver::retrieve(game_id, igdb, steam, Arc::clone(&self.firestore)).await?;

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
        delete: bool,
    ) -> Result<(), Status> {
        let firestore = &self.firestore.lock().unwrap();
        firestore::library::remove_entry(firestore, &self.user_id, &store_entry, library_entry)?;
        match delete {
            false => firestore::failed::add_entry(firestore, &self.user_id, store_entry),
            true => firestore::storefront::remove(firestore, &self.user_id, &store_entry),
        }
    }

    #[instrument(level = "trace", skip(self, igdb, steam))]
    pub async fn rematch_game(
        &self,
        store_entry: StoreEntry,
        game_entry: GameEntry,
        existing_library_entry: &LibraryEntry,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
        exact_match: bool,
    ) -> Result<(), Status> {
        let game_entry =
            Resolver::retrieve(game_entry.id, igdb, steam, Arc::clone(&self.firestore)).await?;

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
}
