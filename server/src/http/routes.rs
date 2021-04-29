use crate::http::handlers;
use crate::http::models;
use crate::igdb_service::api::IgdbApi;
use std::convert::Infallible;
use std::sync::Arc;
use warp::{self, Filter};

/// Returns a Filter with all available routes.
pub fn routes(
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    get_library(igdb.clone())
        .or(post_details(igdb.clone()))
        .or(post_match(igdb.clone()))
        .or(post_unmatch(igdb.clone()))
        .or(post_search(igdb))
        .or(get_images())
}

/// GET /library/{user_id}
fn get_library(
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String)
        .and(warp::get())
        .and(with_igdb(igdb))
        .and_then(handlers::get_library)
}

/// POST /library/{user_id}/details/{id}
fn post_details(
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "details" / u64)
        .and(warp::post())
        .and(details_body())
        .and(with_igdb(igdb))
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
fn post_unmatch(
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "unmatch")
        .and(warp::post())
        .and(match_body())
        .and(with_igdb(igdb))
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

fn details_body() -> impl Filter<Extract = (models::Details,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(32 * 1024).and(warp::body::json())
}

fn match_body() -> impl Filter<Extract = (models::Match,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(64 * 1024).and(warp::body::json())
}

fn search_body() -> impl Filter<Extract = (models::Search,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(16 * 1024).and(warp::body::json())
}
