use super::library_ops::LibraryOps;
use crate::{
    api::FirestoreApi,
    documents::{GameEntry, LibraryEntry, StoreEntry},
    Status,
};

pub struct LibraryTransactions;

/// NOTE: All operations here should be transactions, but this is not currently
/// supported by this library.
impl LibraryTransactions {
    /// Handles successfully resovled StoreEntry.
    pub fn match_game(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: StoreEntry,
        owned_version: u64,
        game_entry: GameEntry,
    ) -> Result<(), Status> {
        LibraryOps::write_game_entry(firestore, &game_entry)?;
        LibraryOps::delete_unmatched(firestore, user_id, &store_entry)?;

        let library_entry = LibraryEntry::new(
            game_entry,
            vec![store_entry.clone()],
            vec![owned_version],
            None,
        );

        LibraryOps::append_to_recent(firestore, user_id, &library_entry, store_entry)?;

        // Update LibraryEntry. It might already exist from a different
        // storefront.
        LibraryOps::update_library_entry(firestore, user_id, library_entry)?;

        Ok(())
    }

    /// Delete or unmatches (based on `delete`) a StoreEntry from the library.
    pub fn unmatch_game(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: StoreEntry,
        library_entry: LibraryEntry,
        delete: bool,
    ) -> Result<(), Status> {
        let mut library_entry = library_entry;
        LibraryOps::remove_from_library_entry(
            firestore,
            user_id,
            &store_entry,
            &mut library_entry,
        )?;

        LibraryOps::remove_from_recent(firestore, user_id, &store_entry)?;

        if delete {
            LibraryOps::remove_from_storefront_ids(firestore, user_id, &store_entry)?;
        } else {
            LibraryOps::write_failed(firestore, user_id, &store_entry)?;
        }

        Ok(())
    }

    /// Handles failed to resolve StoreEntry.
    pub fn match_failed(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: StoreEntry,
    ) -> Result<(), Status> {
        LibraryOps::delete_unmatched(firestore, user_id, &store_entry)?;
        LibraryOps::write_failed(firestore, user_id, &store_entry)?;

        Ok(())
    }
}
