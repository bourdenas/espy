use crate::espy;
use crate::igdb_service;
use crate::library;
use crate::recon;
use crate::steam;
use crate::util;
use std::sync::Arc;

/// Implementation of espy.Espy API.
pub struct EspyImpl {
    keys: util::keys::Keys,
    igdb: Arc<igdb_service::api::IgdbApi>,
}

impl EspyImpl {
    pub async fn build(
        keys: util::keys::Keys,
    ) -> Result<EspyImpl, Box<dyn std::error::Error + Send + Sync>> {
        let mut igdb = igdb_service::api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
        igdb.connect().await?;

        Ok(EspyImpl {
            keys,
            igdb: Arc::new(igdb),
        })
    }
}

#[tonic::async_trait]
impl espy::espy_server::Espy for EspyImpl {
    async fn get_library(
        &self,
        request: tonic::Request<espy::LibraryRequest>,
    ) -> Result<tonic::Response<espy::LibraryResponse>, tonic::Status> {
        println!("Espy.GetLibrary request: {:?}", request.get_ref());

        let mut mgr = library::manager::LibraryManager::new(
            &request.get_ref().user_id,
            recon::reconciler::Reconciler::new(Arc::clone(&self.igdb)),
        );
        match mgr
            .build(
                Some(steam::api::SteamApi::new(
                    &self.keys.steam.client_key,
                    &self.keys.steam.user_id,
                )),
                None,
            )
            .await
        {
            Ok(_) => Ok(tonic::Response::new(espy::LibraryResponse {
                library: Some(mgr.library),
            })),
            Err(e) => {
                println!("Internal Error: {}", e);
                Err(tonic::Status::internal("Failed to build user library."))
            }
        }
    }
}
