use crate::{
    documents::{
        Collection, CollectionType, Company, CompanyRole, GameDigest, GameEntry, Image, Website,
        WebsiteAuthority,
    },
    Status,
};
use async_recursion::async_recursion;
use std::sync::Arc;
use tracing::instrument;

use super::{backend::post, docs, IgdbConnection, IgdbGame};

/// Returns an IgdbGame doc from IGDB for given game `id`.
///
/// Does not perform any lookups on tables beyond Game.
#[instrument(level = "trace", skip(connection))]
pub async fn get_game(connection: &IgdbConnection, id: u64) -> Result<IgdbGame, Status> {
    let result: Vec<IgdbGame> = post(
        connection,
        GAMES_ENDPOINT,
        &format!("fields *; where id={id};"),
    )
    .await?;

    match result.into_iter().next() {
        Some(igdb_game) => Ok(igdb_game),
        None => Err(Status::not_found(format!(
            "Failed to retrieve game with id={id}"
        ))),
    }
}

/// Returns a GameEntry from IGDB that can build the GameDigest doc.
#[instrument(
    level = "trace",
    skip(connection, igdb_game)
    fields(
        game_id = %igdb_game.id,
        game_name = %igdb_game.name,
    )
)]
pub async fn resolve_game_digest(
    connection: Arc<IgdbConnection>,
    igdb_game: &IgdbGame,
) -> Result<GameEntry, Status> {
    let mut game_entry = GameEntry::from(igdb_game);

    if let Some(cover) = igdb_game.cover {
        game_entry.cover = get_cover(&connection, cover).await?;
    }

    if !igdb_game.genres.is_empty() {
        game_entry.genres = get_genres(&connection, &igdb_game.genres).await?;
    }
    if !igdb_game.keywords.is_empty() {
        game_entry.keywords = get_keywords(&connection, &igdb_game.keywords).await?;
    }

    if let Some(collection) = igdb_game.collection {
        if let Some(collection) = get_collection(&connection, collection).await? {
            game_entry.collections = vec![collection];
        }
    }
    if !igdb_game.franchises.is_empty() {
        game_entry
            .collections
            .extend(get_franchises(&connection, &igdb_game.franchises).await?);
    }

    if !igdb_game.involved_companies.is_empty() {
        let companies = get_companies(&connection, &igdb_game.involved_companies).await?;
        game_entry.developers = companies
            .iter()
            .filter(|company| match company.role {
                CompanyRole::Developer => true,
                _ => false,
            })
            // NOTE: drain_filter() would prevent the cloning.
            .map(|company| company.clone())
            .collect();
        game_entry.publishers = companies
            .into_iter()
            .filter(|company| match company.role {
                CompanyRole::Publisher => true,
                _ => false,
            })
            .collect();
    }

    Ok(game_entry)
}

