use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use http_body_util::BodyExt;
use tower::ServiceExt;
use crypto_service::server::app_router;
use serde_json::json;

#[tokio::test]
async fn test_encrypt_decrypt_workflow() {
    let app = app_router();

    let payload = json!({
        "key": "0123456789abcdef0123456789abcdef",
        "iv": "1234567890abcdef",
        "payload": "Secret production data"
    });

    let req = Request::builder()
        .method("POST")
        .uri("/encrypt")
        .header("content-type", "application/json")
        .body(Body::from(payload.to_string()))
        .unwrap();

    let res = app.clone().oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);

    let body = res.into_body().collect().await.unwrap().to_bytes();
    let v: serde_json::Value = serde_json::from_slice(&body).unwrap();
    let ciphertext = v["result"].as_str().unwrap().to_string();
    assert!(!ciphertext.is_empty());

    let decrypt_payload = json!({
        "key": "0123456789abcdef0123456789abcdef",
        "iv": "1234567890abcdef",
        "payload": ciphertext
    });

    let req_dec = Request::builder()
        .method("POST")
        .uri("/decrypt")
        .header("content-type", "application/json")
        .body(Body::from(decrypt_payload.to_string()))
        .unwrap();

    let res_dec = app.oneshot(req_dec).await.unwrap();
    assert_eq!(res_dec.status(), StatusCode::OK);

    let body_dec = res_dec.into_body().collect().await.unwrap().to_bytes();
    let v_dec: serde_json::Value = serde_json::from_slice(&body_dec).unwrap();
    assert_eq!(v_dec["result"].as_str().unwrap(), "Secret production data");
}
