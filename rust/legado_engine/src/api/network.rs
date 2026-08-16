use super::AppError;
use crate::http::client;
use crate::http::network_config::{self, NetworkConfig};
use crate::rule::js_engine;
use std::collections::HashMap;
use std::time::Duration;

/// 网络配置 DTO
#[derive(Debug, Clone)]
pub struct NetworkConfigDto {
    pub proxy_enabled: bool,
    pub proxy_type: String,
    pub proxy_host: String,
    pub proxy_port: i32,
    pub proxy_username: String,
    pub proxy_password: String,
    pub dns_servers: String,
}

#[derive(Debug, Clone)]
pub struct ApplicationHttpResponseDto {
    pub status_code: i32,
    pub body: String,
}

#[derive(Debug, Clone)]
pub struct ApplicationBinaryHttpResponseDto {
    pub status_code: i32,
    pub content_type: String,
    pub body: Vec<u8>,
}

/// 应用代理 / DNS 配置
#[flutter_rust_bridge::frb(sync)]
pub fn set_network_config(
    proxy_enabled: bool,
    proxy_type: String,
    proxy_host: String,
    proxy_port: i32,
    proxy_username: String,
    proxy_password: String,
    dns_servers: String,
) -> Result<(), AppError> {
    network_config::set_network_config(NetworkConfig {
        proxy_enabled,
        proxy_type,
        proxy_host,
        proxy_port: proxy_port.max(0) as u16,
        proxy_username,
        proxy_password,
        dns_servers,
    })
    .map_err(AppError::Validation)
}

/// 清空 HTTP Cookie 与 JS 内存缓存
#[flutter_rust_bridge::frb(sync)]
pub fn clear_engine_cache() -> Result<(), AppError> {
    client::clear_http_cookies().map_err(AppError::Unknown)?;
    js_engine::reset_cache().map_err(AppError::JsExecution)?;
    Ok(())
}

/// 用扁平 Cookie 整串替换书源 eTLD+1 Cookie 桶；空串等价于清除。
#[flutter_rust_bridge::frb(sync)]
pub fn set_source_cookie(source_url: String, cookie: String) -> Result<(), AppError> {
    client::set_source_cookie(&source_url, &cookie).map_err(AppError::Validation)
}

/// 清除且仅清除目标书源 eTLD+1 Cookie 桶。
#[flutter_rust_bridge::frb(sync)]
pub fn clear_source_cookie(source_url: String) -> Result<(), AppError> {
    client::clear_source_cookie(&source_url).map_err(AppError::Validation)
}

/// 返回书源 Cookie 桶使用的 eTLD+1；IP 保持自身。
#[flutter_rust_bridge::frb(sync)]
pub fn source_cookie_domain(source_url: String) -> Result<String, AppError> {
    client::source_cookie_domain(&source_url).map_err(AppError::Validation)
}

/// 开启一次 debug HTTP 请求轨迹采集。
#[flutter_rust_bridge::frb(sync)]
pub fn start_http_request_trace() -> Result<(), AppError> {
    client::start_request_trace().map_err(AppError::Unknown)
}

/// 停止并取出 debug HTTP 请求轨迹 JSON。
#[flutter_rust_bridge::frb(sync)]
pub fn drain_http_request_trace() -> String {
    client::drain_request_trace()
}

/// 当前网络配置
#[flutter_rust_bridge::frb(sync)]
pub fn get_network_config() -> NetworkConfigDto {
    let cfg = network_config::get_network_config();
    NetworkConfigDto {
        proxy_enabled: cfg.proxy_enabled,
        proxy_type: cfg.proxy_type,
        proxy_host: cfg.proxy_host,
        proxy_port: cfg.proxy_port as i32,
        proxy_username: cfg.proxy_username,
        proxy_password: cfg.proxy_password,
        dns_servers: cfg.dns_servers,
    }
}

