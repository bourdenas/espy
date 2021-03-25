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
        .or(post_details(igdb))
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
    warp::body::content_length_limit(1024 * 16).and(warp::body::json())
}
