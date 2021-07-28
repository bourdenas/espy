use crate::api;
use crate::espy;
use crate::library::LibraryManager;
use crate::util;
use crate::Status;

pub struct User {
    pub user: espy::User,
}

impl User {
    pub fn new(user_id: &str) -> Self {
        User {
            user: User::load_user(user_id),
        }
    }

    pub fn steam_user_id<'a>(&'a self) -> Option<&'a str> {
        match &self.user.keys {
            Some(keys) => Some(&keys.steam_user_id),
            None => None,
        }
    }

    pub fn gog_auth_code<'a>(&'a self) -> Option<&'a str> {
        match &self.user.keys {
            Some(keys) => match &keys.gog_token {
                Some(token) => Some(&token.oauth_code),
                None => None,
            },
            None => None,
        }
    }

    pub fn update(&mut self, steam_user_id: &str, gog_auth_code: &str) -> Result<(), Status> {
        self.user.keys = Some(espy::Keys {
            steam_user_id: String::from(steam_user_id),
            gog_token: Some(espy::GogToken {
                oauth_code: String::from(gog_auth_code),
                ..Default::default()
            }),
        });
        util::proto::save(&format!("target/{}.profile", self.user.uid), &self.user)?;

        Ok(())
    }

    pub async fn sync(&mut self, keys: &util::keys::Keys) -> Result<(), Status> {
        let gog_api = match self.gog_token() {
            Some(token) => match api::gog_token::validate(token).await {
                Ok(()) => Some(api::GogApi::new(token.clone())),
                Err(_) => match token.oauth_code.is_empty() {
                    false => {
                        let token =
                            api::gog_token::create_from_oauth_code(&token.oauth_code).await?;
                        if let Some(keys) = &mut self.user.keys {
                            keys.gog_token = Some(token.clone());
                        }
                        Some(api::GogApi::new(token))
                    }
                    true => None,
                },
            },
            None => None,
        };
        // Need to save User as it may got GogToken updated.
        // TODO: Save only if needed.
        util::proto::save(&format!("target/{}.profile", self.user.uid), &self.user)?;

        let steam_api = match self.steam_user_id() {
            Some(user_id) => Some(api::SteamApi::new(&keys.steam.client_key, user_id)),
            None => None,
        };

        let mut mgr = LibraryManager::new(&self.user.uid);
        mgr.build();
        mgr.sync(steam_api, gog_api).await?;

        Ok(())
    }

    fn gog_token<'a>(&'a mut self) -> Option<&'a mut espy::GogToken> {
        match &mut self.user.keys {
            Some(keys) => match &mut keys.gog_token {
                Some(token) => Some(token),
                None => None,
            },
            None => None,
        }
    }

    fn load_user(user_id: &str) -> espy::User {
        match util::proto::load(&format!("target/{}.profile", user_id)) {
            Ok(user) => user,
            Err(_) => {
                let user = espy::User {
                    uid: String::from(user_id),
                    ..Default::default()
                };
                if let Err(err) = util::proto::save(&format!("target/{}.profile", user_id), &user) {
                    eprintln!("Failed to create user profile '{}'", err);
                }
                user
            }
        }
    }
}
