use crate::{
    api::{FirestoreApi, IgdbApi},
    http::models,
    library::{LibraryManager, User},
    util, Status,
};
use std::{
    convert::Infallible,
    sync::{Arc, Mutex},
    time::SystemTime,
};
use tracing::{debug, error, instrument, warn};
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
        .search_by_title_with_cover(&search.title, search.base_game_only)
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

#[instrument(
    level = "trace",
    skip(match_op, firestore),
    fields(
        title = %match_op.store_entry.title,
    )
)]
pub async fn post_match(
    user_id: String,
    match_op: models::MatchOp,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> Result<impl warp::Reply, Infallible> {
    debug!("POST /library/{user_id}/match");

    let manager = LibraryManager::new(&user_id, firestore);

    match (match_op.game_entry, match_op.unmatch_entry) {
        // Match StoreEntry to GameEntry and add in Library.
        (Some(game_entry), None) => match manager.get_game_entry(game_entry.id).await {
            Ok(game_entry) => {
                match manager.create_library_entry(match_op.store_entry, game_entry) {
                    Ok(()) => Ok(StatusCode::OK),
                    Err(err) => {
                        error!("{err}");
                        Ok(StatusCode::INTERNAL_SERVER_ERROR)
                    }
                }
            }
            Err(err) => {
                error!("{err}");
                Ok(StatusCode::NOT_FOUND)
            }
        },
        // Remove StoreEntry from Library.
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
        // Match StoreEntry with a different GameEntry.
        (Some(game_entry), Some(library_entry)) => {
            match manager
                .rematch_game(match_op.store_entry, game_entry, &library_entry)
                .await
            {
                Ok(()) => Ok(StatusCode::OK),
                Err(err) => {
                    error!("{err}");
                    Ok(StatusCode::INTERNAL_SERVER_ERROR)
                }
            }
        }
        // Unexpected request.
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

#[instrument(level = "trace", skip(firestore))]
pub async fn post_unlink(
    user_id: String,
    unlink: models::Unlink,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> Result<impl warp::Reply, Infallible> {
    debug!("POST /library/{user_id}/unlink");
    let started = SystemTime::now();

    // Remove storefront credentials from UserData.
    match User::new(Arc::clone(&firestore), &user_id) {
        Ok(mut user) => {
            if let Err(err) = user.remove_storefront(&unlink.storefront_id) {
                error!("{err}");
                return Ok(StatusCode::INTERNAL_SERVER_ERROR);
            }
        }
        Err(err) => {
            error!("{err}");
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    // Remove storefront library entries.
    let manager = LibraryManager::new(&user_id, firestore);
    if let Err(err) = manager.remove_storefront(&unlink.storefront_id).await {
        error!("{err}");
        return Ok(StatusCode::INTERNAL_SERVER_ERROR);
    }

    let resp_time = SystemTime::now().duration_since(started).unwrap();
    debug!("time: {:.2} msec", resp_time.as_millis());

    Ok(StatusCode::OK)
}

#[instrument(level = "trace", skip(api_keys, firestore, igdb))]
pub async fn post_sync(
    user_id: String,
    api_keys: Arc<util::keys::Keys>,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    debug!("POST /library/{user_id}/sync");
    let started = SystemTime::now();

    let store_entries = match User::new(Arc::clone(&firestore), &user_id) {
        Ok(mut user) => match user.sync_accounts(&api_keys).await {
            Ok(entries) => entries,
            Err(err) => return Ok(log_err(err)),
        },
        Err(err) => return Ok(log_err(err)),
    };

    let manager = LibraryManager::new(&user_id, firestore);
    let report = match manager.recon_store_entries(store_entries, igdb).await {
        Ok(report) => report,
        Err(err) => return Ok(log_err(err)),
    };

    let resp_time = SystemTime::now().duration_since(started).unwrap();
    debug!("time: {:.2} msec", resp_time.as_millis());

    let resp: Box<dyn warp::Reply> = Box::new(warp::reply::json(&report));
    Ok(resp)
}

#[instrument(level = "trace", skip(upload, firestore, igdb))]
pub async fn post_upload(
    user_id: String,
    upload: models::Upload,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    debug!("POST /library/{user_id}/upload");
    let started = SystemTime::now();

    let manager = LibraryManager::new(&user_id, firestore);
    let report = match manager.recon_store_entries(upload.entries, igdb).await {
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