/// 通过统一 Rust HTTP 客户端抓取公开文本资源。
///
/// `user_agent` 为空时使用引擎默认值；传入 `null` 对齐规则订阅
/// `#requestWithoutUA` 的既有请求语义。
pub async fn fetch_public_text(url: String, user_agent: String) -> Result<String, AppError> {
    let source_json = if user_agent.is_empty() {
        serde_json::json!({ "bookSourceUrl": url }).to_string()
    } else {
        serde_json::json!({
            "bookSourceUrl": url,
            "header": { "User-Agent": user_agent }
        })
        .to_string()
    };
    client::fetch_with_source(&url, "GET", None, "UTF-8", &source_json)
        .await
        .map_err(AppError::Network)
}

fn map_application_http_error(message: String) -> AppError {
    if message.starts_with("响应不是 UTF-8:") {
        AppError::Parse(message)
    } else {
        AppError::Network(message)
    }
}

/// 发送应用服务 HTTP 请求。`allow_private_network` 仅供用户显式配置的本地服务使用。
#[flutter_rust_bridge::frb]
pub async fn send_application_http_request(
    url: String,
    method: String,
    headers: HashMap<String, String>,
    body: Option<String>,
    timeout_seconds: i32,
    allow_private_network: bool,
) -> Result<ApplicationHttpResponseDto, AppError> {
    if timeout_seconds <= 0 {
        return Err(AppError::Validation("请求超时秒数必须大于 0".to_string()));
    }
    let policy = if allow_private_network {
        client::ApplicationNetworkPolicy::LocalNetwork
    } else {
        client::ApplicationNetworkPolicy::PublicOnly
    };
    let response = client::send_application_http_request(
        &url,
        &method,
        &headers,
        body.as_deref(),
        Duration::from_secs(timeout_seconds as u64),
        policy,
    )
    .await
    .map_err(map_application_http_error)?;
    Ok(ApplicationHttpResponseDto {
        status_code: i32::from(response.status_code),
        body: response.body,
    })
}

