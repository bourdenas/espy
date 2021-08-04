use crate::api::IgdbApi;
use crate::espy;
use crate::igdb;
use crate::models::{self, StoreEntry};
use crate::Status;
use futures::stream::{self, StreamExt};
use std::sync::Arc;
use tokio::sync::mpsc;

pub struct Reconciler {
    igdb: Arc<IgdbApi>,
}

pub struct Match {
    pub store_entry: StoreEntry,
    pub igdb_entry: Option<models::igdb::Entry>,
}

impl Reconciler {
    pub fn new(igdb: Arc<IgdbApi>) -> Reconciler {
        Reconciler { igdb }
    }

    /// Matches store entries with IGDB entries.
    pub async fn reconcile(&self, entries: Vec<StoreEntry>) -> Result<Vec<Match>, Status> {
        let (tx, mut rx) = mpsc::channel(32);

        let fut = stream::iter(entries.into_iter().map(|store_entry| Task {
            store_entry: store_entry,
            igdb: Arc::clone(&self.igdb),
            tx: tx.clone(),
        }))
        .for_each_concurrent(IGDB_CONNECTIONS_LIMIT, recon_task);

        let handle = tokio::spawn(async move {
            let mut matches = vec![];
            while let Some(entry_match) = rx.recv().await {
                matches.push(entry_match);
            }
            return matches;
        });

        fut.await;
        drop(tx);

        match handle.await {
            Ok(matches) => Ok(matches),
            Err(err) => Err(Status::internal("StoreEntry reconciliation failed", err)),
        }
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
        Ok(igdb_entry) => Match {
            store_entry: task.store_entry,
            igdb_entry,
        },
        Err(e) => {
            println!("Failed to resolve '{}': {}", task.store_entry.title, e);
            Match {
                store_entry: task.store_entry,
                igdb_entry: None,
            }
        }
    };

    if let Err(e) = task.tx.send(entry_match).await {
        eprintln!("{}", e);
    }
}

/// Returns a game entry from IGDB that matches the input store entry.
async fn resolve(
    igdb: &IgdbApi,
    store_entry: &StoreEntry,
) -> Result<Option<models::igdb::Entry>, Status> {
    println!("Resolving '{}'", &store_entry.title);

    let igdb_external_game = igdb.match_external(store_entry).await?;
    if let None = igdb_external_game {
        return Ok(None);
    }

    let igdb_entry = igdb
        .get_game_by_id(igdb_external_game.unwrap().game.unwrap().id)
        .await?;
    if let None = igdb_entry {
        return Ok(None);
    }

    let mut igdb_entry = igdb_entry.unwrap();
    igdb.retrieve_game_info(&mut igdb_entry).await?;

    Ok(Some(convert(igdb_entry)))
}

fn convert(igdb_game: igdb::Game) -> models::igdb::Entry {
    models::igdb::Entry {
        id: igdb_game.id,
        name: igdb_game.name,

        cover: match igdb_game.cover {
            Some(cover) => Some(models::igdb::Image {
                image_id: cover.image_id,
                height: cover.height,
                width: cover.width,
            }),
            None => None,
        },

        collection: match igdb_game.collection {
            Some(collection) => Some(models::igdb::Collection {
                id: collection.id,
                name: collection.name,
            }),
            None => None,
        },

        franchises: igdb_game
            .franchises
            .into_iter()
            .map(|franchise| models::igdb::Franchise {
                id: franchise.id,
                name: franchise.name,
            })
            .collect(),

        companies: igdb_game
            .involved_companies
            .into_iter()
            .map(|company| models::igdb::Company {
                id: company.id,
                name: match company.company {
                    Some(company) => company.name,
                    None => String::new(),
                },
            })
            .collect(),

        screenshots: igdb_game
            .screenshots
            .into_iter()
            .map(|image| models::igdb::Image {
                image_id: image.image_id,
                height: image.height,
                width: image.width,
            })
            .collect(),

        artwork: igdb_game
            .artworks
            .into_iter()
            .map(|image| models::igdb::Image {
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
