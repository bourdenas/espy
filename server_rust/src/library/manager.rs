use crate::espy::Library;
use prost::bytes::Bytes;
use prost::Message;
use std::fs;

#[derive(Debug)]
pub struct LibraryManager {
    pub library: Library,
    user_id: String,
}

impl LibraryManager {
    // Creates a LibraryManager instance for a unique user_id id.
    pub fn new(user_id: &str) -> LibraryManager {
        LibraryManager {
            library: match LibraryManager::load(&format!("target/{}.bin", user_id)) {
                Ok(lib) => lib,
                Err(_) => {
                    eprintln!("No local library found for user_id:'{}'", user_id);
                    Library {
                        ..Default::default()
                    }
                }
            },
            user_id: String::from(user_id),
        }
    }

    /// Loads a proto message from file.
    fn load<T: Message + Default>(path: &str) -> Result<T, Box<dyn std::error::Error>> {
        let msg = Bytes::from(fs::read(path)?);
        Ok(T::decode(msg)?)
    }
}
