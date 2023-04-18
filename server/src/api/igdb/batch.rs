use crate::Status;
use tracing::instrument;

use super::{
    backend::post,
    docs::ExternalGame,
    resolve::{EXTERNAL_GAMES_ENDPOINT, GAMES_ENDPOINT},
    IgdbApi, IgdbGame,
};

pub struct IgdbBatchApi {
    service: IgdbApi,
}

impl IgdbBatchApi {
    pub fn new(service: IgdbApi) -> IgdbBatchApi {
        IgdbBatchApi { service }
    }

    #[instrument(level = "trace", skip(self))]
    pub async fn collect_igdb_games(&self, offset: u64) -> Result<Vec<IgdbGame>, Status> {
        let connection = self.service.connection()?;
        post::<Vec<IgdbGame>>(
            &connection,
            GAMES_ENDPOINT,
            &format!("fields *; sort first_release_date desc; where platforms = (6) & (follows > 3 | hypes > 3) & (category = 0 | category = 1 | category = 2 | category = 4 | category = 8 | category = 9); limit 500; offset {offset};"),
        )
        .await
    }

    #[instrument(level = "trace", skip(self))]
    pub async fn collect_external_games(
        &self,
        external_source: &str,
        offset: u64,
    ) -> Result<Vec<ExternalGame>, Status> {
        let category: u8 = match external_source {
            "steam" => 1,
            "gog" => 5,
            "egs" => 26,
            _ => {
                return Err(Status::invalid_argument(format!(
                    "Unrecognised source: {external_source}"
                )));
            }
        };

        let connection = self.service.connection()?;
        post::<Vec<ExternalGame>>(
            &connection,
            EXTERNAL_GAMES_ENDPOINT,
            &format!("fields *; sort uid; where category = {category} & platform.category = 6; limit 500; offset {offset};"),
        )
        .await
    }
}
