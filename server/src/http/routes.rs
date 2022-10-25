use crate::api::{FirestoreApi, IgdbApi};
use crate::http::{handlers, models};
use crate::util;
use std::convert::Infallible;
use std::sync::{Arc, Mutex};
use tracing::warn;
use warp::{self, Filter};

/// Returns a Filter with all available routes.
pub fn routes(
    keys: Arc<util::keys::Keys>,
    igdb: Arc<IgdbApi>,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    home()
        .or(get_images())
        .or(post_sync(keys, Arc::clone(&firestore), Arc::clone(&igdb)))
        .or(post_search(Arc::clone(&igdb)))
        .or(post_recon(Arc::clone(&firestore), Arc::clone(&igdb)))
        .or(post_upload(firestore, igdb))
        .or_else(|e| async {
            warn! {"Rejected route: {:?}", e};
            Err(e)
        })
}

/// POST /library/{user_id}/sync
fn post_sync(
    keys: Arc<util::keys::Keys>,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "sync")
        .and(warp::post())
        .and(with_keys(keys))
        .and(with_firestore(firestore))
        .and(with_igdb(igdb))
        .and_then(handlers::post_sync)
}

/// POST /match/search
fn post_search(
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("search")
        .and(warp::post())
        .and(search_body())
        .and(with_igdb(igdb))
        .and_then(handlers::post_search)
}

/// POST /library/{user_id}/recon
fn post_recon(
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "recon")
        .and(warp::post())
        .and(recon_body())
        .and(with_firestore(firestore))
        .and(with_igdb(igdb))
        .and_then(handlers::post_recon)
}

/// POST /library/{user_id}/upload
fn post_upload(
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "upload")
        .and(warp::post())
        .and(upload_body())
        .and(with_firestore(firestore))
        .and(with_igdb(igdb))
        .and_then(handlers::post_upload)
}

/// GET /images/{resolution}/{image_id}
fn get_images() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("images" / String / String)
        .and(warp::get())
        .and_then(handlers::get_images)
}

/// GET /
fn home() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!().and(warp::get()).and_then(handlers::welcome)
}

fn with_igdb(
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = (Arc<IgdbApi>,), Error = Infallible> + Clone {
    warp::any().map(move || Arc::clone(&igdb))
}

fn with_firestore(
    firestore: Arc<Mutex<FirestoreApi>>,
) -> impl Filter<Extract = (Arc<Mutex<FirestoreApi>>,), Error = Infallible> + Clone {
    warp::any().map(move || Arc::clone(&firestore))
}

fn with_keys(
    keys: Arc<util::keys::Keys>,
) -> impl Filter<Extract = (Arc<util::keys::Keys>,), Error = Infallible> + Clone {
    warp::any().map(move || Arc::clone(&keys))
}

fn search_body() -> impl Filter<Extract = (models::Search,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(16 * 1024).and(warp::body::json())
}

fn recon_body() -> impl Filter<Extract = (models::Recon,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}

fn upload_body() -> impl Filter<Extract = (models::Upload,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}
