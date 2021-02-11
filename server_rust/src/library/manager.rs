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

    // Async construction of LibraryManager.
    pub async fn new_async(user_id: &str) -> LibraryManager {
        let path = format!("target/{}.bin", user_id);
        let lib_future = tokio::spawn(async move {
            match LibraryManager::load(&path) {
                Ok(lib) => lib,
                Err(_) => {
                    eprintln!("Local library not found:'{}'", path);
                    Library {
                        ..Default::default()
                    }
                }
            }
        });

        LibraryManager {
            library: lib_future.await.unwrap(),
            user_id: String::from(user_id),
        }
    }

    /// Loads a proto message from file.
    fn load<T: Message + Default>(path: &str) -> Result<T, Box<dyn std::error::Error>> {
        let msg = Bytes::from(fs::read(path)?);
        Ok(T::decode(msg)?)
    }
}
