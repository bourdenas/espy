use crate::espy;
use crate::igdb;
use crate::igdb_service;

pub struct Reconciler {
    igdb: igdb_service::api::IgdbApi,
}

impl Reconciler {
    pub fn new(igdb: igdb_service::api::IgdbApi) -> Reconciler {
        Reconciler { igdb }
    }

    // Retrieve data from IGDB for Steam entries and create a Library based on
    // IGDB info.
    pub async fn reconcile(
        &self,
        steam_entries: &Vec<espy::SteamEntry>,
    ) -> Result<espy::Library, Box<dyn std::error::Error + Send + Sync>> {
        let mut lib = espy::Library {
            ..Default::default()
        };

        for entry in steam_entries.iter() {
            match self.recon_entry(entry).await {
                Ok(game) => lib.entry.push(espy::GameEntry {
                    game: Some(game),
                    store_owned: vec![espy::game_entry::Store {
                        game_id: entry.id,
                        store_id: espy::game_entry::store::StoreId::Steam as i32,
                    }],
                }),
                Err(_) => lib.unreconciled_steam_game.push(entry.clone()),
            }
        }

        Ok(lib)
    }

    async fn recon_entry(
        &self,
        entry: &espy::SteamEntry,
    ) -> Result<igdb::Game, Box<dyn std::error::Error + Send + Sync>> {
        let result = match self.igdb.search_by_title(&entry.title).await {
            Ok(r) => r,
            Err(e) => {
                println!("Failed to recon '{}': {}", &entry.title, e);
                igdb::GameResult {
                    ..Default::default()
                }
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

        // TODO: Return Err if there are no candidates.
        let mut game = candidates.pop().unwrap().game;
        if let Some(cover) = game.cover {
            game.cover = Some(Box::new(self.igdb.get_cover(cover.id).await?));
        }
        if let Some(collection) = game.collection {
            game.collection = Some(self.igdb.get_collection(collection.id).await?);
        }
        if game.franchises.len() > 0 {
            game.franchises = self
                .igdb
                .get_franchises(&game.franchises.iter().map(|f| f.id).collect())
                .await?
                .franchises;
        }

        Ok(game)
    }
}

struct Candidate {
    game: igdb::Game,
    score: i32,
}

// Returns edit distance between two strings. It does not support UTF-8 strings.
fn edit_distance(a: &str, b: &str) -> i32 {
    let mut matrix: Vec<i32> = vec![0; (a.len() + 1) * (b.len() + 1)];
    let row_size = b.len() + 1;

    // Closure to translate 2d coordinates to a single-dimensional array.
    let xy = |x, y| x * row_size + y;

    for i in 1..(a.len() + 1) {
        matrix[xy(i, 0)] = i as i32;
    }
    for i in 1..(b.len() + 1) {
        matrix[xy(0, i)] = i as i32;
    }

    for i in 1..(a.len() + 1) {
        for j in 1..(b.len() + 1) {
            let cost = match a[(i - 1)..i] == b[(j - 1)..j] {
                true => 0,
                false => 1,
            };
            matrix[xy(i, j)] = std::cmp::min(
                std::cmp::min(matrix[xy(i - 1, j)] + 1, matrix[xy(i, j - 1)] + 1),
                matrix[xy(i - 1, j - 1)] + cost,
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
    #[should_panic(expected = "byte index 1 is not a char boundary; it is inside")]
    fn edit_distance_emoji() {
        assert_eq!(edit_distance("😊", ""), 4);
        assert_eq!(edit_distance("😊", "❤️"), 4);
    }
}
