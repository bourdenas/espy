use crate::{
    api::{FirestoreApi, IgdbApi},
    games::SteamDataApi,
    util,
};
use std::sync::{Arc, Mutex};
use tracing::warn;
use warp::{self, Filter};

use super::{handlers, resources::*};

/// Returns a Filter with all available routes.
pub fn routes(
    keys: Arc<util::keys::Keys>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    home()
        .or(post_search(Arc::clone(&igdb)))
        .or(post_resolve(
            Arc::clone(&firestore),
            Arc::clone(&igdb),
            Arc::clone(&steam),
        ))
        // TODO: Remove post_retrieve. It is a duplicate of post_resolve for the
        // transition period to maintain compatiblity with older clients.
        .or(post_retrieve(
            Arc::clone(&firestore),
            Arc::clone(&igdb),
            Arc::clone(&steam),
        ))
        .or(post_match(
            Arc::clone(&firestore),
            Arc::clone(&igdb),
            Arc::clone(&steam),
        ))
        .or(post_wishlist(Arc::clone(&firestore)))
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
        .or(get_images())
        .or_else(|e| async {
            warn! {"Rejected route: {:?}", e};
            Err(e)
        })
}

/// GET /
fn home() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!().and(warp::get()).and_then(handlers::welcome)
}

/// POST /search
fn post_search(
    igdb: Arc<IgdbApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("search")
        .and(warp::post())
        .and(search_body())
        .and(with_igdb(igdb))
        .and_then(handlers::post_search)
}

/// POST /resolve
fn post_resolve(
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("resolve")
        .and(warp::post())
        .and(resolve_body())
        .and(with_firestore(firestore))
        .and(with_igdb(igdb))
        .and(with_steam(steam))
        .and_then(handlers::post_resolve)
}

/// POST /library/retrieve
fn post_retrieve(
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / "retrieve")
        .and(warp::post())
        .and(resolve_body())
        .and(with_firestore(firestore))
        .and(with_igdb(igdb))
        .and(with_steam(steam))
        .and_then(handlers::post_resolve)
}

/// POST /library/{user_id}/match
fn post_match(
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "match")
        .and(warp::post())
        .and(match_op_body())
        .and(with_firestore(firestore))
        .and(with_igdb(igdb))
        .and(with_steam(steam))
        .and_then(handlers::post_match)
}

/// POST /library/{user_id}/wishlist
fn post_wishlist(
    firestore: Arc<Mutex<FirestoreApi>>,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("library" / String / "wishlist")
        .and(warp::post())
        .and(wishlist_body())
        .and(with_firestore(firestore))
        .and_then(handlers::post_wishlist)
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

/// GET /images/{resolution}/{image_id}
fn get_images() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("images" / String / String)
        .and(warp::get())
        .and_then(handlers::get_images)
}
