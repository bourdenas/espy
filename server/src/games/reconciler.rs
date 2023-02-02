use crate::{
    api::IgdbApi,
    documents::{GameEntry, StoreEntry},
    Status,
};
use tracing::{debug, instrument};

pub struct Reconciler;

impl Reconciler {
    /// Attempts to reconcile a `StoreEntry` with an IGDB game.
    ///
    /// It initially tries to use the external game table for finding the
    /// corresponding entry. If that fails it performs a search by title and
    /// matches with the best candidate.
    ///
    /// The returned GameEntry is a shallow entry (single IGDB lookup). If
    /// `use_base_game` is `true`, the entry returned is the base game instead
    /// of the exact match, e.g. remastered version or expansion / DLC.
    #[instrument(level = "trace", skip(igdb))]
    pub async fn recon(
        igdb: &IgdbApi,
        store_entry: &StoreEntry,
        use_base_game: bool,
    ) -> Result<Option<GameEntry>, Status> {
        let game_entry = match match_by_external_id(igdb, store_entry).await? {
            Some(game_entry) => Some(game_entry),
            None => match match_by_title(igdb, &store_entry.title).await? {
                Some(game_entry) => Some(game_entry),
                None => None,
            },
        };

        match use_base_game {
            true => base_game(igdb, game_entry).await,
            false => Ok(game_entry),
        }
    }
}

async fn base_game(
    igdb: &IgdbApi,
    game_entry: Option<GameEntry>,
) -> Result<Option<GameEntry>, Status> {
    match game_entry {
        Some(game_entry) => match game_entry.parent {
            Some(id) => igdb.get(id).await,
            None => Ok(Some(game_entry)),
        },
        None => Ok(None),
    }
}

/// Returns a `GameEntry` from IGDB matching the external storefront id in
/// `store_entry`.
async fn match_by_external_id(
    igdb: &IgdbApi,
    store_entry: &StoreEntry,
) -> Result<Option<GameEntry>, Status> {
    debug!("Resolving '{}'", &store_entry.title);

    match store_entry.id.is_empty() {
        true => Ok(None),
        false => igdb.get_by_store_entry(store_entry).await,
    }
}

/// Returns a `GameEntry` from IGDB matching the `title`.
async fn match_by_title(igdb: &IgdbApi, title: &str) -> Result<Option<GameEntry>, Status> {
    debug!("Searching '{}'", title);

    let candidates = igdb.search_by_title(title).await?;
    match candidates.into_iter().next() {
        Some(game_entry) => Ok(Some(game_entry)),
        None => Ok(None),
    }
}
