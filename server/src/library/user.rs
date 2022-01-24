use crate::api;
use crate::documents::{Keys, UserData};
use crate::library::LibraryManager;
use crate::util;
use crate::Status;
use std::sync::{Arc, Mutex};
use std::time::{SystemTime, UNIX_EPOCH};

pub struct User {
    data: UserData,
    firestore: Arc<Mutex<api::FirestoreApi>>,
}

impl User {
    /// Returns a User instance that is loaded from the Firestore users
    /// collection. Creates a new User entry in Firestore if user does not
    /// already exist.
    pub fn new(firestore: Arc<Mutex<api::FirestoreApi>>, user_id: &str) -> Result<Self, Status> {
        match load_user(user_id, Arc::clone(&firestore)) {
            Ok(data) => Ok(User {
                data,
                firestore: Arc::clone(&firestore),
            }),
            Err(e) => {
                eprintln!("Creating new user '{}'\n{}", user_id, e);
                let user = User {
                    data: UserData {
                        uid: String::from(user_id),
                        ..Default::default()
                    },
                    firestore: Arc::clone(&firestore),
                };
                match user.save() {
                    Ok(_) => Ok(user),
                    Err(e) => Err(Status::internal(
                        &format!("Failed to read or create user '{}'", user_id),
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
    pub async fn update(&mut self, steam_user_id: &str, gog_auth_code: &str) -> Result<(), Status> {
        self.data.keys = Some(Keys {
            steam_user_id: String::from(steam_user_id),
            // TODO: Need to avoid invalidating the existing credentials for no reason.
            gog_token: match api::GogToken::from_oauth_code(gog_auth_code).await {
                Ok(token) => Some(token),
                Err(_) => None,
            },
        });

        if let Err(e) = self.save() {
            return Err(Status::internal("User.update:", e));
        }

        Ok(())
    }

    /// Synchronises user library with connected storefronts to retrieve
    /// updates.
    ///
    /// NOTE: It does not try to reconcile retrieve entries.
    /// NOTE: `egs_sid` is too ephemeral to be stored in Firestore so it is
    /// provided as an optional argument.
    pub async fn sync(
        &mut self,
        keys: &util::keys::Keys,
        egs_sid: Option<String>,
    ) -> Result<(), Status> {
        let gog_api = match self.gog_token().await {
            Some(token) => Some(api::GogApi::new(token.clone())),
            None => None,
        };

        // Need to save User as it may got GogToken updated.
        if let Err(e) = self.save() {
            return Err(Status::internal("User.sync:", e));
        }

        let steam_api = match self.steam_user_id() {
            Some(user_id) => Some(api::SteamApi::new(&keys.steam.client_key, user_id)),
            None => None,
        };

        let egs_api = match egs_sid {
            Some(egs_sid) => match api::EgsApi::connect(&egs_sid).await {
                Ok(egs_api) => Some(egs_api),
                Err(status) => {
                    return Err(Status::internal("User.sync:", status));
                }
            },
            None => None,
        };

        let mgr = LibraryManager::new(&self.data.uid, Arc::clone(&self.firestore));
        mgr.sync_library(steam_api, gog_api, egs_api).await?;

        self.data.version = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("SystemTime set before UNIX EPOCH!")
            .as_millis() as u64;
        if let Err(e) = self.save() {
            return Err(Status::internal("User.sync:", e));
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
                                eprintln!("Failed to validate GOG token. {}", e);
                                api::GogToken::new(&token.oauth_code)
                            }
                        }
                    }
                    match token.validate().await {
                        Ok(()) => Some(token),
                        Err(status) => {
                            eprintln!("Failed to validate GOG toke: {}", status);
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
        eprintln!("updating user data to firestore...");
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
