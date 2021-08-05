use crate::documents::StoreEntry;
use crate::Status;
use async_trait::async_trait;

#[async_trait]
pub trait Storefront {
    // Returns the list of games owned by the user in the Storefront.
    async fn get_owned_games(&self) -> Result<Vec<StoreEntry>, Status>;
}
