use crate::{
    api::{FirestoreApi, GogApi, GogToken, SteamApi},
    documents::UserData,
    traits, util, Status,
};
use std::{
    collections::HashSet,
    sync::{Arc, Mutex},
};
use tracing::{error, info, instrument, warn};

use super::firestore;

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

    /// Remove user credentials from a storefront.
    #[instrument(level = "trace", skip(self))]
    pub fn remove_storefront(&mut self, storefront_id: &str) -> Result<(), Status> {
        match storefront_id {
            "gog" => {
                if let Some(keys) = &mut self.data.keys {
                    keys.gog_auth_code.clear();
                    keys.gog_token = None;
                    self.save()?;
                }
                Ok(())
            }
            "steam" => {
                if let Some(keys) = &mut self.data.keys {
                    keys.steam_user_id.clear();
                    self.save()?;
                }
                Ok(())
            }
            _ => Err(Status::invalid_argument(
                format! {"Storefront '{storefront_id}' is not valid."},
            )),
        }
    }

    /// Sync user library with connected storefronts to retrieve updates.
    #[instrument(level = "trace", skip(self, keys))]
    pub async fn sync_accounts(&mut self, keys: &util::keys::Keys) -> Result<(), Status> {
        let gog_api = match self.gog_token().await {
            Some(token) => Some(GogApi::new(token.clone())),
            None => None,
        };
        if let Some(api) = gog_api {
            self.sync_storefront(&api).await?;
        }

        let steam_api = match self.steam_user_id() {
            Some(user_id) => Some(SteamApi::new(&keys.steam.client_key, user_id)),
            None => None,
        };
        if let Some(api) = steam_api {
            self.sync_storefront(&api).await?;
        }

        Ok(())
    }

    /// Retieves new game entries from the provided remote storefront and
    /// temporarily stores them in unmatched in Firestore.
    #[instrument(level = "trace", skip(self, api))]
    async fn sync_storefront<T: traits::Storefront>(&self, api: &T) -> Result<(), Status> {
        let store_entries = api.get_owned_games().await?;

        let firestore = &self.firestore.lock().unwrap();

        let mut game_ids = HashSet::<String>::from_iter(
            firestore::storefront::read(firestore, &self.data.uid, &T::id()).into_iter(),
        );

        let mut store_entries = store_entries;
        store_entries.retain(|entry| !game_ids.contains(&entry.id));

        for entry in &store_entries {
            firestore::unmatched::write(firestore, &self.data.uid, entry)?;
        }

        game_ids.extend(store_entries.into_iter().map(|store_entry| store_entry.id));
        firestore::storefront::write(
            firestore,
            &self.data.uid,
            &T::id(),
            game_ids.into_iter().collect::<Vec<_>>(),
        )
    }

    /// Returns a valid GOG token if available.
    async fn gog_token(&mut self) -> Option<GogToken> {
        {
            let keys = match &mut self.data.keys {
                Some(keys) => keys,
                None => return None,
            };

            keys.gog_token = match keys.gog_token.clone() {
                Some(mut token) => match token.validate().await {
                    Ok(()) => Some(token),
                    Err(e) => {
                        warn!("Failed to validate GOG token: {e}");
                        None
                    }
                },
                None => match keys.gog_auth_code.is_empty() {
                    false => match GogToken::from_oauth_code(&keys.gog_auth_code).await {
                        Ok(token) => Some(token),
                        Err(e) => {
                            warn!("Failed to create GOG token from oauth code. {e}");
                            None
                        }
                    },
                    true => None,
                },
            };
        }

        if self.data.keys.as_ref().unwrap().gog_token.is_some() {
            if let Err(e) = self.save() {
                error!("Failed to save user data: {e}");
            }
        }

        self.data.keys.as_ref().unwrap().gog_token.clone()
    }

    /// Returns user's Steam id.
    fn steam_user_id<'a>(&'a self) -> Option<&'a str> {
        match &self.data.keys {
            Some(keys) => Some(&keys.steam_user_id),
            None => None,
        }
    }

    fn save(&self) -> Result<(), Status> {
        save_user_data(&self.data, &self.firestore.lock().unwrap())?;
        Ok(())
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
