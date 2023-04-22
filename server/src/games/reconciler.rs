use std::sync::{Arc, Mutex};

use crate::{
    api::{FirestoreApi, IgdbApi},
    documents::{GameEntry, StoreEntry},
    library::firestore,
    Status,
};
use tracing::{info, instrument};

pub struct Reconciler;

impl Reconciler {
    /// Attempts to reconcile a `StoreEntry` with an IGDB game.
    ///
    /// It initially tries to use the external game table for finding the
    /// corresponding entry. If that fails it performs a search by title and
    /// matches with the best candidate.
    ///
    /// The returned GameEntry is a shallow entry (single IGDB lookup). If
    /// `use_base_game` is `true`, the entry returned is the base game instead
    /// of the exact match, e.g. remastered version or expansion / DLC.
    #[instrument(level = "trace", skip(firestore, igdb, store_entry))]
    pub async fn recon(
        firestore: Arc<Mutex<FirestoreApi>>,
        igdb: &IgdbApi,
        store_entry: &StoreEntry,
    ) -> Result<Option<GameEntry>, Status> {
        match match_by_external_id(Arc::clone(&firestore), igdb, store_entry).await? {
            Some(game_entry) => Ok(Some(game_entry)),
            None => match match_by_title(firestore, igdb, &store_entry.title).await? {
                Some(game_entry) => Ok(Some(game_entry)),
                None => Ok(None),
            },
        }
    }
}

/// Returns a `GameEntry` from IGDB matching the external storefront id in
/// `store_entry`.
#[instrument(level = "trace", skip(firestore, igdb))]
async fn match_by_external_id(
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: &IgdbApi,
    store_entry: &StoreEntry,
) -> Result<Option<GameEntry>, Status> {
    info!("Matching external '{}'", &store_entry.title);

    match store_entry.id.is_empty() {
        false => {
            let external_game = {
                let firestore = &firestore.lock().unwrap();
                match firestore::external_games::read(
                    firestore,
                    &store_entry.storefront_name,
                    &store_entry.id,
                ) {
                    Ok(external_game) => external_game,
                    Err(Status::NotFound(_)) => return Ok(None),
                    Err(e) => return Err(e),
                }
            };
            let game_entry = {
                let firestore = &firestore.lock().unwrap();
                firestore::games::read(firestore, external_game.igdb_id)
            };
            match game_entry {
                Ok(game_entry) => Ok(Some(game_entry)),
                Err(Status::NotFound(_)) => {
                    let igdb_game = igdb.get(external_game.igdb_id).await?;
                    let game_entry = igdb.resolve(igdb_game).await?;
                    {
                        firestore::games::write(&firestore.lock().unwrap(), &game_entry)?;
                    }
                    Ok(Some(game_entry))
                }
                Err(e) => Err(e),
            }
        }
        true => Ok(None),
    }
}

/// Returns a `GameEntry` from IGDB matching the `title`.
#[instrument(level = "trace", skip(firestore, igdb))]
async fn match_by_title(
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: &IgdbApi,
    title: &str,
) -> Result<Option<GameEntry>, Status> {
    info!("Searching by title '{}'", title);

    let candidates = igdb.search_by_title(title).await?;
    match candidates.into_iter().next() {
        Some(igdb_game) => {
            let game_entry = { firestore::games::read(&firestore.lock().unwrap(), igdb_game.id) };
            match game_entry {
                Ok(game_entry) => Ok(Some(game_entry)),
                Err(Status::NotFound(_)) => {
                    let game_entry = igdb.resolve(igdb_game).await?;
                    {
                        firestore::games::write(&firestore.lock().unwrap(), &game_entry)?;
                    }
                    Ok(Some(game_entry))
                }
                Err(e) => Err(e),
            }
        }
        None => Ok(None),
    }
}
