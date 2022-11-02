use crate::{
    api::IgdbApi,
    documents::{GameEntry, StoreEntry},
    library::{search, steam_data},
    Status,
};
use futures::stream::{self, StreamExt};
use std::sync::Arc;
use tokio::sync::mpsc;
use tracing::{debug, error, instrument, trace_span, Instrument};

// The result of a reconcile operation on a `store_entry` with a `game_entry`
// from IGDB.
#[derive(Default)]
pub struct Match {
    pub store_entry: StoreEntry,
    pub game_entry: Option<GameEntry>,
}

impl Match {
    async fn create(store_entry: StoreEntry, game_entry: GameEntry, igdb: &IgdbApi) -> Self {
        Match {
            store_entry,
            game_entry: match game_entry.parent {
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
                None => Some(game_entry),
            },
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
        fields(entries_len = %store_entries.len()),
    )]
    pub async fn reconcile(&self, tx: mpsc::Sender<Match>, store_entries: Vec<StoreEntry>) {
        let fut = stream::iter(store_entries.into_iter().map(|store_entry| MatchingTask {
            store_entry,
            igdb: Arc::clone(&self.igdb),
            tx: tx.clone(),
        }))
        .for_each_concurrent(4, match_task)
        .instrument(trace_span!("spawn recon tasks"));

        fut.await;
        drop(tx);
    }
}

/// Performs a `MatchingTask` to producea `Match` and transmits it over its
/// task's channel.
#[instrument(
    level = "trace",
    skip(task),
    fields(store_entry = %task.store_entry),
)]
async fn match_task(task: MatchingTask) {
    let mut entry_match = match match_by_external_id(&task.igdb, &task.store_entry).await {
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

    // Retrieve Steam data for matched GameEntry.
    if let Some(game_entry) = &mut entry_match.game_entry {
        if let Err(e) = steam_data::retrieve_steam_data(game_entry).await {
            error!("{e}");
        }
    }

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
    debug!("Resolving '{}'", &store_entry.title);

    match store_entry.id.is_empty() {
        true => Ok(None),
        false => igdb.match_store_entry(store_entry).await,
    }
}

/// Returns a `GameEntry` from IGDB matching the title in `StoreEntry`.
async fn match_by_title(
    igdb: &IgdbApi,
    store_entry: &StoreEntry,
) -> Result<Option<GameEntry>, Status> {
    debug!("Searching '{}'", &store_entry.title);

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

/// Reconciliation task structure.
struct MatchingTask {
    store_entry: StoreEntry,
    igdb: Arc<IgdbApi>,
    tx: mpsc::Sender<Match>,
}
