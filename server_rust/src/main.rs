use server_rust::*;

const TEST_USER: &str = "testing";

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let keys = util::keys::Keys::from_file("../server/keys.json").unwrap();

    let mut igdb = igdb_service::api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;

    let mut mgr = library::manager::LibraryManager::new(TEST_USER);
    mgr.build(
        steam::api::SteamApi::new(&keys.steam.client_key, &keys.steam.user_id),
        recon::reconciler::Reconciler::new(igdb),
    )
    .await?;

    render_html(&mgr.library)?;

    Ok(())
}

use std::fs::File;
use std::io::Write;

// Basic rendering of library in HTML.
fn render_html(library: &espy::Library) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
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

    let mut output = File::create(format!("target/{}_lib.html", TEST_USER))?;
    writeln!(output, "{}", HTML_CODE)?;
    for line in lines {
        writeln!(output, "{}", line)?;
    }
    writeln!(output, "{}", HTML_TAIL)?;

    Ok(())
}