/// 发送应用服务二进制 HTTP 请求。`max_response_bytes = 0` 表示保持调用者原有的无上限行为。
#[flutter_rust_bridge::frb]
pub async fn send_application_binary_http_request(
    url: String,
    method: String,
    headers: HashMap<String, String>,
    body: Option<Vec<u8>>,
    timeout_seconds: i32,
    allow_private_network: bool,
    max_response_bytes: i32,
) -> Result<ApplicationBinaryHttpResponseDto, AppError> {
    if timeout_seconds <= 0 {
        return Err(AppError::Validation("请求超时秒数必须大于 0".to_string()));
    }
    if max_response_bytes < 0 {
        return Err(AppError::Validation("最大响应字节数不能小于 0".to_string()));
    }
    let policy = if allow_private_network {
        client::ApplicationNetworkPolicy::LocalNetwork
    } else {
        client::ApplicationNetworkPolicy::PublicOnly
    };
    let response = client::send_application_binary_http_request(
        &url,
        &method,
        &headers,
        body.as_deref(),
        Duration::from_secs(timeout_seconds as u64),
        policy,
        (max_response_bytes > 0).then_some(max_response_bytes as usize),
    )
    .await
    .map_err(AppError::Network)?;
    Ok(ApplicationBinaryHttpResponseDto {
        status_code: i32::from(response.status_code),
        content_type: response.content_type.unwrap_or_default(),
        body: response.body,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::{Read, Write};
    use std::net::TcpListener;
    use std::sync::{Arc, Mutex};
    use std::thread;

    fn start_fixture(status: u16, body: &'static str) -> (String, Arc<Mutex<String>>) {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let address = listener.local_addr().unwrap();
        let captured = Arc::new(Mutex::new(String::new()));
        let request = Arc::clone(&captured);
        thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            stream
                .set_read_timeout(Some(Duration::from_secs(2)))
                .unwrap();
            let mut bytes = Vec::new();
            let mut buffer = [0_u8; 4096];
            loop {
                let size = stream.read(&mut buffer).unwrap_or_default();
                if size == 0 {
                    break;
                }
                bytes.extend_from_slice(&buffer[..size]);
                let headers_end = bytes
                    .windows(4)
                    .position(|window| window == b"\r\n\r\n")
                    .map(|position| position + 4);
                let Some(headers_end) = headers_end else {
                    continue;
                };
                let headers = String::from_utf8_lossy(&bytes[..headers_end]);
                let content_length = headers
                    .lines()
                    .find_map(|line| {
                        line.split_once(':').and_then(|(name, value)| {
                            name.eq_ignore_ascii_case("content-length")
                                .then(|| value.trim().parse::<usize>().ok())
                                .flatten()
                        })
                    })
                    .unwrap_or(0);
                if bytes.len() >= headers_end + content_length {
                    break;
                }
            }
            *request.lock().unwrap() = String::from_utf8_lossy(&bytes).to_string();
            let response = format!(
                "HTTP/1.1 {status} Fixture\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                body.len()
            );
            stream.write_all(response.as_bytes()).unwrap();
        });
        (format!("http://{address}"), captured)
    }

    async fn request_fixture(
        url: String,
        method: &str,
        headers: HashMap<String, String>,
        body: Option<&str>,
    ) -> ApplicationHttpResponseDto {
        send_application_http_request(
            url,
            method.to_string(),
            headers,
            body.map(str::to_string),
            5,
            true,
        )
        .await
        .unwrap()
    }

    #[tokio::test]
    async fn supports_get_post_put_headers_raw_body_and_non_success_status() {
        for (method, request_body, status, response_body) in [
            ("GET", None, 200, "get"),
            ("POST", Some(r#"{"prompt":"测试"}"#), 201, "post"),
            ("PUT", Some("raw=body"), 409, "put-conflict"),
        ] {
            let (base, captured) = start_fixture(status, response_body);
            let response = request_fixture(
                format!("{base}/api"),
                method,
                HashMap::from([("X-Application-Test".to_string(), method.to_string())]),
                request_body,
            )
            .await;

            assert_eq!(response.status_code, i32::from(status));
            assert_eq!(response.body, response_body);
            let captured = captured.lock().unwrap();
            assert!(captured.starts_with(&format!("{method} /api HTTP/1.1")));
            assert!(captured.to_ascii_lowercase().contains(&format!(
                "x-application-test: {}",
                method.to_ascii_lowercase()
            )));
            if let Some(body) = request_body {
                assert!(captured.ends_with(body));
            }
        }
    }

    #[tokio::test]
    async fn public_only_rejects_localhost_and_local_network_allows_loopback() {
        let error = send_application_http_request(
            "http://localhost:4567/private".to_string(),
            "GET".to_string(),
            HashMap::new(),
            None,
            5,
            false,
        )
        .await
        .unwrap_err();
        assert!(
            matches!(error, AppError::Network(ref message) if message.contains("SSRF")),
            "unexpected error: {error}"
        );

        let (base, _) = start_fixture(200, "local-ok");
        let response =
            request_fixture(format!("{base}/private"), "GET", HashMap::new(), None).await;
        assert_eq!(response.body, "local-ok");
    }

    #[tokio::test]
    async fn rejects_response_larger_than_eight_mib() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let address = listener.local_addr().unwrap();
        thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            let mut request = [0_u8; 1024];
            let _ = stream.read(&mut request);
            let response = format!(
                "HTTP/1.1 200 OK\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
                client::MAX_RESPONSE_BYTES + 1
            );
            stream.write_all(response.as_bytes()).unwrap();
        });

        let error = send_application_http_request(
            format!("http://{address}/large"),
            "GET".to_string(),
            HashMap::new(),
            None,
            5,
            true,
        )
        .await
        .unwrap_err();
        assert!(
            matches!(error, AppError::Network(ref message) if message.contains("响应过大")),
            "unexpected error: {error}"
        );
    }

    #[tokio::test]
    async fn rejects_streamed_response_without_content_length_over_eight_mib() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let address = listener.local_addr().unwrap();
        thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            let mut request = [0_u8; 1024];
            let _ = stream.read(&mut request);
            stream
                .write_all(b"HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n")
                .unwrap();
            let chunk = [b'x'; 64 * 1024];
            for _ in 0..=client::MAX_RESPONSE_BYTES / chunk.len() {
                if stream.write_all(&chunk).is_err() {
                    break;
                }
            }
        });

        let error = send_application_http_request(
            format!("http://{address}/streamed-large"),
            "GET".to_string(),
            HashMap::new(),
            None,
            5,
            true,
        )
        .await
        .unwrap_err();
        assert!(
            matches!(error, AppError::Network(ref message) if message.contains("响应过大")),
            "unexpected error: {error}"
        );
    }

    #[tokio::test]
    async fn binary_request_preserves_bytes_content_type_and_non_success_status() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let address = listener.local_addr().unwrap();
        thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            let mut request = [0_u8; 2048];
            let size = stream.read(&mut request).unwrap();
            assert!(request[..size].ends_with(&[0, 127, 255]));
            stream
                .write_all(
                    b"HTTP/1.1 409 Conflict\r\nContent-Type: application/octet-stream\r\nContent-Length: 3\r\nConnection: close\r\n\r\n\x00\x80\xff",
                )
                .unwrap();
        });

        let response = send_application_binary_http_request(
            format!("http://{address}/binary"),
            "POST".to_string(),
            HashMap::from([(
                "Content-Type".to_string(),
                "application/octet-stream".to_string(),
            )]),
            Some(vec![0, 127, 255]),
            5,
            true,
            1024,
        )
        .await
        .unwrap();
        assert_eq!(response.status_code, 409);
        assert_eq!(response.content_type, "application/octet-stream");
        assert_eq!(response.body, vec![0, 128, 255]);
    }

    #[tokio::test]
    async fn application_http_input_errors_are_validation_errors() {
        let error = send_application_http_request(
            "http://localhost:4567/validation".to_string(),
            "GET".to_string(),
            HashMap::new(),
            None,
            0,
            true,
        )
        .await
        .unwrap_err();
        assert!(matches!(
            error,
            AppError::Validation(ref message) if message == "请求超时秒数必须大于 0"
        ));

        let error = send_application_binary_http_request(
            "http://localhost:4567/validation".to_string(),
            "GET".to_string(),
            HashMap::new(),
            None,
            5,
            true,
            -1,
        )
        .await
        .unwrap_err();
        assert!(matches!(
            error,
            AppError::Validation(ref message) if message == "最大响应字节数不能小于 0"
        ));
    }

    #[tokio::test]
    async fn public_text_http_errors_are_network_errors_with_original_text() {
        let error = fetch_public_text("file:///private".to_string(), String::new())
            .await
            .unwrap_err();
        assert!(matches!(
            error,
            AppError::Network(ref message) if message == "仅允许 http/https 请求"
        ));
    }

    #[test]
    fn application_text_decode_errors_are_parse_errors_with_original_text() {
        let message = "响应不是 UTF-8: invalid byte".to_string();
        let error = map_application_http_error(message.clone());
        assert!(matches!(error, AppError::Parse(ref value) if value == &message));
    }

    #[test]
    fn source_cookie_domain_uses_public_suffix_and_keeps_ip() {
        assert_eq!(
            source_cookie_domain("https://login.reader.example.co.uk/a".to_string()).unwrap(),
            "example.co.uk"
        );
        assert_eq!(
            source_cookie_domain("http://127.0.0.1:8080/a".to_string()).unwrap(),
            "127.0.0.1"
        );
        let error = source_cookie_domain("not-a-url".to_string()).unwrap_err();
        assert!(matches!(
            error,
            AppError::Validation(ref message) if message == "无效的书源 URL"
        ));
    }
}
