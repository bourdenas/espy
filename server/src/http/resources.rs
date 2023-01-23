use crate::{
    api::{FirestoreApi, IgdbApi},
    games::SteamDataApi,
    http::models,
    util,
};
use std::{
    convert::Infallible,
    sync::{Arc, Mutex},
};
use warp::{self, Filter};

pub fn with_igdb(
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = (Arc<IgdbApi>,), Error = Infallible> + Clone {
    warp::any().map(move || Arc::clone(&igdb))
}

pub fn with_steam(
    steam: Arc<SteamDataApi>,
) -> impl Filter<Extract = (Arc<SteamDataApi>,), Error = Infallible> + Clone {
    warp::any().map(move || Arc::clone(&steam))
}

pub fn with_firestore(
    firestore: Arc<Mutex<FirestoreApi>>,
) -> impl Filter<Extract = (Arc<Mutex<FirestoreApi>>,), Error = Infallible> + Clone {
    warp::any().map(move || Arc::clone(&firestore))
}

pub fn with_keys(
    keys: Arc<util::keys::Keys>,
) -> impl Filter<Extract = (Arc<util::keys::Keys>,), Error = Infallible> + Clone {
    warp::any().map(move || Arc::clone(&keys))
}

pub fn upload_body() -> impl Filter<Extract = (models::Upload,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}

pub fn search_body() -> impl Filter<Extract = (models::Search,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(16 * 1024).and(warp::body::json())
}

pub fn resolve_body() -> impl Filter<Extract = (models::Resolve,), Error = warp::Rejection> + Clone
{
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}

pub fn match_body() -> impl Filter<Extract = (models::Match,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}

pub fn unmatch_body() -> impl Filter<Extract = (models::Unmatch,), Error = warp::Rejection> + Clone
{
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}

pub fn rematch_body() -> impl Filter<Extract = (models::Rematch,), Error = warp::Rejection> + Clone
{
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}

pub fn wishlist_body(
) -> impl Filter<Extract = (models::WishlistOp,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}
