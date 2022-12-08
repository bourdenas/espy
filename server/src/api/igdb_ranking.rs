use crate::documents::GameEntry;

/// Sorts GameEntries by title relevance in descending order.
pub fn sorted_by_relevance(title: &str, igdb_games: Vec<GameEntry>) -> Vec<GameEntry> {
    let mut candidates = igdb_games
        .into_iter()
        .map(|game_entry| Candidate {
            score: edit_distance(title, &game_entry.name),
            game_entry,
        })
        .collect::<Vec<_>>();
    candidates.sort_by(|a, b| a.score.total_cmp(&b.score));

    candidates
        .into_iter()
        .map(|candidate| candidate.game_entry)
        .collect()
}

// Internal struct that is only exposed for debug reasons (search by title) in
// the command line tool.
#[derive(Debug)]
struct Candidate {
    game_entry: GameEntry,
    score: f64,
}

impl std::fmt::Display for Candidate {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{} ({})", self.game_entry.name, self.score)
    }
}

// Returns edit distance between two strings.
fn edit_distance(a: &str, b: &str) -> f64 {
    let a_len = a.chars().count();
    let b_len = b.chars().count();

    if a_len == 0 {
        return b_len as f64;
    } else if b_len == 0 {
        return a_len as f64;
    }

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

    *matrix.last().unwrap() as f64 / std::cmp::max(a_len, b_len) as f64
}

#[cfg(test)]
mod tests {
    use super::*;

    macro_rules! assert_delta {
        ($x:expr, $y:expr, $d:expr) => {
            if !(($x - $y).abs() < $d || ($y - $x).abs() < $d) {
                panic!(
                    "{} is not equal to {} with an error margin of {}",
                    $x, $y, $d
                );
            }
        };
    }

    #[test]
    fn edit_distance_equal() {
        assert_eq!(edit_distance("hello", "hello"), 0.0);
        assert_eq!(edit_distance("hello there", "hello there"), 0.0);
    }

    #[test]
    fn edit_distance_diff() {
        assert_eq!(edit_distance("hello", "hallo"), 0.2);
        assert_delta!(edit_distance("go", "got"), 0.33, 0.004);
        assert_delta!(edit_distance("hello there", "hello world"), 0.45, 0.005);
    }

    #[test]
    fn edit_distance_empty() {
        assert_eq!(edit_distance("", ""), 0.0);
        assert_eq!(edit_distance("hello", ""), 5.0);
        assert_eq!(edit_distance("", "hello"), 5.0);
    }

    #[test]
    fn edit_distance_emoji() {
        assert_eq!(edit_distance("😊", ""), 1.0);
        assert_eq!(edit_distance("😊", "😊😊"), 0.5);
        assert_delta!(edit_distance("😊🦀", "🦀😊🦀"), 0.33, 0.004);
        assert_eq!(edit_distance("😊🦀", "😊🦀"), 0.0);
    }
}
