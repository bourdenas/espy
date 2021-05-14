use crate::igdb;
use crate::igdb_service;
use crate::Status;

/// Returns scored Candidates of igdb.Game entries that match the input title.
pub async fn get_candidates(
    igdb: &igdb_service::api::IgdbApi,
    title: &str,
) -> Result<Vec<Candidate>, Status> {
    let mut result = match igdb.search_by_title(title).await {
        Ok(r) => r,
        Err(e) => {
            println!("Failed to recon '{}': {}", title, e);
            igdb::GameResult::default()
        }
    };

    for game in &mut result.games {
        if let Some(cover) = &game.cover {
            if let Some(cover) = igdb.get_cover(cover.id).await? {
                game.cover = Some(Box::new(cover));
            }
        }
    }

    let mut candidates = result
        .games
        .into_iter()
        .map(|game| Candidate {
            score: edit_distance(title, &game.name),
            game: game,
        })
        .collect::<Vec<Candidate>>();
    candidates.sort_by(|a, b| a.score.cmp(&b.score));

    Ok(candidates)
}

// Internal struct that is only exposed for debug reasons (search by title) in
// the command line tool.
pub struct Candidate {
    pub game: igdb::Game,
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