/// Returns a fully resolved GameEntry from IGDB that goes beyond the GameDigest doc.
#[async_recursion]
#[instrument(
    level = "trace",
    skip(connection, igdb_game, game_entry),
    fields(
        game_id = %igdb_game.id,
        game_name = %igdb_game.name,
    )
)]
pub async fn resolve_game_info(
    connection: Arc<IgdbConnection>,
    igdb_game: IgdbGame,
    game_entry: &mut GameEntry,
) -> Result<(), Status> {
    if !igdb_game.screenshots.is_empty() {
        game_entry.screenshots = get_screenshots(&connection, &igdb_game.screenshots).await?;
    }
    if !igdb_game.artworks.is_empty() {
        game_entry.artwork = get_artwork(&connection, &igdb_game.artworks).await?;
    }
    if igdb_game.websites.len() > 0 {
        game_entry.websites.extend(
            get_websites(&connection, &igdb_game.websites)
                .await?
                .into_iter()
                .map(|website| Website {
                    url: website.url,
                    authority: match website.category {
                        1 => WebsiteAuthority::Official,
                        3 => WebsiteAuthority::Wikipedia,
                        9 => WebsiteAuthority::Youtube,
                        13 => WebsiteAuthority::Steam,
                        16 => WebsiteAuthority::Egs,
                        17 => WebsiteAuthority::Gog,
                        _ => WebsiteAuthority::Null,
                    },
                }),
        );
    }

    let parent_id = match igdb_game.parent_game {
        Some(parent) => Some(parent),
        None => match igdb_game.version_parent {
            Some(parent) => Some(parent),
            None => None,
        },
    };

    if let Some(parent_id) = parent_id {
        let parent = resolve_game_digest(
            Arc::clone(&connection),
            &get_game(&connection, parent_id).await?,
        )
        .await?;
        game_entry.parent = Some(GameDigest::new(parent));
    }

    for expansion_id in igdb_game.expansions.into_iter() {
        let expansion = resolve_game_digest(
            Arc::clone(&connection),
            &get_game(&connection, expansion_id).await?,
        )
        .await?;
        game_entry.expansions.push(GameDigest::new(expansion));
    }
    for dlc_id in igdb_game.dlcs.into_iter() {
        let dlc = resolve_game_digest(
            Arc::clone(&connection),
            &get_game(&connection, dlc_id).await?,
        )
        .await?;
        game_entry.dlcs.push(GameDigest::new(dlc));
    }
    for remake_id in igdb_game.remakes.into_iter() {
        let remake = resolve_game_digest(
            Arc::clone(&connection),
            &get_game(&connection, remake_id).await?,
        )
        .await?;
        game_entry.remakes.push(GameDigest::new(remake));
    }
    for remaster_id in igdb_game.remasters.into_iter() {
        let remaster = resolve_game_digest(
            Arc::clone(&connection),
            &get_game(&connection, remaster_id).await?,
        )
        .await?;
        game_entry.remasters.push(GameDigest::new(remaster));
    }

    Ok(())
}

/// Returns game image cover based on id from the igdb/covers endpoint.
#[instrument(level = "trace", skip(connection))]
pub async fn get_cover(connection: &IgdbConnection, id: u64) -> Result<Option<Image>, Status> {
    let result: Vec<Image> = post(
        connection,
        COVERS_ENDPOINT,
        &format!("fields *; where id={id};"),
    )
    .await?;

    Ok(result.into_iter().next())
}

/// Returns game image cover based on id from the igdb/covers endpoint.
#[instrument(level = "trace", skip(connection))]
async fn get_company_logo(connection: &IgdbConnection, id: u64) -> Result<Option<Image>, Status> {
    let result: Vec<Image> = post(
        connection,
        COMPANY_LOGOS_ENDPOINT,
        &format!("fields *; where id={id};"),
    )
    .await?;

    Ok(result.into_iter().next())
}

/// Returns game genres based on id from the igdb/genres endpoint.
#[instrument(level = "trace", skip(connection))]
async fn get_genres(connection: &IgdbConnection, ids: &[u64]) -> Result<Vec<String>, Status> {
    Ok(post::<Vec<docs::Annotation>>(
        connection,
        GENRES_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<String>>()
                .join(",")
        ),
    )
    .await?
    .into_iter()
    .map(|genre| genre.name)
    .collect())
}

/// Returns game keywords based on id from the igdb/keywords endpoint.
#[instrument(level = "trace", skip(connection))]
async fn get_keywords(connection: &IgdbConnection, ids: &[u64]) -> Result<Vec<String>, Status> {
    Ok(post::<Vec<docs::Annotation>>(
        connection,
        KEYWORDS_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<String>>()
                .join(",")
        ),
    )
    .await?
    .into_iter()
    .map(|genre| genre.name)
    .collect())
}

/// Returns game screenshots based on id from the igdb/screenshots endpoint.
#[instrument(level = "trace", skip(connection))]
async fn get_artwork(connection: &IgdbConnection, ids: &[u64]) -> Result<Vec<Image>, Status> {
    Ok(post(
        connection,
        ARTWORKS_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<String>>()
                .join(",")
        ),
    )
    .await?)
}

/// Returns game screenshots based on id from the igdb/screenshots endpoint.
#[instrument(level = "trace", skip(connection))]
async fn get_screenshots(connection: &IgdbConnection, ids: &[u64]) -> Result<Vec<Image>, Status> {
    Ok(post(
        &connection,
        SCREENSHOTS_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<String>>()
                .join(",")
        ),
    )
    .await?)
}

