use crate::{
    api::{FirestoreApi, IgdbApi},
    documents::{GameEntry, LibraryEntry, StoreEntry},
    games::{ReconReport, Reconciler, Resolver, SteamDataApi},
    Status,
};
use std::sync::{Arc, Mutex};
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
        let mut report = ReconReport {
            lines: vec![format!(
                "Attempted to match {} new entries.",
                store_entries.len()
            )],
        };

        let handles: Vec<_> = store_entries
            .into_iter()
            .map(|store_entry| {
                let igdb = Arc::clone(&igdb);
                let steam = Arc::clone(&steam);
                let firestore = Arc::clone(&self.firestore);
                let user_id = self.user_id.clone();
                tokio::spawn(
                    async move {
                        let game_entry = Reconciler::recon(&igdb, &store_entry, false).await?;

                        match game_entry {
                            Some(game_entry) => {
                                let report_line = format!(
                                    "  matched '{}' ({}) with {}",
                                    &store_entry.title,
                                    &store_entry.storefront_name,
                                    &game_entry.name,
                                );
                                // TODO: The single match operation is not
                                // optimal for multiple matches. The read/write
                                // library operation is slow. This can be
                                // optimized by bundlings all updates in a
                                // single write.
                                Self::match_game_impl(
                                    &user_id,
                                    store_entry,
                                    game_entry,
                                    igdb,
                                    steam,
                                    firestore,
                                    MatchType::BaseGame,
                                )
                                .await?;
                                Ok::<String, Status>(report_line)
                            }
                            None => {
                                let report_line = format!(
                                    "  failed to match {} ({})",
                                    &store_entry.title, &store_entry.storefront_name,
                                );
                                let firestore = &firestore.lock().unwrap();
                                firestore::failed::add_entry(
                                    firestore,
                                    &user_id,
                                    store_entry.clone(),
                                )?;
                                firestore::unmatched::delete(firestore, &user_id, &store_entry)?;
                                Ok(report_line)
                            }
                        }
                    }
                    .instrument(trace_span!("spawn match entry")),
                )
            })
            .collect();

        futures::future::join_all(handles)
            .await
            .into_iter()
            .filter_map(|x| x.ok())
            .for_each(|report_line| match report_line {
                Ok(line) => report.lines.push(line),
                Err(e) => report.lines.push(format!("{e}")),
            });

        Ok(report)
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
        match_type: MatchType,
    ) -> Result<(), Status> {
        Self::match_game_impl(
            &self.user_id,
            store_entry,
            game_entry,
            igdb,
            steam,
            Arc::clone(&self.firestore),
            match_type,
        )
        .await
    }

    /// Need to make this a static function so that it can be called inside tokio::spawn.
    async fn match_game_impl(
        user_id: &str,
        store_entry: StoreEntry,
        game_entry: GameEntry,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
        firestore: Arc<Mutex<FirestoreApi>>,
        match_type: MatchType,
    ) -> Result<(), Status> {
        let owned_game_id = game_entry.id;
        let game_id = match (match_type, game_entry.parent) {
            (MatchType::BaseGame, Some(parent_id)) => parent_id,
            _ => game_entry.id,
        };

        let game_entry =
            match Resolver::retrieve(game_id, igdb, steam, Arc::clone(&firestore)).await? {
                Some(game_entry) => game_entry,
                None => {
                    return Err(Status::not_found(format!(
                        "Could not find game with id={game_id}"
                    )))
                }
            };

        let firestore = &firestore.lock().unwrap();
        firestore::unmatched::delete(firestore, user_id, &store_entry)?;
        firestore::failed::remove_entry(firestore, user_id, &store_entry)?;
        firestore::wishlist::remove_entry(firestore, user_id, game_entry.id)?;
        firestore::library::add_entry(&firestore, user_id, store_entry, owned_game_id, game_entry)
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
        match_type: MatchType,
    ) -> Result<(), Status> {
        let game_entry =
            match Resolver::retrieve(game_entry.id, igdb, steam, Arc::clone(&self.firestore))
                .await?
            {
                Some(game_entry) => game_entry,
                None => {
                    return Err(Status::not_found(format!(
                        "Could not find game with id={}",
                        game_entry.id
                    )))
                }
            };

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
            game_entry.id, // TODO: This is probably incorrect.
            game_entry,
        )
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

    /// Remove all entries in user library from specified storefront.
    #[instrument(level = "trace", skip(self))]
    pub async fn remove_storefront(&self, storefront_id: &str) -> Result<(), Status> {
        let firestore = &self.firestore.lock().unwrap();

        firestore::library::remove_storefront(firestore, &self.user_id, storefront_id)?;
        firestore::failed::remove_storefront(firestore, &self.user_id, storefront_id)?;
        firestore::storefront::delete(firestore, &self.user_id, storefront_id)
    }
}

#[derive(Debug)]
pub enum MatchType {
    Exact,
    BaseGame,
}
