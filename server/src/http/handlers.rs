use crate::espy;
use crate::http::models;
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

    // Pass None for Steam API to avoid retrieving entries and reconciling on
    // every get_library request.
    let mut mgr = LibraryManager::new(&user_id, Reconciler::new(Arc::clone(&igdb)));
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

pub async fn post_details(
    user_id: String,
    game_id: u64,
    details: models::Details,
    igdb: Arc<IgdbApi>,
) -> Result<impl warp::Reply, Infallible> {
    println!(
        "/library/{}/details/{} body: {:?}",
        &user_id, game_id, &details
    );

    let mut mgr = LibraryManager::new(&user_id, Reconciler::new(Arc::clone(&igdb)));
    if let Err(_) = mgr.build(None).await {
        return Ok(Box::new(StatusCode::NOT_FOUND));
    }

    let mut entry = mgr.library.entry.iter_mut().find(|e| match &e.game {
        Some(game) => game.id == game_id,
        None => false,
    });

    if let Some(entry) = &mut entry {
        entry.details = Some(espy::GameDetails { tag: details.tags });
    }
    match mgr.save().await {
        Ok(_) => Ok(Box::new(StatusCode::OK)),
        Err(_) => Ok(Box::new(StatusCode::INTERNAL_SERVER_ERROR)),
    }
}
