use super::charset;
use super::cookie::{source_cookie_domain as resolve_source_cookie_domain, CookieJar};
use super::network_config::{self, NetworkConfig};
use crate::model::book_source::custom_headers;
use once_cell::sync::Lazy;
use reqwest::dns::{Addrs, Name, Resolve, Resolving};
use reqwest::header::{
    HeaderMap, HeaderName, HeaderValue, ACCEPT, ACCEPT_LANGUAGE, CONTENT_TYPE, USER_AGENT,
};
use reqwest::{Client, ClientBuilder, Method, Proxy};
use serde::Serialize;
use std::collections::HashMap;
use std::future::Future;
use std::net::SocketAddr;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

static CLIENT: Lazy<Mutex<Client>> =
    Lazy::new(|| Mutex::new(build_http_client(&NetworkConfig::default())));

static COOKIE_JAR: Lazy<Mutex<CookieJar>> = Lazy::new(|| Mutex::new(CookieJar::new()));

static REQUEST_TRACE_ENABLED: AtomicBool = AtomicBool::new(false);
static REQUEST_TRACE: Lazy<Mutex<Vec<RequestTraceEvent>>> = Lazy::new(|| Mutex::new(Vec::new()));

#[derive(Debug, Clone, Serialize)]
struct RequestTraceEvent {
    method: String,
    url: String,
    status_code: u16,
    duration_ms: u64,
}

/// 开启一次诊断请求轨迹；默认关闭，避免正常运行时积累网络元数据。
pub fn start_request_trace() -> Result<(), String> {
    REQUEST_TRACE
        .lock()
        .map_err(|_| "请求轨迹锁失败".to_string())?
        .clear();
    REQUEST_TRACE_ENABLED.store(true, Ordering::Release);
    Ok(())
}

/// 停止并取出当前诊断请求轨迹，返回 JSON 供 Flutter debug 日志采样。
pub fn drain_request_trace() -> String {
    REQUEST_TRACE_ENABLED.store(false, Ordering::Release);
    let events = REQUEST_TRACE
        .lock()
        .map(|mut trace| std::mem::take(&mut *trace))
        .unwrap_or_default();
    serde_json::to_string(&events).unwrap_or_else(|_| "[]".to_string())
}

fn record_request_trace(url: &str, method: &str, status_code: u16, started: Instant) {
    if !REQUEST_TRACE_ENABLED.load(Ordering::Acquire) {
        return;
    }
    let event = RequestTraceEvent {
        method: method.to_ascii_uppercase(),
        url: trace_url(url),
        status_code,
        duration_ms: started.elapsed().as_millis() as u64,
    };
    if let Ok(mut trace) = REQUEST_TRACE.lock() {
        if trace.len() >= 512 {
            trace.remove(0);
        }
        trace.push(event);
    }
}

fn trace_url(raw: &str) -> String {
    let Ok(parsed) = url::Url::parse(raw) else {
        return raw.to_string();
    };
    let mut out = format!(
        "{}://{}{}",
        parsed.scheme(),
        parsed.host_str().unwrap_or_default(),
        parsed.path()
    );
    if let Some(query) = parsed.query() {
        out.push('?');
        out.push_str(query);
    }
    out
}

/// 单次书源响应上限，避免异常站点或错误 URL 无限占用内存。
pub(crate) const MAX_RESPONSE_BYTES: usize = 8 * 1024 * 1024;

/// 在宿主同步桥接中为单次 HTTP future 设定 deadline。
///
/// `tokio::time::timeout` 超时时会 drop 该 future，因此 reqwest 请求、响应体和
/// host permit 会在当前 runtime 中一并释放，而不是留下后台工作线程。
async fn with_host_http_deadline<T>(
    timeout: Duration,
    operation: impl Future<Output = Result<T, String>>,
) -> Result<T, String> {
    tokio::time::timeout(timeout, operation)
        .await
        .map_err(|_| format!("JS 宿主 HTTP 请求超时（超过 {} 毫秒）", timeout.as_millis()))?
}

fn build_http_client(cfg: &NetworkConfig) -> Client {
    let builder = Client::builder()
        // 网络代理只由 legado 的 NetworkConfig 控制，避免继承机器环境代理干扰离线测试。
        .no_proxy()
        .timeout(Duration::from_secs(30))
        .connect_timeout(Duration::from_secs(15))
        .redirect(reqwest::redirect::Policy::custom(|attempt| {
            if attempt.previous().len() >= 5 {
                return attempt.error("重定向次数过多");
            }
            if let Err(error) = super::ssrf::assert_public_http_url(attempt.url().as_str()) {
                return attempt.error(error);
            }
            attempt.follow()
        }));

    apply_network_proxy(builder, cfg)
        .build()
        .expect("failed to build HTTP client")
}

/// 为 QuickJS 同步宿主调用构造独立客户端。
///
/// 宿主 deadline 到达后会丢弃整个客户端和请求 future；禁用空闲连接池可确保
/// 未完成请求不会由共享客户端在后台继续持有 socket。
fn build_host_http_client(deadline: Duration) -> Result<Client, String> {
    build_host_http_client_with_builder(
        Client::builder(),
        &network_config::get_network_config(),
        deadline,
    )
}

fn build_host_http_client_with_builder(
    builder: ClientBuilder,
    cfg: &NetworkConfig,
    deadline: Duration,
) -> Result<Client, String> {
    let builder = builder
        .no_proxy()
        .timeout(deadline)
        .connect_timeout(Duration::from_secs(15).min(deadline))
        .pool_max_idle_per_host(0)
        .redirect(reqwest::redirect::Policy::custom(|attempt| {
            if attempt.previous().len() >= 5 {
                return attempt.error("重定向次数过多");
            }
            if let Err(error) = super::ssrf::assert_public_http_url(attempt.url().as_str()) {
                return attempt.error(error);
            }
            attempt.follow()
        }));
    apply_network_proxy(builder, cfg)
        .build()
        .map_err(|error| format!("创建 JS 宿主 HTTP 客户端失败: {error}"))
}

fn apply_network_proxy(mut builder: ClientBuilder, cfg: &NetworkConfig) -> ClientBuilder {
    if let Some(proxy_url) = network_config::build_proxy_url(cfg) {
        if let Ok(mut proxy) = Proxy::all(&proxy_url) {
            if !cfg.proxy_username.is_empty() {
                proxy = proxy.basic_auth(&cfg.proxy_username, &cfg.proxy_password);
            }
            builder = builder.proxy(proxy);
        }
    }
    builder
}

/// 应用网络配置后重建 HTTP 客户端
pub fn rebuild_http_client() -> Result<(), String> {
    let cfg = network_config::get_network_config();
    let client = build_http_client(&cfg);
    *CLIENT.lock().map_err(|_| "HTTP 客户端锁失败".to_string())? = client;
    Ok(())
}

/// 清空 Cookie 缓存
pub fn clear_http_cookies() -> Result<(), String> {
    *COOKIE_JAR.lock().map_err(|_| "Cookie 锁失败".to_string())? = CookieJar::new();
    Ok(())
}

