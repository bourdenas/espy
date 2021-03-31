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
    match mgr.build(None, None).await {
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
    if let Err(_) = mgr.build(None, None).await {
        return Ok(StatusCode::NOT_FOUND);
    }

    let mut entry = mgr.library.entry.iter_mut().find(|e| match &e.game {
        Some(game) => game.id == game_id,
        None => false,
    });

    if let Some(entry) = &mut entry {
        entry.details = Some(espy::GameDetails { tag: details.tags });
    }
    match mgr.save().await {
        Ok(_) => Ok(StatusCode::OK),
        Err(_) => Ok(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

pub async fn get_images(
    resolution: String,
    image: String,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    println!("/images/{}/{}", &resolution, &image);

    let uri = format!("{}/{}/{}", IGDB_IMAGES_URL, &resolution, &image);
    let resp = match reqwest::Client::new().get(&uri).send().await {
        Ok(resp) => resp,
        Err(e) => {
            eprintln!("Remote GET failed! {}", e);
            return Ok(Box::new(StatusCode::NOT_FOUND));
        }
    };

    if resp.status() != StatusCode::OK {
        eprintln!(
            "Failed to retrieve image: {} \nerr: {}",
            &uri,
            resp.status()
        );
        return Ok(Box::new(resp.status()));
    }

    match resp.bytes().await {
        Ok(bytes) => Ok(Box::new(bytes.to_vec())),
        Err(_) => Ok(Box::new(StatusCode::NOT_FOUND)),
    }
}

const IGDB_IMAGES_URL: &str = "https://images.igdb.com/igdb/image/upload";
