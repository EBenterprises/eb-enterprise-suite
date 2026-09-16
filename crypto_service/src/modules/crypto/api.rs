use axum::{
    routing::post,
    extract::Json,
    http::StatusCode,
    Router,
};
use serde::{Deserialize, Serialize};
use crate::modules::crypto::engine::{encrypt_payload, decrypt_payload};
use crate::modules::telemetry::logger::log_event;

#[derive(Deserialize)]
pub struct CryptoRequest {
    pub key: String,
    pub iv: String,
    pub payload: String,
}

#[derive(Serialize)]
pub struct CryptoResponse {
    pub result: String,
}

async fn handle_encrypt(Json(payload): Json<CryptoRequest>) -> Result<Json<CryptoResponse>, StatusCode> {
    log_event("INFO", "Executing encryption module workflow");
    let key = payload.key.as_bytes();
    let iv = payload.iv.as_bytes();
    let text = payload.payload.as_bytes();

    match encrypt_payload(key, iv, text) {
        Ok(res) => Ok(Json(CryptoResponse { result: res })),
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

async fn handle_decrypt(Json(payload): Json<CryptoRequest>) -> Result<Json<CryptoResponse>, StatusCode> {
    log_event("INFO", "Executing decryption module workflow");
    let key = payload.key.as_bytes();
    let iv = payload.iv.as_bytes();

    match decrypt_payload(key, iv, &payload.payload) {
        Ok(res) => {
            let decoded = String::from_utf8(res).unwrap_or_else(|_| "Invalid UTF8".to_string());
            Ok(Json(CryptoResponse { result: decoded }))
        }
        Err(_) => Err(StatusCode::BAD_REQUEST),
    }
}

pub fn routes() -> Router {
    Router::new()
        .route("/encrypt", post(handle_encrypt))
        .route("/decrypt", post(handle_decrypt))
}