fn http_client() -> Result<Client, String> {
    Ok(CLIENT
        .lock()
        .map_err(|_| "HTTP 客户端锁失败".to_string())?
        .clone())
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ApplicationNetworkPolicy {
    PublicOnly,
    LocalNetwork,
}

#[derive(Debug, Clone)]
pub struct ApplicationHttpResponse {
    pub status_code: u16,
    pub body: String,
}

#[derive(Debug, Clone)]
pub struct ApplicationBinaryHttpResponse {
    pub status_code: u16,
    pub content_type: Option<String>,
    pub body: Vec<u8>,
}

fn assert_http_url(url: &str) -> Result<(), String> {
    let parsed = url::Url::parse(url.trim()).map_err(|_| "无效的 URL".to_string())?;
    if parsed.scheme() != "http" && parsed.scheme() != "https" {
        return Err("仅允许 http/https 请求".to_string());
    }
    if parsed.host_str().is_none() {
        return Err("无效的 URL".to_string());
    }
    Ok(())
}

fn assert_application_url(url: &str, policy: ApplicationNetworkPolicy) -> Result<(), String> {
    match policy {
        ApplicationNetworkPolicy::PublicOnly => {
            // ssrf 模块为旧书源单测保留了带端口回环 fixture；应用公网策略不继承该例外。
            let parsed = url::Url::parse(url.trim()).map_err(|_| "无效的 URL".to_string())?;
            match parsed.host() {
                Some(url::Host::Ipv4(address)) => {
                    super::ssrf::assert_public_ip(std::net::IpAddr::V4(address))?
                }
                Some(url::Host::Ipv6(address)) => {
                    super::ssrf::assert_public_ip(std::net::IpAddr::V6(address))?
                }
                _ => {}
            }
            super::ssrf::assert_public_http_url(url)
        }
        ApplicationNetworkPolicy::LocalNetwork => assert_http_url(url),
    }
}

#[derive(Debug)]
struct PublicOnlyDnsResolver;

impl Resolve for PublicOnlyDnsResolver {
    fn resolve(&self, name: Name) -> Resolving {
        let host = name.as_str().to_string();
        Box::pin(async move {
            let addresses = tokio::net::lookup_host((host.as_str(), 0))
                .await
                .map_err(|error| -> Box<dyn std::error::Error + Send + Sync> { Box::new(error) })?
                .collect::<Vec<_>>();
            assert_public_dns_addresses(&host, &addresses).map_err(
                |error| -> Box<dyn std::error::Error + Send + Sync> {
                    Box::new(std::io::Error::other(error))
                },
            )?;
            Ok(Box::new(addresses.into_iter()) as Addrs)
        })
    }
}

fn assert_public_dns_addresses(host: &str, addresses: &[SocketAddr]) -> Result<(), String> {
    if addresses.is_empty() {
        return Err(format!("域名未解析到地址: {host}"));
    }
    for address in addresses {
        super::ssrf::assert_public_ip(address.ip())
            .map_err(|error| format!("域名 {host} 解析到受限地址: {error}"))?;
    }
    Ok(())
}

fn assert_application_redirect(
    url: &str,
    previous_count: usize,
    policy: ApplicationNetworkPolicy,
) -> Result<(), String> {
    if previous_count > 5 {
        return Err("重定向次数过多".to_string());
    }
    assert_application_url(url, policy)
}

fn build_application_http_client(
    cfg: &NetworkConfig,
    timeout: Duration,
    policy: ApplicationNetworkPolicy,
) -> Result<Client, String> {
    build_application_http_client_with_builder(Client::builder(), cfg, timeout, policy)
}

fn build_application_http_client_with_builder(
    builder: ClientBuilder,
    cfg: &NetworkConfig,
    timeout: Duration,
    policy: ApplicationNetworkPolicy,
) -> Result<Client, String> {
    let mut builder = builder
        // 与共享客户端一致：不继承环境代理，仅接受 NetworkConfig 的显式代理。
        .no_proxy()
        .timeout(timeout)
        .connect_timeout(Duration::from_secs(15).min(timeout))
        .redirect(reqwest::redirect::Policy::custom(move |attempt| {
            if let Err(error) = assert_application_redirect(
                attempt.url().as_str(),
                attempt.previous().len(),
                policy,
            ) {
                return attempt.error(error);
            }
            attempt.follow()
        }));

    if policy == ApplicationNetworkPolicy::PublicOnly {
        builder = builder.dns_resolver(Arc::new(PublicOnlyDnsResolver));
    }

    apply_network_proxy(builder, cfg)
        .build()
        .map_err(|error| format!("创建 HTTP 客户端失败: {error}"))
}

#[cfg(test)]
mod application_http_policy_tests {
    use super::*;
    use std::io::{Read, Write};
    use std::net::{SocketAddr, TcpListener};
    use std::thread::{self, JoinHandle};

    fn start_redirect_fixture(request_count: usize) -> (SocketAddr, JoinHandle<()>) {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let address = listener.local_addr().unwrap();
        let handle = thread::spawn(move || {
            for index in 0..request_count {
                let (mut stream, _) = listener.accept().unwrap();
                stream
                    .set_read_timeout(Some(Duration::from_secs(2)))
                    .unwrap();
                let mut request = [0_u8; 2048];
                let size = stream.read(&mut request).unwrap();
                let request = String::from_utf8_lossy(&request[..size]);
                if index == 0 {
                    assert!(request.starts_with("GET /redirect HTTP/1.1"));
                    let response = format!(
                        "HTTP/1.1 302 Found\r\nLocation: http://127.0.0.1:{}/target\r\nContent-Length: 0\r\nConnection: close\r\n\r\n",
                        address.port()
                    );
                    stream.write_all(response.as_bytes()).unwrap();
                } else {
                    assert!(request.starts_with("GET /target HTTP/1.1"));
                    stream
                        .write_all(
                            b"HTTP/1.1 200 OK\r\nContent-Length: 11\r\nConnection: close\r\n\r\nredirect-ok",
                        )
                        .unwrap();
                }
            }
        });
        (address, handle)
    }

    fn start_redirect_chain(
        redirects: usize,
        serve_terminal_response: bool,
    ) -> (SocketAddr, JoinHandle<()>) {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let address = listener.local_addr().unwrap();
        let handle = thread::spawn(move || {
            let request_count = redirects + usize::from(serve_terminal_response);
            for index in 0..request_count {
                let (mut stream, _) = listener.accept().unwrap();
                let mut request = [0_u8; 2048];
                let size = stream.read(&mut request).unwrap();
                let request = String::from_utf8_lossy(&request[..size]);
                assert!(request.starts_with(&format!("GET /{index} HTTP/1.1")));
                if index < redirects {
                    let response = format!(
                        "HTTP/1.1 302 Found\r\nLocation: /{}\r\nContent-Length: 0\r\nConnection: close\r\n\r\n",
                        index + 1
                    );
                    stream.write_all(response.as_bytes()).unwrap();
                } else {
                    stream
                        .write_all(
                            b"HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok",
                        )
                        .unwrap();
                }
            }
        });
        (address, handle)
    }

    fn redirect_client(address: SocketAddr, policy: ApplicationNetworkPolicy) -> Client {
        build_application_http_client_with_builder(
            Client::builder().resolve("public.example", address),
            &NetworkConfig::default(),
            Duration::from_secs(5),
            policy,
        )
        .unwrap()
    }

    #[tokio::test]
    async fn redirect_closure_rejects_private_target_for_public_only() {
        let (address, fixture) = start_redirect_fixture(1);
        let error = redirect_client(address, ApplicationNetworkPolicy::PublicOnly)
            .get(format!("http://public.example:{}/redirect", address.port()))
            .send()
            .await
            .unwrap_err();
        let error = format!("{error:?}");
        assert!(error.contains("SSRF"), "unexpected error: {error}");
        fixture.join().unwrap();
    }

    #[tokio::test]
    async fn redirect_closure_follows_private_target_for_local_network() {
        let (address, fixture) = start_redirect_fixture(2);
        let response = redirect_client(address, ApplicationNetworkPolicy::LocalNetwork)
            .get(format!("http://public.example:{}/redirect", address.port()))
            .send()
            .await
            .unwrap();
        assert_eq!(response.status().as_u16(), 200);
        assert_eq!(response.text().await.unwrap(), "redirect-ok");
        fixture.join().unwrap();
    }

    #[tokio::test]
    async fn redirect_client_allows_five_hops_and_rejects_sixth() {
        let (address, fixture) = start_redirect_chain(5, true);
        let response = redirect_client(address, ApplicationNetworkPolicy::LocalNetwork)
            .get(format!("http://{address}/0"))
            .send()
            .await
            .unwrap();
        assert_eq!(response.text().await.unwrap(), "ok");
        fixture.join().unwrap();

        let (address, fixture) = start_redirect_chain(6, false);
        let error = redirect_client(address, ApplicationNetworkPolicy::LocalNetwork)
            .get(format!("http://{address}/0"))
            .send()
            .await
            .unwrap_err();
        assert!(
            format!("{error:?}").contains("重定向次数过多"),
            "unexpected error: {error:?}"
        );
        fixture.join().unwrap();
    }

    #[test]
    fn redirect_policy_enforces_five_hop_limit() {
        assert!(assert_application_redirect(
            "https://example.com/next",
            5,
            ApplicationNetworkPolicy::PublicOnly,
        )
        .is_ok());
        assert_eq!(
            assert_application_redirect(
                "https://example.com/next",
                6,
                ApplicationNetworkPolicy::PublicOnly,
            )
            .unwrap_err(),
            "重定向次数过多"
        );
    }

    #[test]
    fn public_dns_rejects_private_ipv4_and_ipv6_results() {
        assert!(
            assert_public_dns_addresses("private.example", &["127.0.0.1:0".parse().unwrap()],)
                .is_err()
        );
        assert!(
            assert_public_dns_addresses("private-v6.example", &["[::1]:0".parse().unwrap()],)
                .is_err()
        );
        assert!(
            assert_public_dns_addresses("public.example", &["8.8.8.8:0".parse().unwrap()],).is_ok()
        );
    }

    #[tokio::test]
    async fn request_timeout_includes_waiting_for_host_permit() {
        let url = "http://application-permit-timeout.invalid/permit-timeout";
        let first = super::super::rate_limit::acquire_host_permit(url)
            .await
            .unwrap();
        let second = super::super::rate_limit::acquire_host_permit(url)
            .await
            .unwrap();
        let error = send_application_http_request(
            url,
            "GET",
            &HashMap::new(),
            None,
            Duration::from_millis(50),
            ApplicationNetworkPolicy::LocalNetwork,
        )
        .await
        .unwrap_err();
        assert!(error.contains("请求超时"), "unexpected error: {error}");
        drop(first);
        drop(second);
    }
}

/// 应用服务使用的通用 HTTP 请求，不把非 2xx 状态转换为传输错误。
pub async fn send_application_http_request(
    url: &str,
    method: &str,
    headers: &HashMap<String, String>,
    body: Option<&str>,
    timeout: Duration,
    policy: ApplicationNetworkPolicy,
) -> Result<ApplicationHttpResponse, String> {
    let response = send_application_binary_http_request(
        url,
        method,
        headers,
        body.map(str::as_bytes),
        timeout,
        policy,
        Some(MAX_RESPONSE_BYTES),
    )
    .await?;
    let body =
        String::from_utf8(response.body).map_err(|error| format!("响应不是 UTF-8: {error}"))?;
    Ok(ApplicationHttpResponse {
        status_code: response.status_code,
        body,
    })
}

/// 应用服务使用的二进制 HTTP 请求；`max_response_bytes = None` 保留旧调用者的无上限行为。
pub async fn send_application_binary_http_request(
    url: &str,
    method: &str,
    headers: &HashMap<String, String>,
    body: Option<&[u8]>,
    timeout: Duration,
    policy: ApplicationNetworkPolicy,
    max_response_bytes: Option<usize>,
) -> Result<ApplicationBinaryHttpResponse, String> {
    assert_application_url(url, policy)?;
    let method = method
        .trim()
        .to_ascii_uppercase()
        .parse::<Method>()
        .map_err(|_| format!("不支持的 HTTP 方法: {method}"))?;
    if method != Method::GET && method != Method::POST && method != Method::PUT {
        return Err(format!("不支持的 HTTP 方法: {method}"));
    }

    let mut request_headers = HeaderMap::new();
    for (name, value) in headers {
        let name = HeaderName::from_bytes(name.as_bytes())
            .map_err(|error| format!("无效的请求头名称 {name}: {error}"))?;
        let value = HeaderValue::from_str(value)
            .map_err(|error| format!("无效的请求头值 {}: {error}", name.as_str()))?;
        request_headers.insert(name, value);
    }

    tokio::time::timeout(timeout, async move {
        let _permit = super::rate_limit::acquire_host_permit(url).await?;
        let started = Instant::now();
        let method_name = method.as_str().to_string();
        let client =
            build_application_http_client(&network_config::get_network_config(), timeout, policy)?;
        let mut request = client.request(method, url).headers(request_headers);
        if let Some(body) = body {
            request = request.body(body.to_vec());
        }
        let response = match request.send().await {
            Ok(response) => response,
            Err(error) => {
                record_request_trace(url, &method_name, 0, started);
                return Err(format!("{method_name} 请求失败: {error:?}"));
            }
        };
        let status_code = response.status().as_u16();
        let content_type = response
            .headers()
            .get(CONTENT_TYPE)
            .and_then(|value| value.to_str().ok())
            .map(str::to_string);
        record_request_trace(url, &method_name, status_code, started);
        let body = read_response_bytes_with_limit(response, max_response_bytes).await?;
        Ok(ApplicationBinaryHttpResponse {
            status_code,
            content_type,
            body,
        })
    })
    .await
    .map_err(|_| format!("请求超时: {} ms", timeout.as_millis()))?
}

const USER_AGENT_STR: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) \
AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

