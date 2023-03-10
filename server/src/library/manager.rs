use crate::{
    api::{FirestoreApi, IgdbApi},
    documents::{GameEntry, LibraryEntry, StoreEntry},
    games::{ReconReport, Reconciler, Resolver, SteamDataApi},
    Status,
};
use std::sync::{Arc, Mutex};
use tracing::{error, instrument, trace_span, Instrument};

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
        let mut resolved_entries = vec![];
        let mut report = ReconReport {
            lines: vec![format!(
                "Attempted to match {} new entries.",
                store_entries.len()
            )],
        };

        // TODO: Errors will considered failed entry as resolved. Need to filter
        // entries with error (beyond failed to match, which is handled
        // correctly) and retry them.
        for store_entry in store_entries.into_iter() {
            let igdb = Arc::clone(&igdb);
            let steam = Arc::clone(&steam);

            match self.match_entry(igdb, steam, store_entry).await {
                Ok(result) => resolved_entries.push(result),
                Err(e) => report.lines.push(e.to_string()),
            }

            if resolved_entries.len() == 2 {
                let upload_entries = resolved_entries;
                resolved_entries = vec![];
                let firestore = Arc::clone(&self.firestore);
                let user_id = self.user_id.clone();
                tokio::spawn(
                    async move {
                        if let Err(e) = Self::upload_entries(firestore, &user_id, upload_entries) {
                            error!("{e}");
                        }
                    }
                    .instrument(trace_span!("spawn_library_update")),
                );
            }
        }

        Self::upload_entries(Arc::clone(&self.firestore), &self.user_id, resolved_entries)?;

        Ok(report)
    }

    #[instrument(level = "trace", skip(firestore, user_id, entries))]
    fn upload_entries(
        firestore: Arc<Mutex<FirestoreApi>>,
        user_id: &str,
        entries: Vec<(StoreEntry, u64, GameEntry)>,
    ) -> Result<(), Status> {
        let store_entries = entries
            .iter()
            .map(|(store_entry, _, _)| store_entry.clone())
            .collect();

        // Adds all resolved entries in the library.
        // TODO: Should also remove entries from wishlist.
        let firestore = &firestore.lock().unwrap();
        firestore::library::add_entries(firestore, &user_id, entries)?;
        firestore::storefront::add_entries(firestore, &user_id, store_entries)
    }

    #[instrument(level = "trace", skip(self, igdb, steam))]
    async fn match_entry(
        &self,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
        store_entry: StoreEntry,
    ) -> Result<(StoreEntry, u64, GameEntry), Status> {
        let game_entry = Reconciler::recon(&igdb, &store_entry, false).await?;

        match game_entry {
            Some(game_entry) => {
                let (owned_game_id, game_entry) = self
                    .retrieve_game_info(game_entry, igdb, steam, MatchType::BaseGame)
                    .await?;
                Ok((store_entry, owned_game_id, game_entry))
            }
            None => {
                let firestore = &self.firestore.lock().unwrap();
                firestore::failed::add_entry(firestore, &self.user_id, store_entry.clone())?;
                firestore::storefront::add_entry(firestore, &self.user_id, store_entry.clone())?;
                Err(Status::not_found(store_entry.title))
            }
        }
    }

    /// Retrieves full info for a partial GameEntry. Returns an tuple with the
    /// updated GameEntry and game_id of the originally owned game. The
    /// GameEntry might be different from owned_game_id based on the
    /// `match_type` requested, e.g. match with base game.
    #[instrument(
        level = "trace",
        skip(self,  game_entry, igdb, steam)
        fields(
            game = %game_entry.name
        ),
    )]
    pub async fn retrieve_game_info(
        &self,
        game_entry: GameEntry,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
        match_type: MatchType,
    ) -> Result<(u64, GameEntry), Status> {
        let owned_game_id = game_entry.id;
        let game_id = match (match_type, game_entry.parent) {
            (MatchType::BaseGame, Some(parent_id)) => parent_id,
            _ => game_entry.id,
        };

        let game_entry =
            match Resolver::retrieve(game_id, igdb, steam, Arc::clone(&self.firestore)).await? {
                Some(game_entry) => game_entry,
                None => {
                    return Err(Status::not_found(format!(
                        "Could not find game with id={game_id}"
                    )))
                }
            };

        Ok((owned_game_id, game_entry))
    }

    #[instrument(
        level = "trace",
        skip(self, store_entry, game_entry)
        fields(
            store_game = %store_entry.title,
            matched_game = %game_entry.name
        ),
    )]
    pub fn create_library_entry(
        &self,
        store_entry: StoreEntry,
        game_entry: GameEntry,
        owned_game_id: u64,
    ) -> Result<(), Status> {
        let firestore = &self.firestore.lock().unwrap();
        firestore::failed::remove_entry(firestore, &self.user_id, &store_entry)?;
        firestore::wishlist::remove_entry(firestore, &self.user_id, game_entry.id)?;
        firestore::library::add_entry(
            firestore,
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
