use crate::api::IgdbApi;
use crate::documents::{GameEntry, LibraryEntry, StoreEntry};
use crate::library::search;
use crate::Status;
use futures::stream::{self, StreamExt};
use std::sync::Arc;
use tokio::sync::mpsc;
use tracing::{error, info, instrument, Instrument, trace_span};

// The result of a refresh operation on a `library_entry`.
pub struct Refresh {
    pub library_entry: LibraryEntry,
    pub game_entry: Option<GameEntry>,
}

// The result of a reconcile operation on a `store_entry` with a `game_entry`
// from IGDB.
#[derive(Default)]
pub struct Match {
    pub store_entry: StoreEntry,
    pub game_entry: Option<GameEntry>,
    pub base_game_entry: Option<GameEntry>,
}

impl Match {
    async fn create(store_entry: StoreEntry, game_entry: GameEntry, igdb: &IgdbApi) -> Self {
        Match {
            store_entry,
            base_game_entry: match game_entry.parent {
                Some(parent_id) => match igdb.get_game_by_id(parent_id).await {
                    Ok(game) => game,
                    Err(e) => {
                        error!(
                            "Failed to retrieve base game (id={parent_id}) for '{}'\nerror: {e}",
                            &game_entry.name
                        );
                        None
                    }
                },
                None => None,
            },
            game_entry: Some(game_entry),
        }
    }

    fn failed(store_entry: StoreEntry) -> Self {
        Match {
            store_entry,
            ..Default::default()
        }
    }
}

pub struct Reconciler {
    igdb: Arc<IgdbApi>,
}

impl Reconciler {
    pub fn new(igdb: Arc<IgdbApi>) -> Reconciler {
        Reconciler { igdb }
    }

    /// Returns a fully resolved IGDB GameEntry matching input `id`.
    #[instrument(level = "trace", skip(self))]
    pub async fn retrieve(&self, id: u64) -> Result<GameEntry, Status> {
        get_entry(&self.igdb, id).await
    }

    /// Matches input `entries` with IGDB GameEntries.
    ///
    /// Uses Sender endpoint to emit `Match`es. A `Match` is emitted both on
    /// successful or failed matches.
    #[instrument(
        level = "trace",
        skip(self, tx, store_entries), 
        fields(entries_len = %store_entries.len())
    )]
    pub async fn reconcile(&self, tx: mpsc::Sender<Match>, store_entries: Vec<StoreEntry>) {
        let fut = stream::iter(store_entries.into_iter().map(|store_entry| MatchingTask {
            store_entry,
            igdb: Arc::clone(&self.igdb),
            tx: tx.clone(),
        }))
        .for_each_concurrent(IGDB_CONNECTIONS_LIMIT, match_task)
        .instrument(trace_span!("spawn recon tasks"));

        fut.await;
        drop(tx);
    }

    /// Matches input `entries` with IGDB GameEntries.
    ///
    /// Uses Sender endpoint to emit `Match`es. A `Match` is emitted both on
    /// successful or failed matches.
    #[instrument(
        level = "trace",
        skip(self, tx, library_entries), 
        fields(entries_len = %library_entries.len())
    )]
    pub async fn refresh(&self, tx: mpsc::Sender<Refresh>, library_entries: Vec<LibraryEntry>) {
        let fut = stream::iter(
            library_entries
                .into_iter()
                .map(|library_entry| RefreshTask {
                    library_entry,
                    igdb: Arc::clone(&self.igdb),
                    tx: tx.clone(),
                }),
        )
        .for_each_concurrent(IGDB_CONNECTIONS_LIMIT, refresh_task)
        .instrument(trace_span!("spawn fresh tasks"));

        fut.await;
        drop(tx);
    }
}

const IGDB_CONNECTIONS_LIMIT: usize = 2;

/// Performs a single `RefreshTask` to producea `Refresh` and transmits it over
/// its task's channel.
#[instrument(
    level = "trace",
    skip(task), 
    fields(library_entry = %task.library_entry)
)]
async fn refresh_task(task: RefreshTask) {
    let entry_match = match get_entry(&task.igdb, task.library_entry.id).await {
        Ok(game_entry) => Refresh {
            library_entry: task.library_entry,
            game_entry: Some(game_entry),
        },
        Err(e) => {
            error!("Failed to resolve '{}': {e}", task.library_entry.name);
            Refresh {
                library_entry: task.library_entry,
                game_entry: None,
            }
        }
    };

    if let Err(e) = task.tx.send(entry_match).await {
        error!("{e}");
    }
}

/// Performs a `MatchingTask` to producea `Match` and transmits it over its
/// task's channel.
#[instrument(
    level = "trace",
    skip(task), 
    fields(store_entry = %task.store_entry)
)]
async fn match_task(task: MatchingTask) {
    let entry_match = match match_by_external_id(&task.igdb, &task.store_entry).await {
        Ok(game_entry) => match game_entry {
            Some(game_entry) => Match::create(task.store_entry, game_entry, &task.igdb).await,
            None => match match_by_title(&task.igdb, &task.store_entry).await {
                Ok(game_entry) => match game_entry {
                    Some(game_entry) => {
                        Match::create(task.store_entry, game_entry, &task.igdb).await
                    }
                    None => Match::failed(task.store_entry),
                },
                Err(e) => {
                    error!("match_by_title '{}' failed: {e}", task.store_entry.title);
                    Match::failed(task.store_entry)
                }
            },
        },
        Err(e) => {
            error!(
                "match_by_external_id '{}' failed: {e}",
                task.store_entry.title
            );
            Match::failed(task.store_entry)
        }
    };

    if let Err(e) = task.tx.send(entry_match).await {
        error!("{e}");
    }
}

/// Returns a `GameEntry` from IGDB matching the external storefront id in
/// `store_entry`.
async fn match_by_external_id(
    igdb: &IgdbApi,
    store_entry: &StoreEntry,
) -> Result<Option<GameEntry>, Status> {
    info!("Resolving '{}'", &store_entry.title);
    igdb.match_store_entry(store_entry).await
}

/// Returns a `GameEntry` from IGDB matching the title in `StoreEntry`.
async fn match_by_title(
    igdb: &IgdbApi,
    store_entry: &StoreEntry,
) -> Result<Option<GameEntry>, Status> {
    info!("Searching '{}'", &store_entry.title);

    let candidates = search::get_candidates(igdb, &store_entry.title).await?;
    match candidates.into_iter().next() {
        Some(game_entry) => Ok(Some(get_entry(igdb, game_entry.id).await?)),
        None => Ok(None),
    }
}

/// Returns a `GameEntry` from IGDB that matches the input `id`.
async fn get_entry(igdb: &IgdbApi, id: u64) -> Result<GameEntry, Status> {
    match igdb.get_game_by_id(id).await? {
        Some(game_entry) => Ok(game_entry),
        None => Err(Status::not_found(&format!(
            "Failed to retrieve game entry with id={id}"
        ))),
    }
}

/// Library entry refresh task structure.
struct RefreshTask {
    library_entry: LibraryEntry,
    igdb: Arc<IgdbApi>,
    tx: mpsc::Sender<Refresh>,
}

/// Reconciliation task structure.
struct MatchingTask {
    store_entry: StoreEntry,
    igdb: Arc<IgdbApi>,
    tx: mpsc::Sender<Match>,
}