const ACCEPT_STR: &str =
    "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8";

/// URL 请求配置
#[derive(Debug, Clone)]
pub struct RequestConfig {
    pub url: String,
    pub method: String,
    pub body: Option<String>,
    pub charset: String,
    pub headers: std::collections::HashMap<String, String>,
}

/// 解析 Legado ruleSearchUrl / exploreUrl 格式
pub fn parse_url_config(raw_url: &str, keyword: &str) -> RequestConfig {
    parse_url_config_with_page(raw_url, keyword, 1)
}

pub fn parse_url_config_with_page(raw_url: &str, keyword: &str, page: i32) -> RequestConfig {
    let raw = raw_url.trim();
    let mut url_part = String::new();
    let mut json_part: Option<String> = None;

    if !raw.starts_with('{') {
        if let Some(comma_idx) = raw.find(",{") {
            url_part = raw[..comma_idx].to_string();
            json_part = Some(raw[comma_idx + 1..].to_string());
        } else {
            url_part = raw.to_string();
        }
    } else {
        json_part = Some(raw.to_string());
    }

    let mut method = "GET".to_string();
    let mut charset = String::new();
    let mut body_str: Option<String> = None;
    let mut extra_headers = std::collections::HashMap::new();

    if let Some(ref jp) = json_part {
        if let Ok(cfg) = serde_json::from_str::<serde_json::Value>(jp) {
            if let Some(m) = cfg.get("method").and_then(|v| v.as_str()) {
                method = m.to_uppercase();
            }
            if let Some(c) = cfg.get("charset").and_then(|v| v.as_str()) {
                charset = c.to_uppercase();
            }
            if let Some(b) = cfg.get("body").and_then(|v| v.as_str()) {
                body_str = Some(b.to_string());
            }
            if let Some(headers) = cfg.get("headers") {
                extra_headers = parse_header_map_value(headers);
            }
        }
    }

    let encoded_key = urlencoding_encode(keyword);
    let page_str = page.to_string();
    url_part = url_part
        .replace("{{key}}", &encoded_key)
        .replace("{{page}}", &page_str)
        .replace("{{limit}}", "20");

    if let Some(ref mut body) = body_str {
        *body = body
            .replace("{{key}}", keyword)
            .replace("{{page}}", &page_str)
            .replace("{{limit}}", "20");
    }
    for value in extra_headers.values_mut() {
        *value = value
            .replace("{{key}}", keyword)
            .replace("{{page}}", &page_str)
            .replace("{{limit}}", "20");
    }

    if charset.is_empty() {
        if let Some(ref b) = body_str {
            if b.chars().any(|c| !c.is_ascii()) {
                charset = "936".to_string();
            } else {
                charset = "UTF-8".to_string();
            }
        } else {
            charset = "UTF-8".to_string();
        }
    }

    RequestConfig {
        url: url_part,
        method,
        body: body_str,
        charset,
        headers: extra_headers,
    }
}

