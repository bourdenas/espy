use crate::http::handlers;
use crate::igdb_service::api::IgdbApi;
use std::convert::Infallible;
use std::sync::Arc;
use warp::{self, Filter};

/// Returns a Filter with all available routes.
pub fn routes(
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    get_library(igdb)
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

fn with_igdb(
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = (Arc<IgdbApi>,), Error = Infallible> + Clone {
    warp::any().map(move || Arc::clone(&igdb))
}
