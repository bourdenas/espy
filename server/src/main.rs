use clap::Clap;
use espy_server::*;
use prost::Message;
use std::sync::Arc;

/// Espy server util for testing functionality of the backend.
#[derive(Clap)]
struct Opts {
    /// Search for a game in IGDB by title.
    #[clap(short, long)]
    search: Option<String>,
    /// If set to true, it tries to connect to a local gRPC server for
    /// retrieving the library.
    #[clap(long)]
    over_grpc: bool,
    /// If set to true, it tries to connect to a local HTTP server for
    /// retrieving the library.
    #[clap(long)]
    over_http: bool,
    /// Port number of the gRPC server to connect to if --over_grpc is true.
    #[clap(long, default_value = "6235")]
    grpc_port: u16,
    /// Espy user name for managing a game library.
    #[clap(short, long, default_value = "testing")]
    user: String,
    /// JSON file that contains application keys for espy service.
    #[clap(long, default_value = "keys.json")]
    key_store: String,
    /// Steam user id used for building the library. If set, it overrides the
    /// user id stored in --key_store JSON file.
    #[clap(long)]
    steam_user: Option<String>,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let opts: Opts = Opts::parse();

    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = igdb_service::api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;

    if let Some(title) = &opts.search {
        let candidates = recon::reconciler::get_candidates(&igdb, title).await?;
        for candidate in candidates {
            println!("{}", candidate);
        }
        return Ok(());
    } else if opts.over_grpc {
        let mut client =
            espy::espy_client::EspyClient::connect(format!("http://[::1]:{}", opts.grpc_port))
                .await?;

        let response = client
            .get_library(tonic::Request::new(espy::LibraryRequest {
                user_id: opts.user.clone(),
            }))
            .await?;
        println!(
            "User has {} entries.",
            response.get_ref().library.as_ref().unwrap().entry.len()
        );
        render_html(&opts.user, response.get_ref().library.as_ref().unwrap())?;
        return Ok(());
    } else if opts.over_http {
        let uri = format!("http://127.0.0.1:3030/library/{}", &opts.user);
        let bytes = reqwest::Client::new()
            .get(&uri)
            .send()
            .await?
            .bytes()
            .await?;
        let library = espy::Library::decode(bytes)?;
        println!("User has {} entries.", library.entry.len());
        render_html(&opts.user, &library)?;
        return Ok(());
    }

    let mut mgr = library::manager::LibraryManager::new(
        &opts.user,
        recon::reconciler::Reconciler::new(Arc::new(igdb)),
    );
    mgr.build(Some(steam::api::SteamApi::new(
        &keys.steam.client_key,
        match &opts.steam_user {
            Some(user_id) => user_id,
            None => &keys.steam.user_id,
        },
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
