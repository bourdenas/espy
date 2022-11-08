use crate::api::{FirestoreApi, IgdbApi};
use crate::http::{handlers, models};
use crate::library::SteamDataApi;
use crate::util;
use std::convert::Infallible;
use std::sync::{Arc, Mutex};
use tracing::warn;
use warp::{self, Filter};

/// Returns a Filter with all available routes.
pub fn routes(
    keys: Arc<util::keys::Keys>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    home()
        .or(get_images())
        .or(post_sync(
            keys,
            Arc::clone(&firestore),
            Arc::clone(&igdb),
            Arc::clone(&steam),
        ))
        .or(post_upload(
            Arc::clone(&firestore),
            Arc::clone(&igdb),
            Arc::clone(&steam),
        ))
        .or(post_search(Arc::clone(&igdb)))
        .or(post_match(
            Arc::clone(&firestore),
            Arc::clone(&igdb),
            Arc::clone(&steam),
        ))
        .or(post_unmatch(Arc::clone(&firestore)))
        .or(post_rematch(firestore, igdb, steam))
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
    steam: Arc<SteamDataApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "sync")
        .and(warp::post())
        .and(with_keys(keys))
        .and(with_firestore(firestore))
        .and(with_igdb(igdb))
        .and(with_steam(steam))
        .and_then(handlers::post_sync)
}

/// POST /library/{user_id}/upload
fn post_upload(
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "upload")
        .and(warp::post())
        .and(upload_body())
        .and(with_firestore(firestore))
        .and(with_igdb(igdb))
        .and(with_steam(steam))
        .and_then(handlers::post_upload)
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

/// POST /library/{user_id}/match
fn post_match(
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "match")
        .and(warp::post())
        .and(match_body())
        .and(with_firestore(firestore))
        .and(with_igdb(igdb))
        .and(with_steam(steam))
        .and_then(handlers::post_match)
}

/// POST /library/{user_id}/unmatch
fn post_unmatch(
    firestore: Arc<Mutex<FirestoreApi>>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "unmatch")
        .and(warp::post())
        .and(unmatch_body())
        .and(with_firestore(firestore))
        .and_then(handlers::post_unmatch)
}

/// POST /library/{user_id}/rematch
fn post_rematch(
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "rematch")
        .and(warp::post())
        .and(rematch_body())
        .and(with_firestore(firestore))
        .and(with_igdb(igdb))
        .and(with_steam(steam))
        .and_then(handlers::post_rematch)
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

fn with_steam(
    steam: Arc<SteamDataApi>,
) -> impl Filter<Extract = (Arc<SteamDataApi>,), Error = Infallible> + Clone {
    warp::any().map(move || Arc::clone(&steam))
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

fn upload_body() -> impl Filter<Extract = (models::Upload,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}

fn search_body() -> impl Filter<Extract = (models::Search,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(16 * 1024).and(warp::body::json())
}

fn match_body() -> impl Filter<Extract = (models::Match,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}

fn unmatch_body() -> impl Filter<Extract = (models::Unmatch,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}

fn rematch_body() -> impl Filter<Extract = (models::Rematch,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}
