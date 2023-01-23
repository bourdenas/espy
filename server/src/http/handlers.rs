use crate::{
    api::{FirestoreApi, IgdbApi},
    games::{Resolver, SteamDataApi},
    http::models,
    library::User,
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
    info!("POST /library/resolve");

    match Resolver::resolve(resolve.game_id, igdb, steam, firestore).await {
        Ok(_) => Ok(StatusCode::OK),
        Err(e) => {
            error!("POST retrieve: {e}");
            Ok(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

#[instrument(level = "trace", skip(firestore, igdb, steam))]
pub async fn post_match_op(
    user_id: String,
    match_op: models::MatchOp,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> Result<impl warp::Reply, Infallible> {
    debug!("POST /library/{user_id}/match_op");

    let mut user = match User::new(firestore, &user_id) {
        Ok(user) => user,
        Err(err) => {
            error!("{err}");
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    if let Some(library_entry) = match_op.unmatch_entry {
        if let Err(err) = user
            .unmatch_entry(
                match_op.store_entry.clone(),
                &library_entry,
                match_op.delete_unmatched,
            )
            .await
        {
            error!("{err}");
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    }

    if let Some(game_entry) = match_op.game_entry {
        if let Err(err) = user
            .match_entry(
                match_op.store_entry,
                game_entry,
                igdb,
                steam,
                match_op.exact_match,
            )
            .await
        {
            error!("{err}");
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    }

    Ok(StatusCode::OK)
}

#[instrument(level = "trace", skip(_match, firestore, igdb, steam))]
pub async fn post_match(
    user_id: String,
    _match: models::Match,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> Result<impl warp::Reply, Infallible> {
    debug!("POST /library/{user_id}/match");

    let mut user = match User::new(firestore, &user_id) {
        Ok(user) => user,
        Err(err) => {
            error!("{err}");
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    match user
        .match_entry(_match.store_entry, _match.game_entry, igdb, steam, false)
        .await
    {
        Ok(()) => Ok(StatusCode::OK),
        Err(err) => {
            error!("{err}");
            Ok(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

#[instrument(level = "trace", skip(firestore))]
pub async fn post_unmatch(
    user_id: String,
    unmatch: models::Unmatch,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> Result<impl warp::Reply, Infallible> {
    debug!("POST /library/{user_id}/unmatch");

    let mut user = match User::new(firestore, &user_id) {
        Ok(user) => user,
        Err(err) => {
            error!("{err}");
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    match user
        .unmatch_entry(unmatch.store_entry, &unmatch.library_entry, unmatch.delete)
        .await
    {
        Ok(()) => Ok(StatusCode::OK),
        Err(err) => {
            error!("{err}");
            Ok(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

#[instrument(level = "trace", skip(firestore, igdb, steam))]
pub async fn post_rematch(
    user_id: String,
    rematch: models::Rematch,
    firestore: Arc<Mutex<FirestoreApi>>,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
) -> Result<impl warp::Reply, Infallible> {
    debug!("POST /library/{user_id}/rematch");

    let mut user = match User::new(firestore, &user_id) {
        Ok(user) => user,
        Err(err) => {
            error!("{err}");
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    match user
        .rematch_entry(
            rematch.store_entry,
            rematch.game_entry,
            &rematch.library_entry,
            igdb,
            steam,
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

#[instrument(level = "trace", skip(firestore))]
pub async fn post_wishlist(
    user_id: String,
    wishlist: models::WishlistOp,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> Result<impl warp::Reply, Infallible> {
    debug!("POST /library/{user_id}/wishlist");

    let user = match User::new(firestore, &user_id) {
        Ok(user) => user,
        Err(err) => {
            error!("{err}");
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    match wishlist.add_game {
        Some(game) => match user.add_to_wishlist(game).await {
            Ok(()) => (),
            Err(err) => {
                error!("{err}");
                return Ok(StatusCode::INTERNAL_SERVER_ERROR);
            }
        },
        None => (),
    }

    match wishlist.remove_game {
        Some(game_id) => match user.remove_from_wishlist(game_id).await {
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

    let mut user = match User::new(firestore, &user_id) {
        Ok(user) => user,
        Err(err) => return Ok(log_err(err)),
    };

    let report = match user.sync(&api_keys, igdb, steam).await {
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

    let mut user = match User::new(Arc::clone(&firestore), &user_id) {
        Ok(user) => user,
        Err(err) => return Ok(log_err(err)),
    };
    let report = match user.upload(upload.entries, igdb, steam).await {
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