/// 同步 HTTP（供 QuickJS `java.ajax`）— 对齐 Jingshiro `JsExtensions.ajax` → AnalyzeUrl。
///
/// 支持：
/// - 纯 URL GET
/// - `url,{"method":"POST","body":"...","charset":"...","headers":{...}}`
/// - 书源 `header` + 登录头合并
///
/// 在独立线程 + 独立 tokio Runtime 中执行，避免嵌套 `block_on` 死锁。
pub fn fetch_url_blocking(url: &str, referer: Option<&str>) -> Result<String, String> {
    ajax_blocking(url, referer, None, None)
}

/// `java.ajax` 完整路径（可带书源/登录头上下文）
pub fn ajax_blocking(
    url_raw: &str,
    referer: Option<&str>,
    source_json: Option<&str>,
    login_header: Option<&str>,
) -> Result<String, String> {
    ajax_blocking_with_deadline(
        url_raw,
        referer,
        source_json,
        login_header,
        Duration::from_secs(30),
    )
}

/// `java.ajax` 的可取消同步桥接。
///
/// 请求 future 在 deadline 到达时被取消，随后 runtime 与其工作线程退出；调用方
/// 不会带着仍在运行的 HTTP 请求继续执行。
pub fn ajax_blocking_with_deadline(
    url_raw: &str,
    referer: Option<&str>,
    source_json: Option<&str>,
    login_header: Option<&str>,
    deadline: Duration,
) -> Result<String, String> {
    let url_raw = url_raw.to_string();
    let referer = referer.map(|s| s.to_string());
    let source_json = source_json.map(|s| s.to_string());
    let login_header = login_header.map(|s| s.to_string());
    let joined = std::thread::spawn(move || {
        let client = build_host_http_client(deadline)?;
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .map_err(|e| format!("创建 java.ajax runtime 失败: {e}"))?;
        rt.block_on(async move {
            with_host_http_deadline(
                deadline,
                ajax_fetch(
                    &client,
                    &url_raw,
                    referer.as_deref(),
                    source_json.as_deref(),
                    login_header.as_deref(),
                ),
            )
            .await
        })
    })
    .join()
    .map_err(|_| "java.ajax 线程异常".to_string())?;
    joined
}

fn parse_header_map_value(v: &serde_json::Value) -> std::collections::HashMap<String, String> {
    let mut out = std::collections::HashMap::new();
    match v {
        serde_json::Value::Object(map) => {
            for (k, val) in map {
                let s = match val {
                    serde_json::Value::String(s) => s.clone(),
                    other => other.to_string(),
                };
                if !s.is_empty() {
                    out.insert(k.clone(), s);
                }
            }
        }
        serde_json::Value::String(s) => {
            if let Ok(obj) = serde_json::from_str::<serde_json::Value>(s) {
                return parse_header_map_value(&obj);
            }
        }
        _ => {}
    }
    out
}

fn login_header_map(login_header: &str) -> std::collections::HashMap<String, String> {
    let t = login_header.trim();
    if t.is_empty() {
        return std::collections::HashMap::new();
    }
    if let Ok(v) = serde_json::from_str::<serde_json::Value>(t) {
        return parse_header_map_value(&v);
    }
    // 非 JSON：当作 Cookie 字符串
    std::collections::HashMap::from([("Cookie".to_string(), t.to_string())])
}

async fn ajax_fetch(
    client: &Client,
    url_raw: &str,
    referer: Option<&str>,
    source_json: Option<&str>,
    login_header: Option<&str>,
) -> Result<String, String> {
    let raw = url_raw.trim();
    // 无 AnalyzeUrl 选项、无书源/登录头上下文时，保持历史 java.ajax 行为：
    // 纯 GET + GE-UA 重试。目录/正文 JS（如 kelexs 抽密钥）依赖这条路径。
    let is_analyze = raw.starts_with('{') || raw.contains(",{");
    if !is_analyze && source_json.is_none() && login_header.is_none() {
        let mut url = raw.to_string();
        if !url.starts_with("http://") && !url.starts_with("https://") {
            if let Some(base) = referer {
                url = resolve_url(&url, base);
            }
        }
        return fetch_text_with_client(client, &url, "GET", None, "UTF-8", referer, "").await;
    }

    let cfg = parse_url_config(raw, "");
    let mut url = cfg.url;
    if url.is_empty() {
        return Err("java.ajax URL 为空".into());
    }
    if !url.starts_with("http://") && !url.starts_with("https://") {
        if let Some(base) = referer {
            url = resolve_url(&url, base);
        } else if let Some(sj) = source_json {
            if let Ok(v) = serde_json::from_str::<serde_json::Value>(sj) {
                let base = v
                    .get("bookSourceUrl")
                    .or_else(|| v.get("sourceUrl"))
                    .and_then(|x| x.as_str())
                    .unwrap_or("");
                if !base.is_empty() {
                    url = resolve_url(&url, base);
                }
            }
        }
    }

    let mut request_headers = std::collections::HashMap::new();
    if let Some(r) = referer {
        request_headers.insert("Referer".to_string(), r.to_string());
    }
    if let Some(lh) = login_header {
        request_headers.extend(login_header_map(lh));
    }
    request_headers.extend(cfg.headers.clone());

    let headers = if let Some(sj) = source_json {
        prepare_source_headers(&url, sj, Some(&request_headers))
    } else {
        let mut h = default_headers();
        let cookie_str = COOKIE_JAR.lock().unwrap().get_cookie(&url);
        if !cookie_str.is_empty() {
            if let Ok(v) = HeaderValue::from_str(&cookie_str) {
                h.insert("Cookie", v);
            }
        }
        insert_header_map(&mut h, &request_headers);
        h
    };

    let response = send_request_with_client(
        client,
        &url,
        &cfg.method,
        cfg.body.as_deref(),
        &cfg.charset,
        headers,
    )
    .await?;
    if source_json
        .map(source_cookie_jar_enabled_json)
        .unwrap_or(true)
    {
        save_cookies(&url, &response);
    }
    let bytes = read_response_bytes(response).await?;
    let text = charset::decode_bytes(&bytes, &cfg.charset)?;
    // 对齐 fetch_text：命中 WAF 时尝试 GE-UA 后重试
    maybe_pass_ge_ua_and_retry(
        &url,
        &cfg.method,
        cfg.body.as_deref(),
        &cfg.charset,
        source_json,
        text,
    )
    .await
}

/// 按已解析的 AnalyzeUrl 配置发送请求，复用统一 TLS、Cookie、限流与 SSRF 策略。
pub async fn fetch_request_config(
    config: &RequestConfig,
    referer: Option<&str>,
) -> Result<String, String> {
    let mut headers = default_headers();
    if let Some(referer) = referer {
        if let Ok(value) = HeaderValue::from_str(referer) {
            headers.insert("Referer", value);
        }
    }

    let cookie = COOKIE_JAR.lock().unwrap().get_cookie(&config.url);
    if !cookie.is_empty() {
        if let Ok(value) = HeaderValue::from_str(&cookie) {
            headers.insert("Cookie", value);
        }
    }
    for (name, value) in &config.headers {
        if let (Ok(name), Ok(value)) = (
            HeaderName::from_bytes(name.as_bytes()),
            HeaderValue::from_str(value),
        ) {
            headers.insert(name, value);
        }
    }

    let response = send_request(
        &config.url,
        &config.method,
        config.body.as_deref(),
        &config.charset,
        headers,
    )
    .await?;
    save_cookies(&config.url, &response);
    let bytes = read_response_bytes(response).await?;
    charset::decode_bytes(&bytes, &config.charset)
}

