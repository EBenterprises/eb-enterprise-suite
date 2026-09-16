use axum::{
    response::{Html, IntoResponse},
    routing::get,
    Router,
};

async fn serve_ui() -> impl IntoResponse {
    Html(include_str!("../../../static/index.html"))
}

pub fn routes() -> Router {
    Router::new().route("/", get(serve_ui))
}
