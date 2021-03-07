use crate::igdb_service::api::IgdbApi;
use crate::library::manager::LibraryManager;
use crate::recon::reconciler::Reconciler;
use prost::Message;
use std::convert::Infallible;
use std::sync::Arc;
use warp::http::StatusCode;

pub async fn get_library(
    user_id: String,
    igdb: Arc<IgdbApi>,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    println!("/library/{}", &user_id);
    let mut mgr = LibraryManager::new(&user_id, Reconciler::new(Arc::clone(&igdb)));

    // Pass None for Steam API to avoid retrieving entries and reconciling on
    // every get_library request.
    match mgr.build(None).await {
        Ok(_) => {
            let mut bytes = vec![];
            match mgr.library.encode(&mut bytes) {
                Ok(_) => Ok(Box::new(bytes)),
                Err(_) => Ok(Box::new(StatusCode::NOT_FOUND)),
            }
        }
        Err(_) => Ok(Box::new(StatusCode::NOT_FOUND)),
    }
}
