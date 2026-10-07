use std::{error::Error, time::Duration};

use axum::{
    Json, Router,
    extract::{Path, State},
    http::StatusCode,
    routing::get,
};
use reqwest::Client;
use serde_json::{Value, json};

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let client = Client::builder().timeout(Duration::from_secs(15)).build()?;

    let app = Router::new()
        .route("/health", get(|| async { "ok - layer reuse test" }))
        .route("/pokemon/{name}", get(pokemon))
        .with_state(client);
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await?;
    eprintln!("listening on 0.0.0.0:3000");
    axum::serve(listener, app)
        .with_graceful_shutdown(async {
            let _ = tokio::signal::ctrl_c().await;
        })
        .await?;
    Ok(())
}

async fn pokemon(
    State(client): State<Client>,
    Path(name): Path<String>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    if name.is_empty()
        || !name
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || byte == b'-')
    {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({ "error": "use a pokemon name or numeric ID" })),
        ));
    }

    let result = async {
        client
            .get(format!("https://pokeapi.co/api/v2/pokemon/{name}/"))
            .send()
            .await?
            .error_for_status()?
            .json::<Value>()
            .await
    }
    .await;

    result.map(Json).map_err(|error| {
        eprintln!("PokéAPI request failed: {error:?}");
        (
            StatusCode::BAD_GATEWAY,
            Json(json!({ "error": format!("{error:?}") })),
        )
    })
}
