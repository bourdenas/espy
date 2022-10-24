use super::{LibraryManager, Reconciler};
use crate::{
    api,
    documents::{Keys, UserData},
    util, Status,
};
use std::{
    sync::{Arc, Mutex},
    time::{SystemTime, UNIX_EPOCH},
};
use tracing::{info, instrument, warn};

pub struct User {
    data: UserData,
    firestore: Arc<Mutex<api::FirestoreApi>>,
}

impl User {
    /// Returns a User instance that is loaded from the Firestore users
    /// collection. Creates a new User entry in Firestore if user does not
    /// already exist.
    #[instrument(level = "trace", skip(firestore))]
    pub fn new(firestore: Arc<Mutex<api::FirestoreApi>>, user_id: &str) -> Result<Self, Status> {
        match load_user(user_id, Arc::clone(&firestore)) {
            Ok(data) => Ok(User {
                data,
                firestore: Arc::clone(&firestore),
            }),
            Err(e) => {
                info!("Creating new user '{user_id}'\n{e}");
                let user = User {
                    data: UserData {
                        uid: String::from(user_id),
                        ..Default::default()
                    },
                    firestore: Arc::clone(&firestore),
                };
                match user.save() {
                    Ok(_) => Ok(user),
                    Err(e) => Err(Status::new(
                        &format!("Failed to read or create user '{user_id}'"),
                        e,
                    )),
                }
            }
        }
    }

    /// Returns user's Steam id.
    pub fn steam_user_id<'a>(&'a self) -> Option<&'a str> {
        match &self.data.keys {
            Some(keys) => Some(&keys.steam_user_id),
            None => None,
        }
    }

    /// Returns user's GOG oauth code returned after successful sign in externally.
    pub fn gog_auth_code<'a>(&'a self) -> Option<&'a str> {
        match &self.data.keys {
            Some(keys) => match &keys.gog_token {
                Some(token) => Some(&token.oauth_code),
                None => None,
            },
            None => None,
        }
    }

    /// Updates the user's Steam id and GOG oauth code. If GOG oauth code is
    /// different than what was already store the GOG logic credentials of the
    /// user are invalidated and refreshed.
    /// Updated user entry is pushed to Firestore.
    #[instrument(level = "trace", skip(self, steam_user_id, gog_auth_code))]
    pub async fn update_codes(
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

        if let Err(e) = self.save() {
            return Err(Status::new("User.update:", e));
        }

        Ok(())
    }

    #[instrument(level = "trace", skip(self))]
    pub fn update_library_version(&mut self) -> Result<(), Status> {
        self.data.version = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("SystemTime set before UNIX EPOCH!")
            .as_millis() as u64;
        if let Err(e) = self.save() {
            return Err(Status::new("User.sync:", e));
        }

        Ok(())
    }

    /// Synchronises user library with connected storefronts to retrieve
    /// updates.
    ///
    /// NOTE: It does not try to reconcile retrieve entries.
    /// NOTE: `egs_sid` is too ephemeral to be stored in Firestore so it is
    /// provided as an optional argument.
    #[instrument(level = "trace", skip(self, keys, recon_service))]
    pub async fn sync(
        &mut self,
        keys: &util::keys::Keys,
        recon_service: Reconciler,
    ) -> Result<(), Status> {
        let gog_api = match self.gog_token().await {
            Some(token) => {
                let gog_api = Some(api::GogApi::new(token.clone()));

                // Need to save User as it may got GogToken updated.
                if let Err(e) = self.save() {
                    return Err(Status::new("User.sync:", e));
                }
                gog_api
            }
            None => None,
        };

        let steam_api = match self.steam_user_id() {
            Some(user_id) => Some(api::SteamApi::new(&keys.steam.client_key, user_id)),
            None => None,
        };

        let mgr = LibraryManager::new(&self.data.uid, Arc::clone(&self.firestore));
        mgr.sync_library(steam_api, gog_api, recon_service).await?;

        if let Err(e) = self.update_library_version() {
            return Err(Status::new("User.sync:", e));
        }

        Ok(())
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
                        Err(status) => {
                            warn!("Failed to validate GOG toke: {status}");
                            None
                        }
                    }
                }
                None => None,
            },
            None => None,
        }
    }

    /// Save user entry to Firestore. Returns the Firestore document id.
    fn save(&self) -> Result<String, Status> {
        info!("updating user data to firestore...");
        self.firestore
            .lock()
            .unwrap()
            .write("users", Some(&self.data.uid), &self.data)
    }
}

fn load_user(user_id: &str, firestore: Arc<Mutex<api::FirestoreApi>>) -> Result<UserData, Status> {
    Ok(firestore
        .lock()
        .unwrap()
        .read::<UserData>("users", user_id)?)
}
