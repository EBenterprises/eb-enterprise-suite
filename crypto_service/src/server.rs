use axum::Router;
use crate::modules::crypto::api::routes as crypto_routes;
use crate::modules::ui::api::routes as ui_routes;

pub fn app_router() -> Router {
    Router::new()
        .merge(crypto_routes())
        .merge(ui_routes())
}
