use crate::{
    api::{FirestoreApi, IgdbApi},
    http::models,
    library::{self, Reconciler, User},
    util,
};
use std::{
    convert::Infallible,
    sync::{Arc, Mutex},
    time::SystemTime,
};
use tracing::{debug, error, instrument, warn};
use warp::http::StatusCode;

#[instrument(level = "trace", skip(api_keys, firestore, igdb))]
pub async fn post_sync(
    user_id: String,
    api_keys: Arc<util::keys::Keys>,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
) -> Result<impl warp::Reply, Infallible> {
    debug!("POST /library/{user_id}/sync");

    let mut user = match User::new(firestore, &user_id) {
        Ok(user) => user,
        Err(err) => {
            error!("{err}");
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    match user
        .sync(&api_keys, Reconciler::new(Arc::clone(&igdb)))
        .await
    {
        Ok(()) => Ok(StatusCode::OK),
        Err(err) => {
            error!("{err}");
            Ok(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

#[instrument(level = "trace", skip(igdb))]
pub async fn post_search(
    search: models::Search,
    igdb: Arc<IgdbApi>,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    debug!("POST /search");
    let started = SystemTime::now();

    let resp: Result<Box<dyn warp::Reply>, Infallible> =
        match library::search::get_candidates_with_covers(igdb, &search.title).await {
            Ok(candidates) => Ok(Box::new(warp::reply::json(&candidates))),
            Err(err) => {
                error!("{err}");
                Ok(Box::new(StatusCode::NOT_FOUND))
            }
        };

    let resp_time = SystemTime::now().duration_since(started).unwrap();
    debug!("time: {:.2} msec", resp_time.as_millis());
    resp
}

#[instrument(level = "trace", skip(igdb, firestore))]
pub async fn post_recon(
    user_id: String,
    recon: models::Recon,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
) -> Result<impl warp::Reply, Infallible> {
    debug!("POST /library/{user_id}/recon");

    let mgr = library::LibraryManager::new(&user_id, Arc::clone(&firestore));
    match mgr
        .manual_match(Reconciler::new(igdb), recon.store_entry, recon.game_entry)
        .await
    {
        Ok(()) => {
            let mut user = match User::new(firestore, &user_id) {
                Ok(user) => user,
                Err(err) => {
                    error!("{err}");
                    return Ok(StatusCode::INTERNAL_SERVER_ERROR);
                }
            };
            match user.update_library_version() {
                Ok(_) => Ok(StatusCode::OK),
                Err(err) => {
                    error!("{err}");
                    Ok(StatusCode::INTERNAL_SERVER_ERROR)
                }
            }
        }
        Err(err) => {
            error!("{err}");
            Ok(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

#[instrument(level = "trace", skip(upload, firestore, igdb))]
pub async fn post_upload(
    user_id: String,
    upload: models::Upload,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
) -> Result<impl warp::Reply, Infallible> {
    debug!("POST /upload");
    let started = SystemTime::now();

    let recon_service = Reconciler::new(igdb);
    let mgr = library::LibraryManager::new(&user_id, Arc::clone(&firestore));
    match mgr.recon_store_entries(upload.entries, recon_service).await {
        Ok(()) => (),
        Err(err) => {
            error!("{err}");
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    }

    let resp_time = SystemTime::now().duration_since(started).unwrap();
    debug!("time: {:.2} msec", resp_time.as_millis());
    Ok(StatusCode::OK)
}

pub async fn get_images(
    resolution: String,
    image: String,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    debug!("GET /images/{resolution}/{image}");

    let uri = format!("{IGDB_IMAGES_URL}/{resolution}/{image}");
    let resp = match reqwest::Client::new().get(&uri).send().await {
        Ok(resp) => resp,
        Err(err) => {
            warn! {"{err}"}
            return Ok(Box::new(StatusCode::NOT_FOUND));
        }
    };

    if resp.status() != StatusCode::OK {
        warn! {"Failed to retrieve image: {uri} \nerr: {}", resp.status()}
        return Ok(Box::new(resp.status()));
    }

    match resp.bytes().await {
        Ok(bytes) => Ok(Box::new(bytes.to_vec())),
        Err(_) => Ok(Box::new(StatusCode::NOT_FOUND)),
    }
}

pub async fn welcome() -> Result<Box<dyn warp::Reply>, Infallible> {
    debug!("GET /");
    Ok(Box::new("welcome"))
}

const IGDB_IMAGES_URL: &str = "https://images.igdb.com/igdb/image/upload";