/// Returns game websites based on id from the igdb/websites endpoint.
#[instrument(level = "trace", skip(connection))]
async fn get_websites(
    connection: &IgdbConnection,
    ids: &[u64],
) -> Result<Vec<docs::Website>, Status> {
    Ok(post(
        &connection,
        WEBSITES_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<String>>()
                .join(",")
        ),
    )
    .await?)
}

/// Returns game collection based on id from the igdb/collections endpoint.
#[instrument(level = "trace", skip(connection))]
async fn get_collection(
    connection: &IgdbConnection,
    id: u64,
) -> Result<Option<Collection>, Status> {
    let result: Vec<docs::Collection> = post(
        &connection,
        COLLECTIONS_ENDPOINT,
        &format!("fields *; where id={id};"),
    )
    .await?;

    match result.into_iter().next() {
        Some(collection) => Ok(Some(Collection {
            id: collection.id,
            name: collection.name,
            slug: collection.slug,
            igdb_type: CollectionType::Collection,
        })),
        None => Ok(None),
    }
}

/// Returns game franchices based on id from the igdb/frachises endpoint.
#[instrument(level = "trace", skip(connection))]
async fn get_franchises(
    connection: &IgdbConnection,
    ids: &[u64],
) -> Result<Vec<Collection>, Status> {
    let result: Vec<docs::Collection> = post(
        &connection,
        FRANCHISES_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<String>>()
                .join(",")
        ),
    )
    .await?;

    Ok(result
        .into_iter()
        .map(|collection| Collection {
            id: collection.id,
            name: collection.name,
            slug: collection.slug,
            igdb_type: CollectionType::Franchise,
        })
        .collect())
}

/// Returns game companies involved in the making of the game.
#[instrument(level = "trace", skip(connection))]
async fn get_companies(connection: &IgdbConnection, ids: &[u64]) -> Result<Vec<Company>, Status> {
    // Collect all involved companies for a game entry.
    let involved_companies: Vec<docs::InvolvedCompany> = post(
        &connection,
        INVOLVED_COMPANIES_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            ids.iter()
                .map(|id| id.to_string())
                .collect::<Vec<_>>()
                .join(",")
        ),
    )
    .await?;

    // Collect company data for involved companies.
    let igdb_companies = post::<Vec<docs::Company>>(
        &connection,
        COMPANIES_ENDPOINT,
        &format!(
            "fields *; where id = ({});",
            involved_companies
                .iter()
                .map(|ic| match &ic.company {
                    Some(c) => c.to_string(),
                    None => "".to_string(),
                })
                .collect::<Vec<_>>()
                .join(",")
        ),
    )
    .await?;

    let mut companies = vec![];
    for company in igdb_companies {
        if company.name.is_empty() {
            continue;
        }

        let ic = involved_companies
            .iter()
            .filter(|ic| ic.company.is_some())
            .find(|ic| ic.company.unwrap() == company.id)
            .expect("Failed to find company in involved companies.");

        companies.push(Company {
            id: company.id,
            name: company.name,
            slug: company.slug,
            role: match ic.developer {
                true => CompanyRole::Developer,
                false => match ic.publisher {
                    true => CompanyRole::Publisher,
                    false => match ic.porting {
                        true => CompanyRole::Porting,
                        false => match ic.supporting {
                            true => CompanyRole::Support,
                            false => CompanyRole::Unknown,
                        },
                    },
                },
            },
            logo: match company.logo {
                Some(logo) => get_company_logo(&connection, logo).await?,
                None => None,
            },
        });
    }

    Ok(companies)
}

pub const GAMES_ENDPOINT: &str = "games";
pub const EXTERNAL_GAMES_ENDPOINT: &str = "external_games";
const COVERS_ENDPOINT: &str = "covers";
const COMPANY_LOGOS_ENDPOINT: &str = "company_logos";
const FRANCHISES_ENDPOINT: &str = "franchises";
const COLLECTIONS_ENDPOINT: &str = "collections";
const ARTWORKS_ENDPOINT: &str = "artworks";
const GENRES_ENDPOINT: &str = "genres";
const KEYWORDS_ENDPOINT: &str = "keywords";
const SCREENSHOTS_ENDPOINT: &str = "screenshots";
const WEBSITES_ENDPOINT: &str = "websites";
const COMPANIES_ENDPOINT: &str = "companies";
const INVOLVED_COMPANIES_ENDPOINT: &str = "involved_companies";
