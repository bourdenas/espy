use crate::api::{FirestoreApi, IgdbApi};
use crate::espy;
use crate::http::models;
use crate::igdb;
use crate::library;
use crate::library::{Reconciler, User};
use crate::util;
use prost::bytes::Bytes;
use prost::Message;
use std::convert::Infallible;
use std::sync::{Arc, Mutex};
use warp::http::StatusCode;

#[deprecated(note = "TBR by direct client calls to Firestore.")]
pub async fn get_library(user_id: String) -> Result<Box<dyn warp::Reply>, Infallible> {
    println!("GET /library/{}", &user_id);

    let library = espy::Library::default();

    let mut bytes = vec![];
    match library.encode(&mut bytes) {
        Ok(_) => Ok(Box::new(bytes)),
        Err(_) => Ok(Box::new(StatusCode::NOT_FOUND)),
    }
}

#[deprecated(note = "TBR by direct client calls to Firestore.")]
pub async fn get_settings(
    user_id: String,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    println!("GET /library/{}/settings", &user_id);

    let user = match User::new(firestore, &user_id) {
        Ok(user) => user,
        Err(e) => {
            eprintln!("GET /library/{}/settings: {}", &user_id, e);
            return Ok(Box::new(StatusCode::INTERNAL_SERVER_ERROR));
        }
    };

    let settings = models::Settings {
        steam_user_id: match user.steam_user_id() {
            Some(id) => String::from(id),
            None => String::default(),
        },
        gog_auth_code: match user.gog_auth_code() {
            Some(code) => String::from(code),
            None => String::default(),
        },
    };

    Ok(Box::new(warp::reply::json(&settings)))
}

