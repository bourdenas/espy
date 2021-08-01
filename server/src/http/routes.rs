use crate::api::{FirestoreApi, IgdbApi};
use crate::http::{handlers, models};
use crate::util;
use std::convert::Infallible;
use std::sync::{Arc, Mutex};
use warp::{self, Filter};

/// Returns a Filter with all available routes.
pub fn routes(
    keys: Arc<util::keys::Keys>,
    igdb: Arc<IgdbApi>,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    get_library()
        .or(get_settings(firestore.clone()))
        .or(post_settings(firestore.clone()))
        .or(post_sync(keys, firestore))
        .or(post_details())
        .or(post_match(igdb.clone()))
        .or(post_unmatch())
        .or(post_search(igdb))
        .or(get_images())
}

/// GET /library/{user_id}
fn get_library() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String)
        .and(warp::get())
        .and_then(handlers::get_library)
}

/// GET /library/{user_id}/settings
fn get_settings(
    firestore: Arc<Mutex<FirestoreApi>>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "settings")
        .and(warp::get())
        .and(with_firestore(firestore))
        .and_then(handlers::get_settings)
}

/// POST /library/{user_id}/settings
fn post_settings(
    firestore: Arc<Mutex<FirestoreApi>>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "settings")
        .and(warp::post())
        .and(settings_body())
        .and(with_firestore(firestore))
        .and_then(handlers::post_settings)
}

/// POST /library/{user_id}/sync
fn post_sync(
    keys: Arc<util::keys::Keys>,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "sync")
        .and(warp::post())
        .and(with_keys(keys))
        .and(with_firestore(firestore))
        .and_then(handlers::post_sync)
}

/// POST /library/{user_id}/details/{id}
fn post_details() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "details" / u64)
        .and(warp::post())
        .and(details_body())
        .and_then(handlers::post_details)
}

/// POST /library/{user_id}/match
fn post_match(
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "match")
        .and(warp::post())
        .and(match_body())
        .and(with_igdb(igdb))
        .and_then(handlers::post_match)
}

/// POST /library/{user_id}/unmatch
fn post_unmatch() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "unmatch")
        .and(warp::post())
        .and(match_body())
        .and_then(handlers::post_unmatch)
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

/// GET /images/{resolution}/{image_id}
fn get_images() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("images" / String / String)
        .and(warp::get())
        .and_then(handlers::get_images)
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

fn settings_body() -> impl Filter<Extract = (models::Settings,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(32 * 1024).and(warp::body::json())
}

fn details_body() -> impl Filter<Extract = (models::Details,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(32 * 1024).and(warp::body::json())
}

fn match_body() -> impl Filter<Extract = (models::Match,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}

fn search_body() -> impl Filter<Extract = (models::Search,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(16 * 1024).and(warp::body::json())
}
