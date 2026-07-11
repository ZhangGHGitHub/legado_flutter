use legado_engine::{db_init, db_insert_book, start_web_api, stop_web_api};

#[tokio::test]
async fn web_api_auth_and_books_roundtrip() {
    let dir = std::env::temp_dir().join(format!("legado_webapi_{}", std::process::id()));
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let _ = std::fs::remove_file(dir.join("legado.db"));
    db_init(dir.join("legado.db").to_string_lossy().to_string()).unwrap();

    let port = 19876_i32;
    let token = "test_token_123";
    let status = start_web_api(port, token.to_string())
        .await
        .expect("start web api");
    assert!(status.running);
    assert_eq!(status.port, port);

    let client = reqwest::Client::new();
    let base = format!("http://127.0.0.1:{port}");

    tokio::time::sleep(std::time::Duration::from_millis(100)).await;

    let health = client
        .get(format!("{base}/api/health"))
        .send()
        .await
        .unwrap();
    assert_eq!(health.status(), 200);

    let unauthorized = client
        .get(format!("{base}/api/books"))
        .send()
        .await
        .unwrap();
    assert_eq!(unauthorized.status(), 401);

    db_insert_book(
        r#"{"id":"wb1","name":"测试书","author":"作者","sourceUrl":"http://x"}"#.to_string(),
    )
    .unwrap();

    let books = client
        .get(format!("{base}/api/books?token={token}"))
        .send()
        .await
        .unwrap();
    assert_eq!(books.status(), 200);
    let body = books.text().await.unwrap();
    assert!(body.contains("测试书"));

    stop_web_api().await.unwrap();
}