#[deprecated(note = "TBR by direct client calls to Firestore.")]
pub async fn post_settings(
    user_id: String,
    settings: models::Settings,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> Result<impl warp::Reply, Infallible> {
    println!("POST /library/{}/settings", &user_id);

    let mut user = match User::new(firestore, &user_id) {
        Ok(user) => user,
        Err(e) => {
            eprintln!("POST /library/{}/settings: {}", &user_id, e);
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    let result = user
        .update(&settings.steam_user_id, &settings.gog_auth_code)
        .await;

    match result {
        Ok(()) => Ok(StatusCode::OK),
        Err(err) => {
            eprintln!("{}", err);
            Ok(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

pub async fn post_sync(
    user_id: String,
    keys: Arc<util::keys::Keys>,
    firestore: Arc<Mutex<FirestoreApi>>,
) -> Result<impl warp::Reply, Infallible> {
    println!("POST /library/{}/sync", &user_id);

    let mut user = match User::new(firestore, &user_id) {
        Ok(user) => user,
        Err(e) => {
            eprintln!("POST /library/{}/settings: {}", &user_id, e);
            return Ok(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };
    let result = user.sync(&keys).await;

    match result {
        Ok(()) => Ok(StatusCode::OK),
        Err(err) => {
            eprintln!("{}", err);
            Ok(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

#[deprecated(note = "TBR by direct client calls to Firestore.")]
pub async fn post_details(
    user_id: String,
    game_id: u64,
    details: models::Details,
) -> Result<impl warp::Reply, Infallible> {
    println!(
        "POST /library/{}/details/{} body: {:?}",
        &user_id, game_id, &details
    );

    let mut library = espy::Library::default();

    let entry = library.entry.iter_mut().find(|entry| match &entry.game {
        Some(game) => game.id == game_id,
        None => false,
    });

    if let None = entry {
        return Ok(StatusCode::NOT_FOUND);
    }
    let entry = entry.unwrap();
    entry.details = Some(espy::GameDetails { tag: details.tags });

    Ok(StatusCode::OK)
}

pub async fn post_match(
    user_id: String,
    match_msg: models::Match,
    igdb: Arc<IgdbApi>,
) -> Result<impl warp::Reply, Infallible> {
    println!("POST /library/{}/match", &user_id);

    let store_entry = match espy::StoreEntry::decode(Bytes::from(match_msg.encoded_store_entry)) {
        Ok(msg) => msg,
        Err(e) => {
            eprintln!("post_match StoreEntry decoding error: {}", e);
            return Ok(StatusCode::BAD_REQUEST);
        }
    };
    let game = match igdb::Game::decode(Bytes::from(match_msg.encoded_game)) {
        Ok(msg) => msg,
        Err(e) => {
            eprintln!("post_match Game decoding error: {}", e);
            return Ok(StatusCode::BAD_REQUEST);
        }
    };

    let mut library = espy::Library::default();

    library
        .unreconciled_store_entry
        .retain(|e| !(e.id == store_entry.id && e.store == store_entry.store));

    let entry = library.entry.iter_mut().find(|e| match &e.game {
        Some(g) => g.id == game.id,
        None => false,
    });

    match entry {
        Some(entry) => entry.store_entry.push(store_entry),
        None => {
            let mut entry = espy::GameEntry {
                game: Some(game),
                store_entry: vec![store_entry],
                ..Default::default()
            };
            let recon_service = Reconciler::new(Arc::clone(&igdb));

            if let Err(_) = recon_service.update_entry(&mut entry).await {
                return Ok(StatusCode::INTERNAL_SERVER_ERROR);
            }
            library.entry.push(entry);
        }
    }

    Ok(StatusCode::OK)
}

#[deprecated(note = "TBR by direct client calls to Firestore.")]
pub async fn post_unmatch(
    user_id: String,
    match_msg: models::Match,
) -> Result<impl warp::Reply, Infallible> {
    println!("POST /library/{}/unmatch", &user_id);

    let store_entry = match espy::StoreEntry::decode(Bytes::from(match_msg.encoded_store_entry)) {
        Ok(msg) => msg,
        Err(e) => {
            eprintln!("post_unmatch StoreEntry decoding error: {}", e);
            return Ok(StatusCode::BAD_REQUEST);
        }
    };
    let game = match igdb::Game::decode(Bytes::from(match_msg.encoded_game)) {
        Ok(msg) => msg,
        Err(e) => {
            eprintln!("post_unmatch Game decoding error: {}", e);
            return Ok(StatusCode::BAD_REQUEST);
        }
    };

    let mut library = espy::Library::default();

    // There's no remove_if so I need to iterate the vector twice. Once to find
    // the game entry and remove the request's storefront from it and a second
    // one to remove the game entry if it no longer has a store entry.
    let entry = library.entry.iter_mut().find(|e| match &e.game {
        Some(g) => g.id == game.id,
        None => false,
    });
    if let Some(entry) = entry {
        entry
            .store_entry
            .retain(|se| !(se.id == store_entry.id && se.store == store_entry.store));
    }
    // NB: It'd be nice if retain() allowed for modifying elements.
    library.entry.retain(|e| !e.store_entry.is_empty());
    library.unreconciled_store_entry.push(store_entry);

    Ok(StatusCode::OK)
}

pub async fn post_search(
    search: models::Search,
    igdb: Arc<IgdbApi>,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    println!("POST /search body: {:?}", &search);

    let candidates = match library::search::get_candidates(&igdb, &search.title).await {
        Ok(result) => result,
        Err(_) => return Ok(Box::new(StatusCode::NOT_FOUND)),
    };

    let result = igdb::GameResult {
        games: candidates.into_iter().map(|c| c.game).collect(),
    };

    let mut bytes = vec![];
    match result.encode(&mut bytes) {
        Ok(_) => Ok(Box::new(bytes)),
        Err(_) => Ok(Box::new(StatusCode::NOT_FOUND)),
    }
}

pub async fn get_images(
    resolution: String,
    image: String,
) -> Result<Box<dyn warp::Reply>, Infallible> {
    println!("GET /images/{}/{}", &resolution, &image);

    let uri = format!("{}/{}/{}", IGDB_IMAGES_URL, &resolution, &image);
    let resp = match reqwest::Client::new().get(&uri).send().await {
        Ok(resp) => resp,
        Err(e) => {
            eprintln!("Remote GET failed! {}", e);
            return Ok(Box::new(StatusCode::NOT_FOUND));
        }
    };

    if resp.status() != StatusCode::OK {
        eprintln!(
            "Failed to retrieve image: {} \nerr: {}",
            &uri,
            resp.status()
        );
        return Ok(Box::new(resp.status()));
    }

    match resp.bytes().await {
        Ok(bytes) => Ok(Box::new(bytes.to_vec())),
        Err(_) => Ok(Box::new(StatusCode::NOT_FOUND)),
    }
}

const IGDB_IMAGES_URL: &str = "https://images.igdb.com/igdb/image/upload";
