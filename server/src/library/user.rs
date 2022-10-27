use super::{LibraryManager, ReconReport, Reconciler};
use crate::{
    api::{self, FirestoreApi, GogApi, SteamApi},
    documents::{GameEntry, Keys, LibraryEntry, StoreEntry, UserData},
    util, Status,
};
use std::{
    sync::{Arc, Mutex},
    time::{SystemTime, UNIX_EPOCH},
};
use tracing::{info, instrument, warn};

pub struct User {
    data: UserData,
    firestore: Arc<Mutex<FirestoreApi>>,
}

impl User {
    /// Returns a User instance that is loaded from the Firestore users
    /// collection. Creates a new User entry in Firestore if user does not
    /// already exist.
    #[instrument(level = "trace", skip(firestore))]
    pub fn new(firestore: Arc<Mutex<FirestoreApi>>, user_id: &str) -> Result<Self, Status> {
        load_user(user_id, firestore)
    }

    /// Updates user's storefront credentials. This may cause refresh of
    /// credentials. Updated user data are pushed to Firestore.
    #[instrument(level = "trace", skip(self, steam_user_id, gog_auth_code))]
    pub async fn update_storefronts(
        &mut self,
        steam_user_id: &str,
        gog_auth_code: &str,
    ) -> Result<(), Status> {
        self.data.keys = Some(Keys {
            // TODO: Need to avoid invalidating the existing credentials for no reason.
            gog_token: match api::GogToken::from_oauth_code(gog_auth_code).await {
                Ok(token) => Some(token),
                Err(_) => None,
            },
            steam_user_id: String::from(steam_user_id),
            egs_auth_code: String::default(),
        });

        if let Err(e) = save_user_data(&self.data, &self.firestore.lock().unwrap()) {
            return Err(Status::new("User.update:", e));
        }

        Ok(())
    }

    /// Synchronises user library with connected storefronts to retrieve
    /// updates.
    #[instrument(level = "trace", skip(self, keys, recon_service))]
    pub async fn sync(
        &mut self,
        keys: &util::keys::Keys,
        recon_service: Reconciler,
    ) -> Result<ReconReport, Status> {
        let gog_api = match self.gog_token().await {
            Some(token) => {
                let gog_api = Some(GogApi::new(token.clone()));

                // Need to save User as it may got GogToken updated.
                if let Err(e) = save_user_data(&self.data, &self.firestore.lock().unwrap()) {
                    return Err(Status::new("User::sync(): failed to save user data.", e));
                }
                gog_api
            }
            None => None,
        };

        let steam_api = match self.steam_user_id() {
            Some(user_id) => Some(SteamApi::new(&keys.steam.client_key, user_id)),
            None => None,
        };

        let mgr = LibraryManager::new(&self.data.uid, Arc::clone(&self.firestore));
        let report = mgr.sync_library(steam_api, gog_api, recon_service).await?;

        commit_version(&mut self.data, &self.firestore.lock().unwrap())?;
        Ok(report)
    }

    /// Manually uploads a set of StoreEntries to the user library for
    /// reconciling.
    #[instrument(level = "trace", skip(self, entries, recon_service))]
    pub async fn upload(
        &mut self,
        entries: Vec<StoreEntry>,
        recon_service: Reconciler,
    ) -> Result<ReconReport, Status> {
        let mgr = LibraryManager::new(&self.data.uid, Arc::clone(&self.firestore));
        let report = mgr.recon_store_entries(entries, recon_service).await?;

        commit_version(&mut self.data, &self.firestore.lock().unwrap())?;
        Ok(report)
    }

    /// Manually matches a StoreEntry with a LibraryEntry.
    #[instrument(level = "trace", skip(self, recon_service))]
    pub async fn match_entry(
        &mut self,
        store_entry: StoreEntry,
        game_entry: GameEntry,
        recon_service: Reconciler,
    ) -> Result<(), Status> {
        let mgr = LibraryManager::new(&self.data.uid, Arc::clone(&self.firestore));
        mgr.manual_match(recon_service, store_entry, game_entry)
            .await?;

        commit_version(&mut self.data, &self.firestore.lock().unwrap())
    }

    /// Unmatches or deletes (based on `delete`) a StoreEntry with a LibraryEntry.
    #[instrument(level = "trace", skip(self, library_entry))]
    pub async fn unmatch_entry(
        &mut self,
        store_entry: StoreEntry,
        library_entry: LibraryEntry,
        delete: bool,
    ) -> Result<(), Status> {
        let mgr = LibraryManager::new(&self.data.uid, Arc::clone(&self.firestore));
        match delete {
            false => mgr.unmatch_game(store_entry, library_entry).await?,
            true => mgr.delete_game(store_entry, library_entry).await?,
        }

        commit_version(&mut self.data, &self.firestore.lock().unwrap())
    }

    /// Tries to validate user's GogToken and returns a reference to it only if
    /// it succeeds.
    async fn gog_token<'a>(&'a mut self) -> Option<&'a mut api::GogToken> {
        match &mut self.data.keys {
            Some(keys) => match &mut keys.gog_token {
                Some(token) => {
                    if token.access_token.is_empty() {
                        *token = match api::GogToken::from_oauth_code(&token.oauth_code).await {
                            Ok(token) => token,
                            Err(e) => {
                                warn!("Failed to validate GOG token. {e}");
                                api::GogToken::new(&token.oauth_code)
                            }
                        }
                    }

                    match token.validate().await {
                        Ok(()) => Some(token),
                        Err(e) => {
                            warn!("Failed to validate GOG token: {e}");
                            None
                        }
                    }
                }
                None => None,
            },
            None => None,
        }
    }

    /// Returns user's Steam id.
    fn steam_user_id<'a>(&'a self) -> Option<&'a str> {
        match &self.data.keys {
            Some(keys) => Some(&keys.steam_user_id),
            None => None,
        }
    }
}

#[instrument(level = "trace", skip(user_id, firestore))]
fn load_user(user_id: &str, firestore: Arc<Mutex<FirestoreApi>>) -> Result<User, Status> {
    if let Ok(data) = load_user_data(user_id, Arc::clone(&firestore)) {
        return Ok(User { data, firestore });
    }

    info!("Creating new user '{user_id}'");
    let user = User {
        data: UserData {
            uid: String::from(user_id),
            ..Default::default()
        },
        firestore: Arc::clone(&firestore),
    };

    match save_user_data(&user.data, &firestore.lock().unwrap()) {
        Ok(_) => Ok(user),
        Err(e) => Err(Status::new(
            &format!("Failed to create user '{user_id}'"),
            e,
        )),
    }
}

fn load_user_data(user_id: &str, firestore: Arc<Mutex<FirestoreApi>>) -> Result<UserData, Status> {
    Ok(firestore
        .lock()
        .unwrap()
        .read::<UserData>("users", user_id)?)
}

#[instrument(level = "trace", skip(user_data, firestore))]
fn save_user_data(user_data: &UserData, firestore: &FirestoreApi) -> Result<String, Status> {
    firestore.write("users", Some(&user_data.uid), user_data)
}

#[instrument(level = "trace", skip(user_data, firestore))]
fn commit_version(user_data: &mut UserData, firestore: &FirestoreApi) -> Result<(), Status> {
    user_data.version = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("SystemTime set before UNIX EPOCH!")
        .as_millis() as u64;
    if let Err(e) = save_user_data(&user_data, firestore) {
        return Err(Status::new("Failed to commit version:", e));
    }

    Ok(())
}
