use crate::{
    api::{FirestoreApi, IgdbApi},
    games::{Resolver, SteamDataApi},
    http::models,
    library::{LibraryManager, User},
    util, Status,
};
use std::{
    convert::Infallible,
    sync::{Arc, Mutex},
    time::SystemTime,
};
use tracing::{debug, error, info, instrument, warn};
use warp::http::StatusCode;

pub async fn welcome() -> Result<impl warp::Reply, Infallible> {
    debug!("GET /");
    Ok("welcome")
}

#[instrument(level = "trace", skip(igdb))]
pub async fn post_search(
    search: models::Search,
    igdb: Arc<IgdbApi>,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    debug!("POST /search");
    let started = SystemTime::now();

    let resp: Result<Box<dyn warp::Reply>, Infallible> = match igdb
        .get_by_title_with_cover(&search.title, search.base_game_only)
        .await
    {
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

#[instrument(level = "trace", skip(firestore, igdb, steam))]
pub async fn post_resolve(
    resolve: models::Resolve,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> Result<impl warp::Reply, Infallible> {
    info!("POST /resolve");

    match Resolver::resolve(resolve.game_id, igdb, steam, firestore).await {
        Ok(_) => Ok(StatusCode::OK),
        Err(e) => {
            error!("POST resolve: {e}");
            Ok(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

#[instrument(level = "trace", skip(firestore, igdb, steam))]
pub async fn post_match(
    user_id: String,
    match_op: models::MatchOp,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> Result<impl warp::Reply, Infallible> {
    debug!("POST /library/{user_id}/match");

    let manager = LibraryManager::new(&user_id, firestore);

    match (match_op.game_entry, match_op.unmatch_entry) {
        (Some(game_entry), None) => {
            match manager
                .match_game(
                    match_op.store_entry,
                    game_entry,
                    igdb,
                    steam,
                    match_op.exact_match,
                )
                .await
            {
                Ok(()) => Ok(StatusCode::OK),
                Err(err) => {
                    error!("{err}");
                    Ok(StatusCode::INTERNAL_SERVER_ERROR)
                }
            }
        }
        (None, Some(library_entry)) => {
            match manager
                .unmatch_game(
                    match_op.store_entry.clone(),
                    &library_entry,
                    match_op.delete_unmatched,
                )
                .await
            {
                Ok(()) => Ok(StatusCode::OK),
                Err(err) => {
                    error!("{err}");
                    Ok(StatusCode::INTERNAL_SERVER_ERROR)
                }
            }
        }
        (Some(game_entry), Some(library_entry)) => {
            match manager
                .rematch_game(
                    match_op.store_entry,
                    game_entry,
                    &library_entry,
                    igdb,
                    steam,
                    match_op.exact_match,
                )
                .await
            {
                Ok(()) => Ok(StatusCode::OK),
                Err(err) => {
                    error!("{err}");
                    Ok(StatusCode::INTERNAL_SERVER_ERROR)
                }
            }
        }
        (None, None) => Ok(StatusCode::BAD_REQUEST),
    }
}

#[instrument(level = "trace", skip(firestore))]
pub async fn post_wishlist(
    user_id: String,
    wishlist: models::WishlistOp,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> Result<impl warp::Reply, Infallible> {
    debug!("POST /library/{user_id}/wishlist");

    let manager = LibraryManager::new(&user_id, firestore);

    match wishlist.add_game {
        Some(game) => match manager.add_to_wishlist(game).await {
            Ok(()) => (),
            Err(err) => {
                error!("{err}");
                return Ok(StatusCode::INTERNAL_SERVER_ERROR);
            }
        },
        None => (),
    }

    match wishlist.remove_game {
        Some(game_id) => match manager.remove_from_wishlist(game_id).await {
            Ok(()) => (),
            Err(err) => {
                error!("{err}");
                return Ok(StatusCode::INTERNAL_SERVER_ERROR);
            }
        },
        None => (),
    }

    Ok(StatusCode::OK)
}

#[instrument(level = "trace", skip(api_keys, firestore, igdb, steam))]
pub async fn post_sync(
    user_id: String,
    api_keys: Arc<util::keys::Keys>,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    debug!("POST /library/{user_id}/sync");
    let started = SystemTime::now();

    match User::new(Arc::clone(&firestore), &user_id) {
        Ok(mut user) => {
            if let Err(err) = user.sync(&api_keys).await {
                return Ok(log_err(err));
            }
        }
        Err(err) => return Ok(log_err(err)),
    };

    let manager = LibraryManager::new(&user_id, firestore);
    let report = match manager.recon_unmatched_collection(igdb, steam).await {
        Ok(report) => report,
        Err(err) => return Ok(log_err(err)),
    };

    let resp_time = SystemTime::now().duration_since(started).unwrap();
    debug!("time: {:.2} msec", resp_time.as_millis());

    let resp: Box<dyn warp::Reply> = Box::new(warp::reply::json(&report));
    Ok(resp)
}

#[instrument(level = "trace", skip(upload, firestore, igdb, steam))]
pub async fn post_upload(
    user_id: String,
    upload: models::Upload,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    debug!("POST /library/{user_id}/upload");
    let started = SystemTime::now();

    let manager = LibraryManager::new(&user_id, firestore);
    let report = match manager
        .recon_store_entries(upload.entries, igdb, steam)
        .await
    {
        Ok(report) => report,
        Err(err) => return Ok(log_err(err)),
    };

    let resp_time = SystemTime::now().duration_since(started).unwrap();
    debug!("time: {:.2} msec", resp_time.as_millis());

    let resp: Box<dyn warp::Reply> = Box::new(warp::reply::json(&report));
    Ok(resp)
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

const IGDB_IMAGES_URL: &str = "https://images.igdb.com/igdb/image/upload";

fn log_err(status: Status) -> Box<dyn warp::Reply> {
    error!("{status}");
    let status: Box<dyn warp::Reply> = Box::new(StatusCode::INTERNAL_SERVER_ERROR);
    status
}
