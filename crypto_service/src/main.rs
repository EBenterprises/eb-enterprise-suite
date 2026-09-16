use crypto_service::server::app_router;

#[tokio::main]
async fn main() {
    let app = app_router();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:8080").await.unwrap();
    println!("Crypto service API listening dynamically on http://127.0.0.1:8080");
    axum::serve(listener, app).await.unwrap();
}
