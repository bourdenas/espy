use serde::{Deserialize, Serialize};

/// Document type under 'users/{user_id}/user_data/tags'.
#[derive(Serialize, Deserialize, Default, Debug)]
pub struct UserTags {
    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub tags: Vec<Tag>,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Tag {
    pub name: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub game_ids: Vec<u64>,
}

impl UserTags {
    /// Returns true if `tag` was added on `game_id`, false if it existed already.
    pub fn add(&mut self, game_id: u64, tag_name: String) -> bool {
        match self.tags.iter_mut().find(|tag| tag.name == tag_name) {
            Some(tag) => {
                if tag.game_ids.contains(&game_id) {
                    return false;
                }
                tag.game_ids.push(game_id)
            }
            None => self.tags.push(Tag {
                name: tag_name,
                game_ids: vec![game_id],
            }),
        }
        true
    }

    /// Returns true if `tag` was removed from `game_id`, false if it did not exist.
    pub fn remove(&mut self, game_id: u64, tag_name: &str) -> bool {
        let Some(tag) = self.tags.iter_mut().find(|tag| tag.name == tag_name) else {
            return false;
        };
        let Some(index) = tag.game_ids.iter().position(|id| *id == game_id) else {
            return false;
        };
        tag.game_ids.remove(index);
        true
    }
}
