use crate::api::{FirestoreApi, IgdbApi};
use crate::http::models;
use crate::library::{self, Reconciler, User};
use crate::util;
use std::{
    convert::Infallible,
    sync::{Arc, Mutex},
    time::SystemTime,
};
use tracing::{info, instrument};
use warp::http::StatusCode;

#[instrument(level = "info", skip(keys, firestore))]
pub async fn post_sync(
    user_id: String,
    keys: Arc<util::keys::Keys>,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> Result<impl warp::Reply, Infallible> {
    println!("POST /library/{user_id}/sync");

    let mut user = match User::new(firestore, &user_id) {
        Ok(user) => user,
        Err(err) => {
            eprintln!("{err}");
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    match user.sync(&keys, None).await {
        Ok(()) => Ok(StatusCode::OK),
        Err(err) => {
            eprintln!("{err}");
            Ok(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

#[instrument(level = "info", skip(igdb, firestore))]
pub async fn post_recon(
    user_id: String,
    recon: models::Recon,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
) -> Result<impl warp::Reply, Infallible> {
    println!("POST /library/{user_id}/recon");

    let mgr = library::LibraryManager::new(&user_id, Arc::clone(&firestore));
    match mgr
        .manual_match(Reconciler::new(igdb), recon.store_entry, recon.game_entry)
        .await
    {
        Ok(()) => {
            let mut user = match User::new(firestore, &user_id) {
                Ok(user) => user,
                Err(err) => {
                    eprintln!("{err}");
                    return Ok(StatusCode::INTERNAL_SERVER_ERROR);
                }
            };
            match user.update_version() {
                Ok(_) => Ok(StatusCode::OK),
                Err(err) => {
                    eprintln!("{err}");
                    Ok(StatusCode::INTERNAL_SERVER_ERROR)
                }
            }
        }
        Err(err) => {
            eprintln!("{err}");
            Ok(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

#[instrument(level = "info", skip(igdb))]
pub async fn post_search(
    search: models::Search,
    igdb: Arc<IgdbApi>,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    info! {
        "POST /search"
    }
    let started = SystemTime::now();

    let resp: Result<Box<dyn warp::Reply>, Infallible> =
        match library::search::get_candidates(&igdb, &search.title).await {
            Ok(candidates) => Ok(Box::new(warp::reply::json(&candidates))),
            Err(err) => {
                eprintln!("{err}");
                Ok(Box::new(StatusCode::NOT_FOUND))
            }
        };

    let resp_time = SystemTime::now().duration_since(started).unwrap();
    info! {
        "  time: {:.2} msec", resp_time.as_millis()
    }

    resp
}

pub async fn get_images(
    resolution: String,
    image: String,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    println!("GET /images/{resolution}/{image}");

    let uri = format!("{IGDB_IMAGES_URL}/{resolution}/{image}");
    let resp = match reqwest::Client::new().get(&uri).send().await {
        Ok(resp) => resp,
        Err(err) => {
            eprintln!("{err}");
            return Ok(Box::new(StatusCode::NOT_FOUND));
        }
    };

    if resp.status() != StatusCode::OK {
        eprintln!("Failed to retrieve image: {uri} \nerr: {}", resp.status());
        return Ok(Box::new(resp.status()));
    }

    match resp.bytes().await {
        Ok(bytes) => Ok(Box::new(bytes.to_vec())),
        Err(_) => Ok(Box::new(StatusCode::NOT_FOUND)),
    }
}

pub async fn welcome() -> Result<Box<dyn warp::Reply>, Infallible> {
    println!("GET /");
    Ok(Box::new("welcome"))
}

const IGDB_IMAGES_URL: &str = "https://images.igdb.com/igdb/image/upload";
