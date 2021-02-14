use crate::espy;
use crate::recon;
use crate::steam;
use crate::util;

pub struct LibraryManager {
    pub library: espy::Library,
    user_id: String,
    steam_api: Option<steam::api::SteamApi>,
    recon_service: Option<recon::reconciler::Reconciler>,
}

impl LibraryManager {
    // Creates a LibraryManager instance for a unique user_id id.
    pub fn new(user_id: &str) -> LibraryManager {
        LibraryManager {
            library: espy::Library {
                ..Default::default()
            },
            user_id: String::from(user_id),
            steam_api: None,
            recon_service: None,
        }
    }

    // Build LibraryManager from local stored library if available and by
    // syncing external storefronts.
    pub async fn build(
        &mut self,
        steam_api: steam::api::SteamApi,
        recon_service: recon::reconciler::Reconciler,
    ) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        self.steam_api = Some(steam_api);
        self.recon_service = Some(recon_service);

        let path = format!("target/{}.bin", self.user_id);
        let lib_future = tokio::spawn(async move {
            match util::proto::load(&path) {
                Ok(lib) => lib,
                Err(_) => {
                    eprintln!("Local library not found:'{}'", path);
                    espy::Library {
                        ..Default::default()
                    }
                }
            }
        });

        self.library = lib_future.await.unwrap();
        Ok(())
    }
}
