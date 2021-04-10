use crate::espy;
use crate::igdb_service;
use futures::stream::{self, StreamExt};
use std::sync::Arc;
use tokio::sync::mpsc;

pub struct Reconciler {
    igdb: Arc<igdb_service::api::IgdbApi>,
}

impl Reconciler {
    pub fn new(igdb: Arc<igdb_service::api::IgdbApi>) -> Reconciler {
        Reconciler { igdb }
    }

    // Retrieve data from IGDB for store entries and create a Library based on
    // IGDB info.
    pub async fn reconcile(
        &self,
        entries: &[espy::StoreEntry],
    ) -> Result<espy::Library, Box<dyn std::error::Error + Send + Sync>> {
        let (tx, mut rx) = mpsc::channel(32);

        let fut = stream::iter(entries.iter().map(|store_entry| Task {
            store_entry: store_entry.clone(),
            igdb: Arc::clone(&self.igdb),
            tx: tx.clone(),
        }))
        .for_each_concurrent(IGDB_CONNECTIONS_LIMIT, recon_task);

        let handle = tokio::spawn(async move {
            let mut lib = espy::Library::default();
            while let Some(game_entry) = rx.recv().await {
                lib.entry.push(game_entry)
            }
            return lib;
        });

        fut.await;
        drop(tx);

        Ok(handle.await?)
    }
}

const IGDB_CONNECTIONS_LIMIT: usize = 8;

async fn recon_task(task: Task) {
    let game_entry = match resolve(&task.igdb, task.store_entry.clone()).await {
        Ok(game_entry) => game_entry,
        Err(e) => {
            println!("Failed to resolve '{}': {}", task.store_entry.title, e);
            espy::GameEntry {
                game: None,
                store_entry: vec![task.store_entry],
                ..Default::default()
            }
        }
    };

    if let Err(e) = task.tx.send(game_entry).await {
        eprintln!("{}", e);
    }
}

/// Returns a game entry from IGDB that matches the input store entry.
async fn resolve(
    igdb: &igdb_service::api::IgdbApi,
    store_entry: espy::StoreEntry,
) -> Result<espy::GameEntry, Box<dyn std::error::Error + Send + Sync>> {
    println!("Resolving '{}'", &store_entry.title);

    let mut game_entry = espy::GameEntry {
        game: None,
        store_entry: vec![store_entry],
        ..Default::default()
    };

    let external_game = igdb.match_external(&game_entry.store_entry[0]).await?;
    if let None = external_game {
        return Ok(game_entry);
    }

    let game = igdb
        .get_game_by_id(external_game.unwrap().game.unwrap().id)
        .await?;
    if let None = game {
        return Ok(game_entry);
    }
    let mut game = game.unwrap();

    if let Some(cover) = &game.cover {
        if let Some(cover) = igdb.get_cover(cover.id).await? {
            game.cover = Some(Box::new(cover));
        }
    }
    if let Some(collection) = game.collection {
        game.collection = igdb.get_collection(collection.id).await?;
    }
    if game.franchises.len() > 0 {
        game.franchises = igdb
            .get_franchises(&game.franchises.iter().map(|f| f.id).collect::<Vec<_>>())
            .await?
            .franchises;
    }
    if game.involved_companies.len() > 0 {
        game.involved_companies = igdb
            .get_companies(
                &game
                    .involved_companies
                    .iter()
                    .map(|f| f.id)
                    .collect::<Vec<_>>(),
            )
            .await?
            .involvedcompanies;
    }
    if game.artworks.len() > 0 {
        game.artworks = igdb
            .get_artwork(&game.artworks.iter().map(|f| f.id).collect::<Vec<_>>())
            .await?
            .artworks;
    }
    if game.screenshots.len() > 0 {
        game.screenshots = igdb
            .get_screenshots(&game.screenshots.iter().map(|f| f.id).collect::<Vec<_>>())
            .await?
            .screenshots;
    }

    game_entry.game = Some(game);
    Ok(game_entry)
}

struct Task {
    store_entry: espy::StoreEntry,
    igdb: Arc<igdb_service::api::IgdbApi>,
    tx: mpsc::Sender<espy::GameEntry>,
}
