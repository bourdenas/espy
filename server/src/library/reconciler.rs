use crate::api::IgdbApi;
use crate::documents::{self, GameEntry, StoreEntry};
use crate::espy;
use crate::igdb;
use crate::Status;
use futures::stream::{self, StreamExt};
use std::sync::Arc;
use tokio::sync::mpsc;

pub struct Reconciler {
    igdb: Arc<IgdbApi>,
}

pub struct Match {
    pub store_entry: StoreEntry,
    pub game_entry: Option<GameEntry>,
}

impl Reconciler {
    pub fn new(igdb: Arc<IgdbApi>) -> Reconciler {
        Reconciler { igdb }
    }

    /// Matches store entries with IGDB entries.
    pub async fn reconcile(&self, tx: mpsc::Sender<Match>, entries: Vec<StoreEntry>) {
        let fut = stream::iter(entries.into_iter().map(|store_entry| Task {
            store_entry: store_entry,
            igdb: Arc::clone(&self.igdb),
            tx: tx.clone(),
        }))
        .for_each_concurrent(IGDB_CONNECTIONS_LIMIT, recon_task);

        fut.await;
        drop(tx);
    }

    pub async fn update_entry(&self, game_entry: &mut espy::GameEntry) -> Result<(), Status> {
        if let Some(game) = &mut game_entry.game {
            self.igdb.retrieve_game_info(game).await?;
        }
        Ok(())
    }
}

const IGDB_CONNECTIONS_LIMIT: usize = 8;

async fn recon_task(task: Task) {
    let entry_match = match resolve(&task.igdb, &task.store_entry).await {
        Ok(game_entry) => Match {
            store_entry: task.store_entry,
            game_entry,
        },
        Err(e) => {
            println!("Failed to resolve '{}': {}", task.store_entry.title, e);
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

/// Returns a game entry from IGDB that matches the input store entry.
async fn resolve(igdb: &IgdbApi, store_entry: &StoreEntry) -> Result<Option<GameEntry>, Status> {
    println!("Resolving '{}'", &store_entry.title);

    let igdb_external_game = igdb.match_external(store_entry).await?;
    if let None = igdb_external_game {
        return Ok(None);
    }

    let game_entry = igdb
        .get_game_by_id(igdb_external_game.unwrap().game.unwrap().id)
        .await?;
    if let None = game_entry {
        return Ok(None);
    }

    let mut game_entry = game_entry.unwrap();
    igdb.retrieve_game_info(&mut game_entry).await?;

    Ok(Some(convert(game_entry)))
}

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
            .map(|company| documents::Annotation {
                id: company.id,
                name: match company.company {
                    Some(company) => company.name,
                    None => String::new(),
                },
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

/// Reconciliation task structure.
struct Task {
    store_entry: StoreEntry,
    igdb: Arc<IgdbApi>,
    tx: mpsc::Sender<Match>,
}
