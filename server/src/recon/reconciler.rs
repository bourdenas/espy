use crate::espy;
use crate::igdb;
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

        let fut = stream::iter(entries.iter().map(|entry| Task {
            entry: entry.clone(),
            igdb: Arc::clone(&self.igdb),
            tx: tx.clone(),
        }))
        .for_each_concurrent(8, |task| async move {
            let resp = match recon(&task.igdb, &task.entry).await {
                Ok(game) => match game {
                    Some(game) => Ok(espy::GameEntry {
                        game: Some(game),
                        steam_entry: Some(task.entry),
                        ..Default::default()
                    }),
                    None => Err(task.entry),
                },
                Err(_) => {
                    println!("failed recon request '{}'", task.entry.title);
                    Err(task.entry)
                }
            };

            if let Err(e) = task.tx.send(resp).await {
                println!("{:?}", e);
            }
        });

        let handle = tokio::spawn(async move {
            let mut lib = espy::Library::default();
            while let Some(resp) = rx.recv().await {
                match resp {
                    Ok(game) => lib.entry.push(game),
                    Err(entry) => lib.unreconciled_steam_game.push(entry),
                };
            }
            return lib;
        });

        fut.await;
        drop(tx);

        Ok(handle.await?)
    }
}

/// Returns scored Candidates of igdb.Game entries that match the input title.
pub async fn get_candidates(
    igdb: &igdb_service::api::IgdbApi,
    title: &str,
) -> Result<Vec<Candidate>, Box<dyn std::error::Error + Send + Sync>> {
    let result = match igdb.search_by_title(title).await {
        Ok(r) => r,
        Err(e) => {
            println!("Failed to recon '{}': {}", title, e);
            igdb::GameResult::default()
        }
    };

    let mut candidates = result
        .games
        .into_iter()
        .map(|e| Candidate {
            score: edit_distance(title, &e.name),
            game: e,
        })
        .collect::<Vec<Candidate>>();
    candidates.sort_by(|a, b| a.score.cmp(&b.score));

    Ok(candidates)
}

struct Task {
    entry: espy::StoreEntry,
    igdb: Arc<igdb_service::api::IgdbApi>,
    tx: mpsc::Sender<Result<espy::GameEntry, espy::StoreEntry>>,
}

/// Returns a Game entry from IGDB that matches the input Steam entry.
async fn recon(
    igdb: &igdb_service::api::IgdbApi,
    entry: &espy::StoreEntry,
) -> Result<Option<igdb::Game>, Box<dyn std::error::Error + Send + Sync>> {
    println!("Resolving '{}'", &entry.title);
    let candidates = get_candidates(igdb, &entry.title).await?;
    if candidates.len() == 0 {
        return Ok(None);
    }

    let mut game = candidates[0].game.clone();
    if let Some(cover) = game.cover {
        game.cover = match igdb.get_cover(cover.id).await? {
            Some(cover) => Some(Box::new(cover)),
            None => None,
        };
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

    Ok(Some(game))
}

// Internal struct that is only exposed for debug reasons (search by title) in
// the command line tool.
pub struct Candidate {
    game: igdb::Game,
    score: i32,
}

impl std::fmt::Display for Candidate {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{} ({})", self.game.name, self.score)
    }
}

// Returns edit distance between two strings.
fn edit_distance(a: &str, b: &str) -> i32 {
    let a_len = a.chars().count();
    let b_len = b.chars().count();

    let mut matrix: Vec<i32> = vec![0; (a_len + 1) * (b_len + 1)];
    let row_size = b_len + 1;

    // Closure to translate 2d coordinates to a single-dimensional array.
    let xy = |x, y| x * row_size + y;

    for i in 1..(a_len + 1) {
        matrix[xy(i, 0)] = i as i32;
    }
    for i in 1..(b_len + 1) {
        matrix[xy(0, i)] = i as i32;
    }

    for (i, a) in a.chars().enumerate() {
        for (j, b) in b.chars().enumerate() {
            let cost = match a == b {
                true => 0,
                false => 1,
            };
            matrix[xy(i + 1, j + 1)] = std::cmp::min(
                std::cmp::min(matrix[xy(i, j + 1)] + 1, matrix[xy(i + 1, j)] + 1),
                matrix[xy(i, j)] + cost,
            );
        }
    }

    *matrix.last().unwrap()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn edit_distance_equal() {
        assert_eq!(edit_distance("hello", "hello"), 0);
        assert_eq!(edit_distance("hello there", "hello there"), 0);
    }

    #[test]
    fn edit_distance_diff() {
        assert_eq!(edit_distance("hello", "hallo"), 1);
        assert_eq!(edit_distance("go", "got"), 1);
        assert_eq!(edit_distance("hello there", "hello world"), 5);
    }

    #[test]
    fn edit_distance_empty() {
        assert_eq!(edit_distance("", ""), 0);
        assert_eq!(edit_distance("hello", ""), 5);
        assert_eq!(edit_distance("", "hello"), 5);
    }

    #[test]
    fn edit_distance_emoji() {
        assert_eq!(edit_distance("😊", ""), 1);
        assert_eq!(edit_distance("😊", "😊😊"), 1);
        assert_eq!(edit_distance("😊❤️", "❤️😊❤️"), 2);
        assert_eq!(edit_distance("😊❤️", "😊❤️"), 0);
    }
}
