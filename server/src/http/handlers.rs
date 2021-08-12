use crate::api::{FirestoreApi, IgdbApi};
use crate::http::models;
use crate::igdb;
use crate::library;
use crate::library::{Reconciler, User};
use crate::util;
use prost::Message;
use std::convert::Infallible;
use std::sync::{Arc, Mutex};
use warp::http::StatusCode;

pub async fn post_sync(
    user_id: String,
    keys: Arc<util::keys::Keys>,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> Result<impl warp::Reply, Infallible> {
    println!("POST /library/{}/sync", &user_id);

    let mut user = match User::new(firestore, &user_id) {
        Ok(user) => user,
        Err(e) => {
            eprintln!("POST /library/{}/settings: {}", &user_id, e);
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    match user.sync(&keys).await {
        Ok(()) => Ok(StatusCode::OK),
        Err(err) => {
            eprintln!("{}", err);
            Ok(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

pub async fn post_recon(
    user_id: String,
    recon: models::Recon,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
) -> Result<impl warp::Reply, Infallible> {
    println!("POST /library/{}/recon", &user_id);

    let mgr = library::LibraryManager::new(&user_id, firestore);
    match mgr
        .manual_recon(Reconciler::new(igdb), recon.store_entry, recon.game_entry)
        .await
    {
        Ok(()) => Ok(StatusCode::OK),
        Err(err) => {
            eprintln!("{}", err);
            Ok(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

#[deprecated(note = "TBR by direct client calls to Firestore.")]
pub async fn post_unmatch(
    user_id: String,
    recon: models::Recon,
) -> Result<impl warp::Reply, Infallible> {
    println!("[deprecated] POST /library/{}/unmatch", &user_id);

    Ok(StatusCode::OK)
}

pub async fn post_search(
    search: models::Search,
    igdb: Arc<IgdbApi>,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    println!("POST /search body: {:?}", &search);

    let candidates = match library::search::get_candidates(&igdb, &search.title).await {
        Ok(result) => result,
        Err(_) => return Ok(Box::new(StatusCode::NOT_FOUND)),
    };

    let result = igdb::GameResult {
        games: candidates.into_iter().map(|c| c.game).collect(),
    };

    let mut bytes = vec![];
    match result.encode(&mut bytes) {
        Ok(_) => Ok(Box::new(bytes)),
        Err(_) => Ok(Box::new(StatusCode::NOT_FOUND)),
    }
}

pub async fn get_images(
    resolution: String,
    image: String,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    println!("GET /images/{}/{}", &resolution, &image);

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