/// 发送 HTTP 请求并返回解码文本
pub async fn fetch_text(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    referer: Option<&str>,
    _source_key: &str,
) -> Result<String, String> {
    let client = http_client()?;
    fetch_text_with_client(&client, url, method, body, charset, referer, _source_key).await
}

async fn fetch_text_with_client(
    client: &Client,
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    referer: Option<&str>,
    _source_key: &str,
) -> Result<String, String> {
    let mut headers = default_headers();
    if let Some(r) = referer {
        if let Ok(v) = HeaderValue::from_str(r) {
            headers.insert("Referer", v);
        }
    }

    let cookie_str = COOKIE_JAR.lock().unwrap().get_cookie(url);
    if !cookie_str.is_empty() {
        if let Ok(v) = HeaderValue::from_str(&cookie_str) {
            headers.insert("Cookie", v);
        }
    }

    let response = send_request_with_client(client, url, method, body, charset, headers).await?;
    save_cookies(url, &response);
    let bytes = read_response_bytes(response).await?;
    let text = charset::decode_bytes(&bytes, charset)?;
    maybe_pass_ge_ua_and_retry_with_client(client, url, method, body, charset, None, text).await
}

/// HTTP 响应元数据（调试用）
#[derive(Debug, Clone)]
pub struct FetchResponse {
    pub status_code: u16,
    pub body: String,
    pub byte_len: usize,
    /// loginCheckJs 期间 `source.putLoginHeader` 写入的最新登录头（供 Dart 回写）
    pub login_header: Option<String>,
}

fn book_source_url_from_json(source_json: &str) -> String {
    serde_json::from_str::<serde_json::Value>(source_json)
        .ok()
        .and_then(|v| {
            v.get("bookSourceUrl")
                .or_else(|| v.get("sourceUrl"))
                .and_then(|x| x.as_str())
                .map(|s| s.to_string())
        })
        .unwrap_or_default()
}

fn prepare_source_headers(
    url: &str,
    source_json: &str,
    extra_headers: Option<&std::collections::HashMap<String, String>>,
) -> HeaderMap {
    let source: serde_json::Value =
        serde_json::from_str(source_json).unwrap_or(serde_json::json!({}));
    let source_url = source
        .get("bookSourceUrl")
        .or_else(|| source.get("sourceUrl"))
        .and_then(|v| v.as_str())
        .filter(|value| !value.trim().is_empty())
        .unwrap_or(url);

    let mut headers = default_headers();
    if let Ok(v) = HeaderValue::from_str(source_url) {
        headers.insert("Referer", v);
    }

    for (k, v) in custom_headers(source_json) {
        if let (Ok(name), Ok(val)) = (
            HeaderName::from_bytes(k.as_bytes()),
            HeaderValue::from_str(&v),
        ) {
            headers.insert(name, val);
        }
    }

    // Rust 登录头缓存（loginCheckJs putLoginHeader / Dart seed）
    let key = book_source_url_from_json(source_json);
    if !key.is_empty() {
        let stored = super::login_header_store::get(&key);
        if !stored.is_empty() {
            for (k, v) in login_header_map(&stored) {
                if let (Ok(name), Ok(val)) = (
                    HeaderName::from_bytes(k.as_bytes()),
                    HeaderValue::from_str(&v),
                ) {
                    headers.insert(name, val);
                }
            }
        }
    }

    if let Some(extra_headers) = extra_headers {
        insert_header_map(&mut headers, extra_headers);
    }

    let source_cookie = COOKIE_JAR.lock().unwrap().get_cookie_for_source(source_url);
    merge_cookie_header(&mut headers, &source_cookie, false);

    if source_cookie_jar_enabled(&source) {
        let request_cookie = COOKIE_JAR.lock().unwrap().get_cookie_for_source(url);
        merge_cookie_header(&mut headers, &request_cookie, true);
    }
    headers
}

fn insert_header_map(headers: &mut HeaderMap, values: &std::collections::HashMap<String, String>) {
    for (name, value) in values {
        if let (Ok(name), Ok(value)) = (
            HeaderName::from_bytes(name.as_bytes()),
            HeaderValue::from_str(value),
        ) {
            headers.insert(name, value);
        }
    }
}

fn merge_cookie_header(headers: &mut HeaderMap, cookie: &str, cookie_overrides: bool) {
    if cookie.trim().is_empty() {
        return;
    }
    let existing = headers
        .get("Cookie")
        .and_then(|value| value.to_str().ok())
        .unwrap_or_default();
    let mut merged = parse_cookie_header(if cookie_overrides { existing } else { cookie });
    merged.extend(parse_cookie_header(if cookie_overrides {
        cookie
    } else {
        existing
    }));
    let value = format_cookie_header(&merged);
    if let Ok(value) = HeaderValue::from_str(&value) {
        headers.insert("Cookie", value);
    }
}

fn parse_cookie_header(cookie: &str) -> std::collections::HashMap<String, String> {
    cookie
        .split(';')
        .filter_map(|part| {
            let (name, value) = part.trim().split_once('=')?;
            let name = name.trim();
            (!name.is_empty()).then(|| (name.to_string(), value.trim().to_string()))
        })
        .collect()
}

fn format_cookie_header(cookies: &std::collections::HashMap<String, String>) -> String {
    let mut values: Vec<String> = cookies
        .iter()
        .map(|(name, value)| format!("{name}={value}"))
        .collect();
    values.sort();
    values.join("; ")
}

fn source_cookie_jar_enabled(source: &serde_json::Value) -> bool {
    source
        .get("enabledCookieJar")
        .and_then(serde_json::Value::as_bool)
        .unwrap_or(true)
}

fn source_cookie_jar_enabled_json(source_json: &str) -> bool {
    serde_json::from_str::<serde_json::Value>(source_json)
        .ok()
        .as_ref()
        .map(source_cookie_jar_enabled)
        .unwrap_or(true)
}

/// 用显式 header map 同步请求（loginCheckJs `java.getStrResponse`）
pub fn fetch_blocking_with_header_map(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    extra_headers: &std::collections::HashMap<String, String>,
) -> Result<(u16, String), String> {
    fetch_blocking_response_with_header_map(url, method, body, charset, extra_headers)
        .map(|(status, body, _)| (status, body))
}

/// 同步请求并保留重定向后的最终 URL（`startBrowserAwait` 返回 StrResponse 使用）。
pub fn fetch_blocking_response_with_header_map(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    extra_headers: &std::collections::HashMap<String, String>,
) -> Result<(u16, String, String), String> {
    let url = url.to_string();
    let method = method.to_string();
    let body = body.map(|s| s.to_string());
    let charset = charset.to_string();
    let extra_headers = extra_headers.clone();
    let joined = std::thread::spawn(move || {
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .map_err(|e| format!("创建 getStrResponse runtime 失败: {e}"))?;
        rt.block_on(async move {
            let mut headers = default_headers();
            for (k, v) in &extra_headers {
                if let (Ok(name), Ok(val)) = (
                    HeaderName::from_bytes(k.as_bytes()),
                    HeaderValue::from_str(v),
                ) {
                    headers.insert(name, val);
                }
            }
            let cookie_str = COOKIE_JAR.lock().unwrap().get_cookie(&url);
            if !cookie_str.is_empty() {
                if let Ok(v) = HeaderValue::from_str(&cookie_str) {
                    headers.insert("Cookie", v);
                }
            }
            let response = send_request(&url, &method, body.as_deref(), &charset, headers).await?;
            let status = response.status().as_u16();
            let final_url = response.url().to_string();
            save_cookies(&url, &response);
            let bytes = read_response_bytes(response).await?;
            let text = charset::decode_bytes(&bytes, &charset)?;
            Ok((status, text, final_url))
        })
    })
    .join()
    .map_err(|_| "getStrResponse 线程异常".to_string())?;
    joined
}

