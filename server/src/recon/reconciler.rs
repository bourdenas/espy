use crate::espy;
use crate::igdb;
use crate::igdb_service;
use futures::future;
use std::sync::Arc;

pub struct Reconciler {
    igdb: Arc<igdb_service::api::IgdbApi>,
}

impl Reconciler {
    pub fn new(igdb: Arc<igdb_service::api::IgdbApi>) -> Reconciler {
        Reconciler { igdb }
    }

    // Retrieve data from IGDB for Steam entries and create a Library based on
    // IGDB info.
    pub async fn reconcile(
        &self,
        steam_entries: &[espy::SteamEntry],
    ) -> Result<espy::Library, Box<dyn std::error::Error + Send + Sync>> {
        let handles = steam_entries.iter().map(|entry| {
            let igdb = Arc::clone(&self.igdb);
            let entry = entry.clone();
            tokio::spawn(async move {
                match recon(&igdb, &entry).await {
                    Ok(game) => match game {
                        Some(game) => Ok(espy::GameEntry {
                            game: Some(game),
                            store_owned: vec![espy::game_entry::Store {
                                game_id: entry.id,
                                store_id: espy::game_entry::store::StoreId::Steam as i32,
                            }],
                        }),
                        None => Err(entry),
                    },
                    Err(_) => {
                        println!("failed recon request '{}'", entry.title);
                        Err(entry)
                    }
                }
            })
        });
        // TODO: This currently does not respect IGDB's free-tier 4 QPS and
        // floods with errors for large slices.
        let results = future::join_all(handles).await;

        let mut lib = espy::Library::default();
        for result in results {
            let result = result?;
            match result {
                Ok(game) => lib.entry.push(game),
                Err(entry) => lib.unreconciled_steam_game.push(entry),
            };
        }

        Ok(lib)
    }
}

/// Returns a Game entry from IGDB that matches the input Steam entry.
async fn recon(
    igdb: &igdb_service::api::IgdbApi,
    entry: &espy::SteamEntry,
) -> Result<Option<igdb::Game>, Box<dyn std::error::Error + Send + Sync>> {
    let result = match igdb.search_by_title(&entry.title).await {
        Ok(r) => r,
        Err(e) => {
            println!("Failed to recon '{}': {}", &entry.title, e);
            igdb::GameResult::default()
        }
    };

    let mut candidates = result
        .games
        .into_iter()
        .map(|e| Candidate {
            score: edit_distance(&entry.title, &e.name),
            game: e,
        })
        .collect::<Vec<Candidate>>();
    candidates.sort_by(|a, b| a.score.cmp(&b.score));

    if candidates.len() == 0 {
        return Ok(None);
    }

    let mut game = candidates.pop().unwrap().game;
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

    Ok(Some(game))
}

struct Candidate {
    game: igdb::Game,
    score: i32,
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
