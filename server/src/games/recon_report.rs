use serde::{Deserialize, Serialize};

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct ReconReport {
    pub lines: Vec<String>,
}