/// 从 Cookie 字符串刷新 jar（对齐 BaseSource.putLoginHeader）
pub fn replace_cookie_for_source(source_url: &str, cookie: &str) {
    if let Ok(mut jar) = COOKIE_JAR.lock() {
        let _ = jar.merge_cookie_for_source(source_url, cookie);
    }
}

/// 用扁平 Cookie 整串替换书源 eTLD+1 桶。
pub fn set_source_cookie(source_url: &str, cookie: &str) -> Result<(), String> {
    COOKIE_JAR
        .lock()
        .map_err(|_| "Cookie 锁失败".to_string())?
        .set_cookie_for_source(source_url, cookie)
}

/// 清除且仅清除目标书源 eTLD+1 Cookie 桶。
pub fn clear_source_cookie(source_url: &str) -> Result<(), String> {
    COOKIE_JAR
        .lock()
        .map_err(|_| "Cookie 锁失败".to_string())?
        .clear_cookie_for_source(source_url)
}

pub fn source_cookie_domain(source_url: &str) -> Result<String, String> {
    resolve_source_cookie_domain(source_url)
}

#[cfg(test)]
mod source_cookie_tests {
    use super::*;
    use serial_test::serial;
    use std::io::{Read, Write};
    use std::net::TcpListener;
    use std::sync::atomic::{AtomicBool, Ordering};
    use std::sync::mpsc;
    use std::sync::Arc;
    use std::thread;

    struct CancellationProbe(Arc<AtomicBool>);

    impl Drop for CancellationProbe {
        fn drop(&mut self) {
            self.0.store(true, Ordering::Release);
        }
    }

    #[tokio::test]
    async fn host_http_deadline_cancels_inflight_future() {
        let cancelled = Arc::new(AtomicBool::new(false));
        let probe = CancellationProbe(cancelled.clone());
        let result = with_host_http_deadline(Duration::from_millis(20), async move {
            let _probe = probe;
            tokio::time::sleep(Duration::from_secs(1)).await;
            Ok::<(), String>(())
        })
        .await;

        assert_eq!(result.unwrap_err(), "JS 宿主 HTTP 请求超时（超过 20 毫秒）");
        assert!(
            cancelled.load(Ordering::Acquire),
            "超时时必须 drop 请求 future，不能保留后台任务"
        );
    }

    #[test]
    fn host_http_deadline_closes_inflight_connection() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let address = listener.local_addr().unwrap();
        let (connection_closed_tx, connection_closed_rx) = mpsc::channel();
        let fixture = thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            let mut request = [0_u8; 2048];
            let size = stream.read(&mut request).unwrap();
            assert!(
                String::from_utf8_lossy(&request[..size]).starts_with("GET /slow HTTP/1.1"),
                "fixture received an unexpected request"
            );
            stream
                .set_read_timeout(Some(Duration::from_secs(2)))
                .unwrap();
            let mut probe = [0_u8; 1];
            let observed = stream.read(&mut probe);
            let closed = matches!(observed, Ok(0));
            if !closed {
                eprintln!("slow fixture connection observation: {observed:?}");
            }
            let _ = connection_closed_tx.send(closed);
        });
        let error = thread::spawn(move || {
            let runtime = tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .build()
                .unwrap();
            runtime.block_on(async move {
                with_host_http_deadline(Duration::from_millis(250), async move {
                    // Keep the client inside the deadline future, mirroring java.ajax.
                    // Timing out must drop both the request and its dedicated client.
                    let client = Client::builder()
                        .no_proxy()
                        .pool_max_idle_per_host(0)
                        .resolve("public.example", address)
                        .build()
                        .unwrap();
                    client
                        .get(format!("http://public.example:{}/slow", address.port()))
                        .timeout(Duration::from_millis(100))
                        .send()
                        .await
                        .map(|_| ())
                        .map_err(|error| format!("fixture request failed: {error}"))
                })
                .await
            })
        })
        .join()
        .unwrap()
        .unwrap_err();

        assert!(
            error.contains("fixture request failed"),
            "请求级 timeout 应在外层 deadline 前中断连接: {error}"
        );
        assert!(
            connection_closed_rx
                .recv_timeout(Duration::from_secs(3))
                .unwrap(),
            "deadline 后不得保留未关闭的 HTTP 连接"
        );
        fixture.join().unwrap();
    }

    fn cookie_header(headers: &HeaderMap) -> &str {
        headers
            .get("Cookie")
            .and_then(|value| value.to_str().ok())
            .unwrap_or_default()
    }

    #[test]
    #[serial]
    fn source_headers_reuse_login_cookie_across_request_domain() {
        clear_http_cookies().unwrap();
        set_source_cookie(
            "https://login.reader.example.co.uk/account",
            "session=source-key",
        )
        .unwrap();
        set_source_cookie(
            "https://content.unrelated.example.net",
            "session=request-domain",
        )
        .unwrap();
        let source_json = serde_json::json!({
            "bookSourceUrl": "https://www.example.co.uk/source",
            "enabledCookieJar": false
        })
        .to_string();

        let headers = prepare_source_headers(
            "https://content.unrelated.example.net/chapter/1",
            &source_json,
            None,
        );

        assert_eq!(cookie_header(&headers), "session=source-key");
        clear_http_cookies().unwrap();
    }

    #[test]
    #[serial]
    fn replace_cookie_for_source_merges_into_registrable_domain_bucket() {
        clear_http_cookies().unwrap();
        set_source_cookie("https://a.example.com", "keep=old; shared=old").unwrap();
        replace_cookie_for_source("https://b.example.com", "added=new; shared=new");
        let source_json = serde_json::json!({
            "sourceUrl": "https://reader.example.com/source"
        })
        .to_string();

        let headers = prepare_source_headers("https://api.other.net/content", &source_json, None);

        assert_eq!(cookie_header(&headers), "added=new; keep=old; shared=new");
        clear_http_cookies().unwrap();
    }

    #[test]
    #[serial]
    fn source_cookie_priority_matches_url_option_and_cookie_jar_policy() {
        clear_http_cookies().unwrap();
        super::super::login_header_store::clear();
        let source_url = "https://reader.source.example";
        set_source_cookie(source_url, "persist=1; shared=persist").unwrap();
        set_source_cookie("https://api.request.example.net", "actual=1; shared=actual").unwrap();
        super::super::login_header_store::seed(source_url, r#"{"Cookie":"login=1; shared=login"}"#);
        let extra = std::collections::HashMap::from([
            ("Cookie".to_string(), "url=1; shared=url".to_string()),
            ("X-Url-Option".to_string(), "present".to_string()),
        ]);

        let disabled = serde_json::json!({
            "bookSourceUrl": source_url,
            "enabledCookieJar": false,
            "header": {"Cookie": "source=1; shared=source"}
        })
        .to_string();
        let disabled_headers = prepare_source_headers(
            "https://api.request.example.net/content",
            &disabled,
            Some(&extra),
        );
        assert_eq!(
            cookie_header(&disabled_headers),
            "persist=1; shared=url; url=1"
        );
        assert_eq!(disabled_headers["X-Url-Option"], "present");

        let enabled = serde_json::json!({
            "bookSourceUrl": source_url,
            "enabledCookieJar": true,
            "header": {"Cookie": "source=1; shared=source"}
        })
        .to_string();
        let enabled_headers = prepare_source_headers(
            "https://api.request.example.net/content",
            &enabled,
            Some(&extra),
        );
        assert_eq!(
            cookie_header(&enabled_headers),
            "actual=1; persist=1; shared=actual; url=1"
        );

        super::super::login_header_store::clear();
        clear_http_cookies().unwrap();
    }

    fn set_cookie_fixture() -> String {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let address = listener.local_addr().unwrap();
        thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            let mut request = [0_u8; 2048];
            let _ = stream.read(&mut request);
            stream
                .write_all(
                    b"HTTP/1.1 200 OK\r\nSet-Cookie: response=stored; Max-Age=3600; Path=/\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok",
                )
                .unwrap();
        });
        format!("http://{address}/cookie")
    }

    #[tokio::test]
    #[serial]
    async fn enabled_cookie_jar_controls_response_cookie_storage() {
        clear_http_cookies().unwrap();
        let disabled_url = set_cookie_fixture();
        let disabled_source = serde_json::json!({
            "bookSourceUrl": "https://disabled.example",
            "enabledCookieJar": false
        })
        .to_string();
        assert_eq!(
            fetch_with_source(&disabled_url, "GET", None, "UTF-8", &disabled_source)
                .await
                .unwrap(),
            "ok"
        );
        assert!(COOKIE_JAR
            .lock()
            .unwrap()
            .get_cookie_for_source(&disabled_url)
            .is_empty());

        let enabled_url = set_cookie_fixture();
        let enabled_source = serde_json::json!({
            "bookSourceUrl": "https://enabled.example",
            "enabledCookieJar": true
        })
        .to_string();
        assert_eq!(
            fetch_with_source(&enabled_url, "GET", None, "UTF-8", &enabled_source)
                .await
                .unwrap(),
            "ok"
        );
        assert_eq!(
            COOKIE_JAR
                .lock()
                .unwrap()
                .get_cookie_for_source(&enabled_url),
            "response=stored"
        );
        clear_http_cookies().unwrap();
    }
}

