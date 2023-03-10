use crate::{api::FirestoreApi, documents::UserTags, Status};
use tracing::instrument;

#[instrument(name = "user_tags::read", level = "trace", skip(firestore, user_id))]
pub fn read(firestore: &FirestoreApi, user_id: &str) -> Result<UserTags, Status> {
    match firestore.read(&format!("users/{user_id}/user_data"), "tags") {
        Ok(tags) => Ok(tags),
        Err(Status::NotFound(_)) => Ok(UserTags::new()),
        Err(e) => Err(e),
    }
}

#[instrument(
    name = "user_tags::write",
    level = "trace",
    skip(firestore, user_id, user_tags)
)]
pub fn write(firestore: &FirestoreApi, user_id: &str, user_tags: &UserTags) -> Result<(), Status> {
    firestore.write(
        &format!("users/{user_id}/user_data"),
        Some("tags"),
        user_tags,
    )?;

    Ok(())
}

#[instrument(
    name = "user_tags::add_user_tag",
    level = "trace",
    skip(firestore, user_id)
)]
pub fn add_user_tag(
    firestore: &FirestoreApi,
    user_id: &str,
    game_id: u64,
    tag_name: String,
    class_name: Option<&str>,
) -> Result<(), Status> {
    let mut user_tags = read(firestore, user_id)?;
    if user_tags.add(game_id, tag_name, class_name) {
        write(firestore, user_id, &user_tags)?;
    }
    Ok(())
}

#[instrument(
    name = "user_tags::remove_user_tag",
    level = "trace",
    skip(firestore, user_id)
)]
pub fn remove_user_tag(
    firestore: &FirestoreApi,
    user_id: &str,
    game_id: u64,
    tag_name: &str,
    class_name: Option<&str>,
) -> Result<(), Status> {
    let mut user_tags = read(firestore, user_id)?;
    if user_tags.remove(game_id, tag_name, class_name) {
        write(firestore, user_id, &user_tags)?;
    }
    Ok(())
}
