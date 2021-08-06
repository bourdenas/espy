use serde::{Deserialize, Serialize};

/// Document type the represents a generic game annotation, e.g. company,
/// collection, etc.
#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Annotation {
    pub id: u64,
    pub name: String,
}
