use std::sync::Mutex;

use axum::{
    body::Body,
    extract::{Path, State},
    http::{Request, StatusCode},
    middleware::{self, Next},
    response::{IntoResponse, Response},
    routing::{delete, get},
    Json, Router,
};
use once_cell::sync::Lazy;
use serde_json::{json, Value};
use tokio::sync::oneshot;

use crate::api::WebApiStatus;
use crate::db;

#[derive(Clone)]
struct AppState {
    token: String,
}

struct ServerHolder {
    shutdown_tx: Option<oneshot::Sender<()>>,
    port: u16,
    token: String,
}

impl Default for ServerHolder {
    fn default() -> Self {
        Self {
            shutdown_tx: None,
            port: 0,
            token: String::new(),
        }
    }
}

static SERVER: Lazy<Mutex<ServerHolder>> = Lazy::new(|| Mutex::new(ServerHolder::default()));

struct ApiError {
    status: StatusCode,
    message: String,
}

impl ApiError {
    fn internal(msg: String) -> Self {
        Self {
            status: StatusCode::INTERNAL_SERVER_ERROR,
            message: msg,
        }
    }

    fn service_unavailable(msg: impl Into<String>) -> Self {
        Self {
            status: StatusCode::SERVICE_UNAVAILABLE,
            message: msg.into(),
        }
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        (self.status, Json(json!({ "error": self.message }))).into_response()
    }
}

async fn auth_middleware(
    State(state): State<AppState>,
    req: Request<Body>,
    next: Next,
) -> Response {
    if state.token.is_empty() {
        return next.run(req).await;
    }

    let header_token = req
        .headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .map(|s| s.trim().strip_prefix("Bearer ").unwrap_or(s).to_string());

    let provided = header_token.unwrap_or_default();
    if provided == state.token {
        next.run(req).await
    } else {
        (
            StatusCode::UNAUTHORIZED,
            Json(json!({ "error": "无效 Token" })),
        )
            .into_response()
    }
}

fn build_router(state: AppState) -> Router {
    let protected = Router::new()
        .route("/books", get(list_books).post(add_book))
        .route("/books/:id", delete(delete_book))
        .route("/books/:id/chapters", get(list_chapters))
        .route("/sources", get(list_sources))
        .route("/records", get(list_records))
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            auth_middleware,
        ));

    Router::new()
        .route("/api/health", get(health))
        .nest("/api", protected)
        .with_state(state)
}

async fn health() -> Json<Value> {
    Json(json!({
        "status": "ok",
        "version": "0.5.1",
    }))
}

async fn list_books(State(_): State<AppState>) -> Result<Json<Value>, ApiError> {
    require_db()?;
    let books = db::db_get_books().map_err(ApiError::internal)?;
    let arr: Vec<Value> = books
        .iter()
        .filter_map(|s| serde_json::from_str(s).ok())
        .collect();
    Ok(Json(json!(arr)))
}

async fn add_book(
    State(_): State<AppState>,
    Json(body): Json<Value>,
) -> Result<StatusCode, ApiError> {
    require_db()?;
    db::db_insert_book(body.to_string()).map_err(ApiError::internal)?;
    Ok(StatusCode::CREATED)
}

async fn delete_book(
    State(_): State<AppState>,
    Path(id): Path<String>,
) -> Result<StatusCode, ApiError> {
    require_db()?;
    db::db_delete_book(id).map_err(ApiError::internal)?;
    Ok(StatusCode::NO_CONTENT)
}

async fn list_chapters(
    State(_): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<Value>, ApiError> {
    require_db()?;
    let chapters = db::db_get_chapters(id).map_err(ApiError::internal)?;
    let arr: Vec<Value> = chapters
        .iter()
        .filter_map(|s| serde_json::from_str(s).ok())
        .collect();
    Ok(Json(json!(arr)))
}

async fn list_sources(State(_): State<AppState>) -> Result<Json<Value>, ApiError> {
    require_db()?;
    let sources = db::db_get_sources(false).map_err(ApiError::internal)?;
    let arr: Vec<Value> = sources
        .iter()
        .filter_map(|s| serde_json::from_str(s).ok())
        .collect();
    Ok(Json(json!(arr)))
}

async fn list_records(State(_): State<AppState>) -> Result<Json<Value>, ApiError> {
    require_db()?;
    let json_str = db::db_get_reading_stats("month".to_string()).map_err(ApiError::internal)?;
    let stats: Value =
        serde_json::from_str(&json_str).map_err(|e| ApiError::internal(e.to_string()))?;
    Ok(Json(stats))
}

fn require_db() -> Result<(), ApiError> {
    if !db::is_initialized() {
        return Err(ApiError::service_unavailable("数据库未初始化"));
    }
    Ok(())
}

pub fn web_api_status() -> WebApiStatus {
    let guard = SERVER.lock().unwrap();
    let running = guard.shutdown_tx.is_some();
    let port = guard.port as i32;
    WebApiStatus {
        running,
        port,
        token: guard.token.clone(),
        base_url: if running && port > 0 {
            format!("http://127.0.0.1:{port}")
        } else {
            String::new()
        },
    }
}

pub async fn start_web_api(port: i32, token: String) -> Result<WebApiStatus, String> {
    if !(1..=65535).contains(&port) {
        return Err("端口无效".into());
    }
    let token = normalize_token(&token)?;
    stop_web_api_inner();

    let addr = format!("127.0.0.1:{port}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .map_err(|e| format!("绑定端口 {port} 失败: {e}"))?;

    let (shutdown_tx, shutdown_rx) = oneshot::channel::<()>();
    let state = AppState {
        token: token.clone(),
    };
    let app = build_router(state);

    tokio::spawn(async move {
        let _ = axum::serve(listener, app)
            .with_graceful_shutdown(async {
                shutdown_rx.await.ok();
            })
            .await;
    });

    {
        let mut guard = SERVER.lock().unwrap();
        guard.shutdown_tx = Some(shutdown_tx);
        guard.port = port as u16;
        guard.token = token;
    }

    Ok(web_api_status())
}

pub async fn stop_web_api() -> Result<(), String> {
    stop_web_api_inner();
    Ok(())
}

fn stop_web_api_inner() {
    let mut guard = SERVER.lock().unwrap();
    if let Some(tx) = guard.shutdown_tx.take() {
        let _ = tx.send(());
    }
    guard.port = 0;
    guard.token.clear();
}

fn normalize_token(token: &str) -> Result<String, String> {
    let trimmed = token.trim();
    if trimmed.is_empty() {
        Err("Token 不能为空".into())
    } else {
        Ok(trimmed.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalize_token_rejects_empty() {
        assert!(normalize_token("").is_err());
    }

    #[test]
    fn normalize_token_keeps_custom() {
        assert_eq!(normalize_token("  abc  ").unwrap(), "abc");
    }
}
