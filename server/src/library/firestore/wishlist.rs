use crate::{
    api::FirestoreApi,
    documents::{Library, LibraryEntry},
    Status,
};
use tracing::instrument;

#[instrument(name = "wishlist::read", level = "trace", skip(firestore, user_id))]
pub fn read(firestore: &FirestoreApi, user_id: &str) -> Result<Library, Status> {
    match firestore.read(&format!("users/{user_id}/games"), "wishlist") {
        Ok(wishlist) => Ok(wishlist),
        Err(Status::NotFound(_)) => Ok(Library::default()),
        Err(e) => Err(e),
    }
}

#[instrument(
    name = "wishlist::write",
    level = "trace",
    skip(firestore, user_id, library)
)]
pub fn write(firestore: &FirestoreApi, user_id: &str, library: &Library) -> Result<(), Status> {
    firestore.write(&format!("users/{user_id}/games"), Some("wishlist"), library)?;
    Ok(())
}

#[instrument(
    name = "wishlist::add_entry",
    level = "trace",
    skip(firestore, user_id, library_entry),
    fields(
        game_id = %library_entry.id
    ),
)]
pub fn add_entry(
    firestore: &FirestoreApi,
    user_id: &str,
    library_entry: LibraryEntry,
) -> Result<(), Status> {
    let mut wishlist = read(firestore, user_id)?;
    if add(library_entry, &mut wishlist) {
        write(firestore, user_id, &wishlist)?;
    }
    Ok(())
}

#[instrument(
    name = "wishlist::remove_entry",
    level = "trace",
    skip(firestore, user_id)
)]
pub fn remove_entry(firestore: &FirestoreApi, user_id: &str, game_id: u64) -> Result<(), Status> {
    let mut wishlist = read(firestore, user_id)?;
    if remove(game_id, &mut wishlist) {
        return write(firestore, user_id, &wishlist);
    }
    Ok(())
}

fn add(library_entry: LibraryEntry, wishlist: &mut Library) -> bool {
    match wishlist.entries.iter().find(|e| e.id == library_entry.id) {
        Some(_) => false,
        None => {
            wishlist.entries.push(library_entry);
            true
        }
    }
}

fn remove(game_id: u64, wishlist: &mut Library) -> bool {
    let original_len = wishlist.entries.len();
    wishlist.entries.retain(|e| e.id != game_id);
    wishlist.entries.len() != original_len
}
