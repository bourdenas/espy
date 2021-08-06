use crate::api::IgdbApi;
use crate::espy;
use crate::util;
use crate::Status;
use std::sync::Arc;

/// Implementation of espy.Espy API.
pub struct EspyImpl {
    _keys: util::keys::Keys,
    _igdb: Arc<IgdbApi>,
}

impl EspyImpl {
    pub async fn build(keys: util::keys::Keys) -> Result<EspyImpl, Status> {
        let mut igdb = IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
        igdb.connect().await?;

        Ok(EspyImpl {
            _keys: keys,
            _igdb: Arc::new(igdb),
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

        let library = espy::Library::default();
        Ok(tonic::Response::new(espy::LibraryResponse {
            library: Some(library),
        }))
    }
}
