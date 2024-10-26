use axum::{extract::Path, routing::get, Router};
use std::env::var;


const COWSAY: &str = env!("COWSAY");

#[tokio::main]
async fn main() {
    // build our application with a single route
    let app = Router::new()
        .route("/", get(|| async { "yo" }))
        .route("/add/:a/:b", get(|Path((a, b)): Path<(usize, usize)>| async move { (a + b).to_string() }))
        // .route("/add/:a/:b", get(|Path((a, b)): Path<(String, String)>| async move { dbg!(a, b); "".to_string() }))
        .route("/mult/:a/:b", get(|Path((a, b)): Path<(usize, usize)>| async move { (a * b).to_string() }))
        .route("/cowsay/:msg", get(|Path(msg): Path<String>| async {
            let output = std::process::Command::new(COWSAY)
                .arg(msg)
                .output()
                .expect("uhhh");

            String::from_utf8(output.stdout).unwrap()
        }))
        .route("/uuid", get(|| async { uuid::Uuid::new_v4().to_string() }))
    ;

    // run our app with hyper, listening globally on port 3000
    let listener = tokio::net::TcpListener::bind(
        format!("0.0.0.0:{}", var("PORT").unwrap()),
    ).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
