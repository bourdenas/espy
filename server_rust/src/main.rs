use clap::Clap;
use server_rust::*;

/// Espy server util for testing functionality of the backend.
#[derive(Clap)]
struct Opts {
    /// Search for a game in IGDB by title.
    #[clap(short, long)]
    search: Option<String>,
    /// Espy user name for managing a game library.
    #[clap(short, long, default_value = "testing")]
    user: String,
    /// JSON file that contains application keys for espy service.
    #[clap(long, default_value = "../server/keys.json")]
    key_store: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let opts: Opts = Opts::parse();

    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = igdb_service::api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;

    if let Some(title) = &opts.search {
        let result = igdb.search_by_title(title).await?;
        println!("{:?}", result);
        return Ok(());
    }

    let mut mgr =
        library::manager::LibraryManager::new(&opts.user, recon::reconciler::Reconciler::new(igdb));
    mgr.build(Some(steam::api::SteamApi::new(
        &keys.steam.client_key,
        &keys.steam.user_id,
    )))
    .await?;

    render_html(&opts.user, &mgr.library)?;

    Ok(())
}

use std::fs::File;
use std::io::Write;

// Basic rendering of library in HTML.
fn render_html(
    user: &str,
    library: &espy::Library,
) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    const HTML_CODE: &str = r#"
    <html>
    <head>
      <style>
        .app {
          display: grid;
          grid-gap: 15px;
          overflow: hidden;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          grid-auto-flow: dense;
        }
      </style>
    </head>
    <body>
      <div class="app">"#;
    const HTML_TAIL: &str = r#"
      </div>
    </body>
    </html>"#;

    let lines = library.entry.iter().map(|e| match &e.game {
        Some(game) => format!(
            r#"<div class="item"><figure><p>
                    <img src="https://images.igdb.com/igdb/image/upload/t_cover_big/{}.jpg">
                    <figcaption><a href="{}">{}</a></figcaption></figure></div>"#,
            match &game.cover {
                Some(cover) => &cover.image_id,
                None => "",
            },
            game.url,
            game.name
        ),
        None => String::from(""),
    });

    let mut output = File::create(format!("target/{}_lib.html", user))?;
    writeln!(output, "{}", HTML_CODE)?;
    for line in lines {
        writeln!(output, "{}", line)?;
    }
    writeln!(output, "{}", HTML_TAIL)?;

    Ok(())
}