/// 带书源自定义头发送请求
pub async fn fetch_with_source(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    source_json: &str,
) -> Result<String, String> {
    Ok(
        fetch_with_source_meta(url, method, body, charset, source_json)
            .await?
            .body,
    )
}

/// 带书源自定义头发送请求（含状态码）
///
/// 成功后若书源配置了非空 `loginCheckJs`，会对 body 执行登录检查 JS（可改写响应体）。
/// 请求失败时也会尝试执行（传入错误文本作 result）；若脚本返回可用 body 则采纳，否则仍返回原错误。
pub async fn fetch_with_source_meta(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    source_json: &str,
) -> Result<FetchResponse, String> {
    fetch_with_source_meta_and_headers(url, method, body, charset, source_json, None).await
}

/// 按 AnalyzeUrl 配置发送书源请求，URL option headers 在登录头之后覆盖。
pub async fn fetch_request_config_with_source(
    config: &RequestConfig,
    resolved_url: &str,
    source_json: &str,
) -> Result<String, String> {
    Ok(fetch_with_source_meta_and_headers(
        resolved_url,
        &config.method,
        config.body.as_deref(),
        &config.charset,
        source_json,
        Some(&config.headers),
    )
    .await?
    .body)
}

async fn fetch_with_source_meta_and_headers(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    source_json: &str,
    extra_headers: Option<&std::collections::HashMap<String, String>>,
) -> Result<FetchResponse, String> {
    let resp =
        match fetch_with_source_meta_inner(url, method, body, charset, source_json, extra_headers)
            .await
        {
            Ok(r) => r,
            Err(e) => {
                let lc = crate::rule::js_engine::apply_login_check_js_async(
                    source_json,
                    &format!("Error Response\n{e}"),
                    url,
                    method,
                    body,
                    charset,
                )
                .await;
                if !lc.body.is_empty() && !lc.body.starts_with("Error Response") {
                    return Ok(FetchResponse {
                        status_code: 200,
                        byte_len: lc.body.len(),
                        body: lc.body,
                        login_header: lc.login_header,
                    });
                }
                return Err(e);
            }
        };
    let lc = crate::rule::js_engine::apply_login_check_js_async(
        source_json,
        &resp.body,
        url,
        method,
        body,
        charset,
    )
    .await;
    let new_body = if lc.body.is_empty() {
        resp.body
    } else {
        lc.body
    };
    Ok(FetchResponse {
        status_code: resp.status_code,
        byte_len: new_body.len(),
        body: new_body,
        login_header: lc.login_header,
    })
}

async fn fetch_with_source_meta_inner(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    source_json: &str,
    extra_headers: Option<&std::collections::HashMap<String, String>>,
) -> Result<FetchResponse, String> {
    let resp =
        fetch_with_source_meta_once(url, method, body, charset, source_json, extra_headers).await?;
    if !super::ge_ua::is_challenge(&resp.body) {
        return Ok(resp);
    }

    pass_ge_ua_challenge(url, &resp.body).await?;
    let retry =
        fetch_with_source_meta_once(url, method, body, charset, source_json, extra_headers).await?;
    if super::ge_ua::is_challenge(&retry.body) {
        return Err("命中 WAF 验证页（人人书云MAX GE-UA），自动验证后仍被拦截".to_string());
    }
    Ok(retry)
}

async fn fetch_with_source_meta_once(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    source_json: &str,
    extra_headers: Option<&std::collections::HashMap<String, String>>,
) -> Result<FetchResponse, String> {
    let client = http_client()?;
    fetch_with_source_meta_once_with_client(
        &client,
        url,
        method,
        body,
        charset,
        source_json,
        extra_headers,
    )
    .await
}

async fn fetch_with_source_meta_once_with_client(
    client: &Client,
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    source_json: &str,
    extra_headers: Option<&std::collections::HashMap<String, String>>,
) -> Result<FetchResponse, String> {
    let headers = prepare_source_headers(url, source_json, extra_headers);
    let response = send_request_with_client(client, url, method, body, charset, headers).await?;
    let status_code = response.status().as_u16();
    if source_cookie_jar_enabled_json(source_json) {
        save_cookies(url, &response);
    }
    let bytes = read_response_bytes(response).await?;
    let byte_len = bytes.len();
    let body = charset::decode_bytes(&bytes, charset)?;
    Ok(FetchResponse {
        status_code,
        body,
        byte_len,
        login_header: None,
    })
}

async fn maybe_pass_ge_ua_and_retry(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    source_json: Option<&str>,
    text: String,
) -> Result<String, String> {
    let client = http_client()?;
    maybe_pass_ge_ua_and_retry_with_client(&client, url, method, body, charset, source_json, text)
        .await
}

async fn maybe_pass_ge_ua_and_retry_with_client(
    client: &Client,
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    source_json: Option<&str>,
    text: String,
) -> Result<String, String> {
    if !super::ge_ua::is_challenge(&text) {
        return Ok(text);
    }
    pass_ge_ua_challenge_with_client(client, url, &text).await?;
    let retry = if let Some(sj) = source_json {
        fetch_with_source_meta_once_with_client(client, url, method, body, charset, sj, None)
            .await?
            .body
    } else {
        let mut headers = default_headers();
        let cookie_str = COOKIE_JAR.lock().unwrap().get_cookie(url);
        if !cookie_str.is_empty() {
            if let Ok(v) = HeaderValue::from_str(&cookie_str) {
                headers.insert("Cookie", v);
            }
        }
        let response =
            send_request_with_client(client, url, method, body, charset, headers).await?;
        save_cookies(url, &response);
        let bytes = read_response_bytes(response).await?;
        charset::decode_bytes(&bytes, charset)?
    };
    if super::ge_ua::is_challenge(&retry) {
        return Err("命中 WAF 验证页（人人书云MAX GE-UA），自动验证后仍被拦截".to_string());
    }
    Ok(retry)
}

/// 完成一次 GE-UA POST 校验，写入 `ge_ua_key` 等 Cookie
async fn pass_ge_ua_challenge(url: &str, challenge_html: &str) -> Result<(), String> {
    let client = http_client()?;
    pass_ge_ua_challenge_with_client(&client, url, challenge_html).await
}

