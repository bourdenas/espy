use crate::api::IgdbApi;
use crate::documents::{self, GameEntry, LibraryEntry, StoreEntry};
use crate::igdb;
use crate::library::search;
use crate::Status;
use futures::stream::{self, StreamExt};
use std::sync::Arc;
use tokio::sync::mpsc;

// The result of a refresh operation on a `library_entry`.
pub struct Refresh {
    pub library_entry: LibraryEntry,
    pub game_entry: Option<GameEntry>,
}

// The result of a reconcile operation on a `store_entry` with a `game_entry`
// from IGDB.
pub struct Match {
    pub store_entry: StoreEntry,
    pub game_entry: Option<GameEntry>,
}

pub struct Reconciler {
    igdb: Arc<IgdbApi>,
}

impl Reconciler {
    pub fn new(igdb: Arc<IgdbApi>) -> Reconciler {
        Reconciler { igdb }
    }

    /// Matches input `entries` with IGDB GameEntries.
    ///
    /// Uses Sender endpoint to emit `Match`es. A `Match` is emitted both on
    /// successful or failed matches.
    pub async fn refresh(&self, tx: mpsc::Sender<Refresh>, library_entries: Vec<LibraryEntry>) {
        let fut = stream::iter(
            library_entries
                .into_iter()
                .map(|library_entry| RefreshTask {
                    library_entry: library_entry,
                    igdb: Arc::clone(&self.igdb),
                    tx: tx.clone(),
                }),
        )
        .for_each_concurrent(IGDB_CONNECTIONS_LIMIT, refresh_task);

        fut.await;
        drop(tx);
    }

    /// Matches input `entries` with IGDB GameEntries.
    ///
    /// Uses Sender endpoint to emit `Match`es. A `Match` is emitted both on
    /// successful or failed matches.
    pub async fn reconcile(&self, tx: mpsc::Sender<Match>, store_entries: Vec<StoreEntry>) {
        let fut = stream::iter(store_entries.into_iter().map(|store_entry| MatchingTask {
            store_entry: store_entry,
            igdb: Arc::clone(&self.igdb),
            tx: tx.clone(),
        }))
        .for_each_concurrent(IGDB_CONNECTIONS_LIMIT, match_task);

        fut.await;
        drop(tx);
    }

    /// Returns IGDB GameEntry matching input `id`.
    pub async fn get_entry(&self, id: u64) -> Result<GameEntry, Status> {
        get_entry(&self.igdb, id).await
    }
}

const IGDB_CONNECTIONS_LIMIT: usize = 8;

/// Performs a single `RefreshTask` to producea `Refresh` and transmits it over
/// its task's channel.
async fn refresh_task(task: RefreshTask) {
    let entry_match = match get_entry(&task.igdb, task.library_entry.id).await {
        Ok(game_entry) => Refresh {
            library_entry: task.library_entry,
            game_entry: Some(game_entry),
        },
        Err(e) => {
            println!("Failed to resolve '{}': {}", task.library_entry.name, e);
            Refresh {
                library_entry: task.library_entry,
                game_entry: None,
            }
        }
    };

    if let Err(e) = task.tx.send(entry_match).await {
        eprintln!("{}", e);
    }
}

/// Performs a single `MatchingTask` to producea `Match` and transmits it over
/// its task's channel.
async fn match_task(task: MatchingTask) {
    let entry_match = match match_by_external_id(&task.igdb, &task.store_entry).await {
        Ok(game_entry) => match game_entry {
            Some(game_entry) => Match {
                store_entry: task.store_entry,
                game_entry: Some(game_entry),
            },
            None => match match_by_title(&task.igdb, &task.store_entry).await {
                Ok(game_entry) => Match {
                    store_entry: task.store_entry,
                    game_entry: game_entry,
                },
                Err(e) => {
                    println!("match_by_title '{}' failed: {}", task.store_entry.title, e);
                    Match {
                        store_entry: task.store_entry,
                        game_entry: None,
                    }
                }
            },
        },
        Err(e) => {
            println!(
                "match_by_external_id '{}' failed: {}",
                task.store_entry.title, e
            );
            Match {
                store_entry: task.store_entry,
                game_entry: None,
            }
        }
    };

    if let Err(e) = task.tx.send(entry_match).await {
        eprintln!("{}", e);
    }
}

/// Returns a `GameEntry` from IGDB matching the external storefront id in
/// `store_entry`.
async fn match_by_external_id(
    igdb: &IgdbApi,
    store_entry: &StoreEntry,
) -> Result<Option<GameEntry>, Status> {
    println!("Resolving '{}'", &store_entry.title);

    let igdb_external_game = igdb.match_external(store_entry).await?;
    match igdb_external_game {
        Some(external_game) => Ok(Some(get_entry(igdb, external_game.game.unwrap().id).await?)),
        None => Ok(None),
    }
}

/// Returns a `GameEntry` from IGDB matching the title in `store_entry`.
async fn match_by_title(
    igdb: &IgdbApi,
    store_entry: &StoreEntry,
) -> Result<Option<GameEntry>, Status> {
    println!("Searching '{}'", &store_entry.title);

    let candidates = search::get_candidates(igdb, &store_entry.title).await?;
    match candidates.into_iter().next() {
        Some(game_entry) => Ok(Some(get_entry(igdb, game_entry.id).await?)),
        None => Ok(None),
    }
}

/// Returns a `GameEntry` from IGDB that matches the input `id`.
async fn get_entry(igdb: &IgdbApi, id: u64) -> Result<GameEntry, Status> {
    let game_entry = igdb.get_game_by_id(id).await?;
    if let None = game_entry {
        return Err(Status::not_found(&format!(
            "Failed to retrieve game entry with id={}",
            id
        )));
    }

    let mut game_entry = game_entry.unwrap();
    igdb.retrieve_game_info(&mut game_entry).await?;

    Ok(convert(game_entry))
}

/// Converts an IGDB `Game` protobuf into a `GameEntry` document stored in
/// Firestore.
fn convert(igdb_game: igdb::Game) -> GameEntry {
    GameEntry {
        id: igdb_game.id,
        name: igdb_game.name,
        summary: igdb_game.summary,

        release_date: match igdb_game.first_release_date {
            Some(date) => Some(date.seconds),
            None => None,
        },

        collection: match igdb_game.collection {
            Some(collection) => Some(documents::Annotation {
                id: collection.id,
                name: collection.name,
            }),
            None => None,
        },

        franchises: igdb_game
            .franchises
            .into_iter()
            .map(|franchise| documents::Annotation {
                id: franchise.id,
                name: franchise.name,
            })
            .collect(),

        companies: igdb_game
            .involved_companies
            .into_iter()
            .filter_map(|involved_company| match involved_company.company {
                Some(company) => match company.name.is_empty() {
                    false => Some(documents::Annotation {
                        id: company.id,
                        name: company.name,
                    }),
                    true => None,
                },
                None => None,
            })
            .collect(),

        cover: match igdb_game.cover {
            Some(cover) => Some(documents::Image {
                image_id: cover.image_id,
                height: cover.height,
                width: cover.width,
            }),
            None => None,
        },

        screenshots: igdb_game
            .screenshots
            .into_iter()
            .map(|image| documents::Image {
                image_id: image.image_id,
                height: image.height,
                width: image.width,
            })
            .collect(),

        artwork: igdb_game
            .artworks
            .into_iter()
            .map(|image| documents::Image {
                image_id: image.image_id,
                height: image.height,
                width: image.width,
            })
            .collect(),
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
