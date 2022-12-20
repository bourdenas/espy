use serde::{Deserialize, Serialize};

/// Document type under 'users/{user_id}/user_data/tags'.
#[derive(Serialize, Deserialize, Default, Debug)]
pub struct LegacyUserTags {
    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub tags: Vec<Tag>,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct UserTags {
    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub classes: Vec<TagClass>,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct TagClass {
    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,

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
    pub fn new() -> Self {
        UserTags {
            classes: vec![TagClass {
                name: None,
                tags: vec![],
            }],
        }
    }

    /// Returns true if `tag` was added on `game_id`, false if it existed already.
    pub fn add(&mut self, game_id: u64, tag_name: String, class_name: Option<&str>) -> bool {
        let mut class = self.get_class(class_name);
        if let None = &class {
            self.classes.push(TagClass {
                name: match class_name {
                    Some(name) => Some(name.to_owned()),
                    None => None,
                },
                tags: vec![],
            });
            class = self.classes.last_mut();
        }

        if let Some(class) = class {
            match class.tags.iter_mut().find(|tag| tag.name == tag_name) {
                Some(tag) => {
                    if tag.game_ids.contains(&game_id) {
                        return false;
                    }
                    tag.game_ids.push(game_id)
                }
                None => class.tags.push(Tag {
                    name: tag_name,
                    game_ids: vec![game_id],
                }),
            }
            true
        } else {
            false
        }
    }

    /// Returns true if `tag` was removed from `game_id`, false if it did not exist.
    pub fn remove(&mut self, game_id: u64, tag_name: &str, class_name: Option<&str>) -> bool {
        let Some(class) = self.get_class(class_name)else {
            return false;
        };
        let Some(tag) = class.tags.iter_mut().find(|tag| tag.name == tag_name) else {
            return false;
        };
        let Some(index) = tag.game_ids.iter().position(|id| *id == game_id) else {
            return false;
        };
        tag.game_ids.remove(index);
        true
    }

    fn get_class<'a>(&'a mut self, name: Option<&str>) -> Option<&'a mut TagClass> {
        match name {
            Some(name) => self
                .classes
                .iter_mut()
                .find(|class| class.name.as_ref().unwrap() == name),
            None => self.classes.iter_mut().find(|class| class.name.is_none()),
        }
    }
}
