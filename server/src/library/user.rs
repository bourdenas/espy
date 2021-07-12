use crate::espy;
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

    pub fn update(mut self, steam_user_id: &str, gog_auth_code: &str) -> Result<(), Status> {
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