async fn pass_ge_ua_challenge_with_client(
    client: &Client,
    url: &str,
    challenge_html: &str,
) -> Result<(), String> {
    let params = super::ge_ua::parse_challenge(challenge_html)
        .ok_or_else(|| "命中 WAF 验证页，但无法解析 GE-UA 参数".to_string())?;

    let (cookie_str, sum) = {
        let jar = COOKIE_JAR.lock().map_err(|_| "Cookie 锁失败".to_string())?;
        let cookie_val = jar
            .get_cookie_value(url, &params.cpk)
            .ok_or_else(|| format!("命中 WAF 验证页，缺少 Cookie {}，无法自动验证", params.cpk))?;
        let sum = super::ge_ua::compute_sum(&cookie_val, params.nonce);
        let mut parts = vec![format!("{}={cookie_val}", params.cpk)];
        // 其余 Cookie（如 PHPSESSID）一并带上，贴近浏览器
        let all = jar.get_cookie(url);
        for part in all.split(';') {
            let part = part.trim();
            if part.is_empty() {
                continue;
            }
            if let Some((n, _)) = part.split_once('=') {
                if n.trim() != params.cpk {
                    parts.push(part.to_string());
                }
            }
        }
        (parts.join("; "), sum)
    };

    let origin = super::ge_ua::origin_of(url);
    let post_body = format!("sum={sum}&nonce={}", params.nonce);

    let mut headers = default_headers();
    headers.insert(ACCEPT, HeaderValue::from_static("*/*"));
    if let Ok(v) = HeaderValue::from_str(&origin) {
        headers.insert("Origin", v);
    }
    if let Ok(v) = HeaderValue::from_str(&format!("{origin}/")) {
        headers.insert("Referer", v);
    }
    if let Ok(v) = HeaderValue::from_str(&params.step) {
        headers.insert("X-GE-UA-Step", v);
    }
    if let Ok(v) = HeaderValue::from_str(&cookie_str) {
        headers.insert("Cookie", v);
    }

    let response =
        send_request_with_client(client, url, "POST", Some(&post_body), "UTF-8", headers).await?;
    save_cookies(url, &response);
    let bytes = read_response_bytes(response).await?;
    let text = String::from_utf8_lossy(&bytes).to_string();
    let ok =
        text.contains("\"ok\":true") || text.contains("\"ok\": true") || text.contains("'ok':true");
    if !ok {
        return Err(format!(
            "命中 WAF 验证页，自动验证未通过: {}",
            text.chars().take(120).collect::<String>()
        ));
    }
    // 浏览器脚本在成功后会等约 1s 再 reload；略等以对齐服务端放行窗口
    tokio::time::sleep(Duration::from_millis(800)).await;
    Ok(())
}

fn default_headers() -> HeaderMap {
    let mut headers = HeaderMap::new();
    headers.insert(USER_AGENT, HeaderValue::from_static(USER_AGENT_STR));
    headers.insert(ACCEPT, HeaderValue::from_static(ACCEPT_STR));
    headers.insert(
        ACCEPT_LANGUAGE,
        HeaderValue::from_static("zh-CN,zh;q=0.9,en;q=0.8"),
    );
    headers
}

async fn send_request(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    mut headers: HeaderMap,
) -> Result<reqwest::Response, String> {
    let client = http_client()?;
    send_request_with_client(&client, url, method, body, charset, headers).await
}

async fn send_request_with_client(
    client: &Client,
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    mut headers: HeaderMap,
) -> Result<reqwest::Response, String> {
    super::ssrf::assert_public_http_url(url)?;
    let _permit = super::rate_limit::acquire_host_permit(url).await?;
    let started = Instant::now();
    let request_method = if method == "POST" { "POST" } else { "GET" };
    let response = if request_method == "POST" {
        let post_body = body.unwrap_or("");
        let encoded = charset::encode_form_body(post_body, charset);
        headers.insert(
            "Content-Type",
            HeaderValue::from_static("application/x-www-form-urlencoded"),
        );
        client.post(url).headers(headers).body(encoded).send().await
    } else {
        client.get(url).headers(headers).send().await
    };
    let response = match response {
        Ok(response) => response,
        Err(error) => {
            record_request_trace(url, request_method, 0, started);
            return Err(format!("{} 请求失败: {error:?}", request_method));
        }
    };
    let status = response.status();
    record_request_trace(url, request_method, status.as_u16(), started);
    if !status.is_success() {
        return Err(format!("HTTP 请求失败: {status}"));
    }
    Ok(response)
}

async fn read_response_bytes(response: reqwest::Response) -> Result<Vec<u8>, String> {
    read_response_bytes_with_limit(response, Some(MAX_RESPONSE_BYTES)).await
}

async fn read_response_bytes_with_limit(
    mut response: reqwest::Response,
    max_response_bytes: Option<usize>,
) -> Result<Vec<u8>, String> {
    if response
        .content_length()
        .is_some_and(|size| max_response_bytes.is_some_and(|max| size > max as u64))
    {
        return Err(response_too_large_error(max_response_bytes.unwrap()));
    }
    let initial_capacity = response
        .content_length()
        .unwrap_or_default()
        .min(max_response_bytes.unwrap_or(64 * 1024) as u64)
        .min(64 * 1024) as usize;
    let mut bytes = Vec::with_capacity(initial_capacity);
    while let Some(chunk) = response
        .chunk()
        .await
        .map_err(|e| format!("读取响应失败: {e}"))?
    {
        if max_response_bytes.is_some_and(|max| bytes.len().saturating_add(chunk.len()) > max) {
            return Err(response_too_large_error(max_response_bytes.unwrap()));
        }
        bytes.extend_from_slice(&chunk);
    }
    Ok(bytes)
}

fn response_too_large_error(max_response_bytes: usize) -> String {
    if max_response_bytes % (1024 * 1024) == 0 {
        format!("响应过大: 超过 {} MiB", max_response_bytes / (1024 * 1024))
    } else {
        format!("响应过大: 超过 {max_response_bytes} 字节")
    }
}

fn save_cookies(url: &str, response: &reqwest::Response) {
    let set_cookies: Vec<String> = response
        .headers()
        .get_all("set-cookie")
        .iter()
        .filter_map(|v| v.to_str().ok().map(|s| s.to_string()))
        .collect();
    if !set_cookies.is_empty() {
        COOKIE_JAR
            .lock()
            .unwrap()
            .save_from_headers(url, &set_cookies);
    }
}

pub fn resolve_url(url: &str, base_url: &str) -> String {
    let url = url.trim();
    if url.is_empty() {
        return String::new();
    }
    // 协议相对 URL：//cdn.example.com/a.jpg → https://cdn.example.com/a.jpg
    if url.starts_with("//") {
        if let Ok(base) = url::Url::parse(base_url) {
            return format!("{}:{}", base.scheme(), url);
        }
        return format!("https:{url}");
    }
    if url.starts_with("http://") || url.starts_with("https://") {
        return url.to_string();
    }
    if let Ok(base) = url::Url::parse(base_url) {
        if let Ok(joined) = base.join(url) {
            return joined.into();
        }
    }
    let base = base_url.trim_end_matches('/');
    if url.starts_with('/') {
        format!("{base}{url}")
    } else {
        format!("{base}/{url}")
    }
}

pub fn base_url(url: &str) -> String {
    if let Ok(parsed) = url::Url::parse(url) {
        let origin = parsed.origin().ascii_serialization();
        if !origin.is_empty() {
            return origin;
        }
    }
    url.trim_end_matches('/').to_string()
}

fn urlencoding_encode(s: &str) -> String {
    s.chars()
        .map(|c| {
            if c.is_ascii_alphanumeric() || "-_.~".contains(c) {
                c.to_string()
            } else {
                let mut buf = [0u8; 4];
                let encoded = c.encode_utf8(&mut buf);
                encoded
                    .bytes()
                    .map(|b| format!("%{b:02X}"))
                    .collect::<String>()
            }
        })
        .collect::<String>()
}
