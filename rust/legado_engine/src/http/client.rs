use super::charset;
use super::cookie::CookieJar;
use super::network_config::{self, NetworkConfig};
use crate::model::book_source::custom_headers;
use once_cell::sync::Lazy;
use reqwest::header::{HeaderMap, HeaderName, HeaderValue, ACCEPT, ACCEPT_LANGUAGE, USER_AGENT};
use reqwest::{Client, Proxy};
use std::sync::Mutex;
use std::time::Duration;

static CLIENT: Lazy<Mutex<Client>> = Lazy::new(|| Mutex::new(build_http_client(&NetworkConfig::default())));

static COOKIE_JAR: Lazy<Mutex<CookieJar>> = Lazy::new(|| Mutex::new(CookieJar::new()));

fn build_http_client(cfg: &NetworkConfig) -> Client {
    let mut builder = Client::builder()
        .timeout(Duration::from_secs(30))
        .connect_timeout(Duration::from_secs(15))
        .redirect(reqwest::redirect::Policy::limited(5))
        .danger_accept_invalid_certs(true);

    if let Some(proxy_url) = network_config::build_proxy_url(cfg) {
        if let Ok(mut proxy) = Proxy::all(&proxy_url) {
            if !cfg.proxy_username.is_empty() {
                proxy = proxy.basic_auth(&cfg.proxy_username, &cfg.proxy_password);
            }
            builder = builder.proxy(proxy);
        }
    }

    builder.build().expect("failed to build HTTP client")
}

/// 应用网络配置后重建 HTTP 客户端
pub fn rebuild_http_client() -> Result<(), String> {
    let cfg = network_config::get_network_config();
    let client = build_http_client(&cfg);
    *CLIENT
        .lock()
        .map_err(|_| "HTTP 客户端锁失败".to_string())? = client;
    Ok(())
}

/// 清空 Cookie 缓存
pub fn clear_http_cookies() -> Result<(), String> {
    *COOKIE_JAR
        .lock()
        .map_err(|_| "Cookie 锁失败".to_string())? = CookieJar::new();
    Ok(())
}

fn http_client() -> Result<Client, String> {
    Ok(CLIENT
        .lock()
        .map_err(|_| "HTTP 客户端锁失败".to_string())?
        .clone())
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
        if let Some(comma_idx) = raw.find(',') {
            if raw[comma_idx + 1..].starts_with('{') {
                url_part = raw[..comma_idx].to_string();
                json_part = Some(raw[comma_idx + 1..].to_string());
            } else {
                url_part = raw.to_string();
            }
        } else {
            url_part = raw.to_string();
        }
    } else {
        json_part = Some(raw.to_string());
    }

    let mut method = "GET".to_string();
    let mut charset = String::new();
    let mut body_str: Option<String> = None;

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
    let url_raw = url_raw.to_string();
    let referer = referer.map(|s| s.to_string());
    let source_json = source_json.map(|s| s.to_string());
    let login_header = login_header.map(|s| s.to_string());
    let joined = std::thread::spawn(move || {
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .map_err(|e| format!("创建 java.ajax runtime 失败: {e}"))?;
        rt.block_on(async move {
            ajax_fetch(
                &url_raw,
                referer.as_deref(),
                source_json.as_deref(),
                login_header.as_deref(),
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

/// 解析 AnalyzeUrl JSON 段中的 headers
fn analyze_url_extra_headers(raw: &str) -> std::collections::HashMap<String, String> {
    let raw = raw.trim();
    let json_part = if raw.starts_with('{') {
        Some(raw)
    } else if let Some(idx) = raw.find(",{") {
        Some(&raw[idx + 1..])
    } else {
        None
    };
    let Some(jp) = json_part else {
        return std::collections::HashMap::new();
    };
    let Ok(cfg) = serde_json::from_str::<serde_json::Value>(jp) else {
        return std::collections::HashMap::new();
    };
    cfg.get("headers")
        .map(parse_header_map_value)
        .unwrap_or_default()
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
        return fetch_text(&url, "GET", None, "UTF-8", referer, "").await;
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

    let mut headers = if let Some(sj) = source_json {
        build_source_headers(&url, sj)
    } else {
        let mut h = default_headers();
        let cookie_str = COOKIE_JAR.lock().unwrap().get_cookie(&url);
        if !cookie_str.is_empty() {
            if let Ok(v) = HeaderValue::from_str(&cookie_str) {
                h.insert("Cookie", v);
            }
        }
        h
    };

    if let Some(r) = referer {
        if let Ok(v) = HeaderValue::from_str(r) {
            headers.insert("Referer", v);
        }
    }

    for (k, v) in analyze_url_extra_headers(raw) {
        if let (Ok(name), Ok(val)) = (
            HeaderName::from_bytes(k.as_bytes()),
            HeaderValue::from_str(&v),
        ) {
            headers.insert(name, val);
        }
    }

    if let Some(lh) = login_header {
        for (k, v) in login_header_map(lh) {
            if let (Ok(name), Ok(val)) = (
                HeaderName::from_bytes(k.as_bytes()),
                HeaderValue::from_str(&v),
            ) {
                headers.insert(name, val);
            }
        }
    }

    let response = send_request(
        &url,
        &cfg.method,
        cfg.body.as_deref(),
        &cfg.charset,
        headers,
    )
    .await?;
    save_cookies(&url, &response);
    let bytes = response
        .bytes()
        .await
        .map_err(|e| format!("读取响应失败: {e}"))?;
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

/// 发送 HTTP 请求并返回解码文本
pub async fn fetch_text(
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

    let response = send_request(url, method, body, charset, headers).await?;
    save_cookies(url, &response);
    let bytes = response
        .bytes()
        .await
        .map_err(|e| format!("读取响应失败: {e}"))?;
    let text = charset::decode_bytes(&bytes, charset)?;
    maybe_pass_ge_ua_and_retry(url, method, body, charset, None, text).await
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

fn build_source_headers(url: &str, source_json: &str) -> HeaderMap {
    let source: serde_json::Value =
        serde_json::from_str(source_json).unwrap_or(serde_json::json!({}));
    let source_url = source
        .get("bookSourceUrl")
        .and_then(|v| v.as_str())
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

    let cookie_str = COOKIE_JAR.lock().unwrap().get_cookie(url);
    if !cookie_str.is_empty() {
        if let Ok(v) = HeaderValue::from_str(&cookie_str) {
            headers.insert("Cookie", v);
        }
    }
    headers
}

/// 用显式 header map 同步请求（loginCheckJs `java.getStrResponse`）
pub fn fetch_blocking_with_header_map(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    extra_headers: &std::collections::HashMap<String, String>,
) -> Result<(u16, String), String> {
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
            let response =
                send_request(&url, &method, body.as_deref(), &charset, headers).await?;
            let status = response.status().as_u16();
            save_cookies(&url, &response);
            let bytes = response
                .bytes()
                .await
                .map_err(|e| format!("读取响应失败: {e}"))?;
            let text = charset::decode_bytes(&bytes, &charset)?;
            Ok((status, text))
        })
    })
    .join()
    .map_err(|_| "getStrResponse 线程异常".to_string())?;
    joined
}

/// 从 Cookie 字符串刷新 jar（对齐 BaseSource.putLoginHeader）
pub fn replace_cookie_for_source(source_url: &str, cookie: &str) {
    let cookie = cookie.trim();
    if cookie.is_empty() || source_url.trim().is_empty() {
        return;
    }
    let set_cookies: Vec<String> = cookie
        .split(';')
        .map(|p| p.trim())
        .filter(|p| !p.is_empty() && p.contains('='))
        .map(|p| format!("{p}; Path=/"))
        .collect();
    if set_cookies.is_empty() {
        return;
    }
    if let Ok(mut jar) = COOKIE_JAR.lock() {
        jar.save_from_headers(source_url, &set_cookies);
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
    Ok(fetch_with_source_meta(url, method, body, charset, source_json)
        .await?
        .body)
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
    let resp = match fetch_with_source_meta_inner(url, method, body, charset, source_json).await {
        Ok(r) => r,
        Err(e) => {
            let lc = crate::rule::js_engine::apply_login_check_js(
                source_json,
                &format!("Error Response\n{e}"),
                url,
                method,
                body,
                charset,
            );
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
    let lc = crate::rule::js_engine::apply_login_check_js(
        source_json,
        &resp.body,
        url,
        method,
        body,
        charset,
    );
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
) -> Result<FetchResponse, String> {
    let resp = fetch_with_source_meta_once(url, method, body, charset, source_json).await?;
    if !super::ge_ua::is_challenge(&resp.body) {
        return Ok(resp);
    }

    pass_ge_ua_challenge(url, &resp.body).await?;
    let retry = fetch_with_source_meta_once(url, method, body, charset, source_json).await?;
    if super::ge_ua::is_challenge(&retry.body) {
        return Err(
            "命中 WAF 验证页（人人书云MAX GE-UA），自动验证后仍被拦截".to_string(),
        );
    }
    Ok(retry)
}

async fn fetch_with_source_meta_once(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    source_json: &str,
) -> Result<FetchResponse, String> {
    let headers = build_source_headers(url, source_json);
    let response = send_request(url, method, body, charset, headers).await?;
    let status_code = response.status().as_u16();
    save_cookies(url, &response);
    let bytes = response
        .bytes()
        .await
        .map_err(|e| format!("读取响应失败: {e}"))?;
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
    if !super::ge_ua::is_challenge(&text) {
        return Ok(text);
    }
    pass_ge_ua_challenge(url, &text).await?;
    let retry = if let Some(sj) = source_json {
        fetch_with_source_meta_once(url, method, body, charset, sj)
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
        let response = send_request(url, method, body, charset, headers).await?;
        save_cookies(url, &response);
        let bytes = response
            .bytes()
            .await
            .map_err(|e| format!("读取响应失败: {e}"))?;
        charset::decode_bytes(&bytes, charset)?
    };
    if super::ge_ua::is_challenge(&retry) {
        return Err(
            "命中 WAF 验证页（人人书云MAX GE-UA），自动验证后仍被拦截".to_string(),
        );
    }
    Ok(retry)
}

/// 完成一次 GE-UA POST 校验，写入 `ge_ua_key` 等 Cookie
async fn pass_ge_ua_challenge(url: &str, challenge_html: &str) -> Result<(), String> {
    let params = super::ge_ua::parse_challenge(challenge_html)
        .ok_or_else(|| "命中 WAF 验证页，但无法解析 GE-UA 参数".to_string())?;

    let (cookie_str, sum) = {
        let jar = COOKIE_JAR.lock().map_err(|_| "Cookie 锁失败".to_string())?;
        let cookie_val = jar.get_cookie_value(url, &params.cpk).ok_or_else(|| {
            format!(
                "命中 WAF 验证页，缺少 Cookie {}，无法自动验证",
                params.cpk
            )
        })?;
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

    let response = send_request(url, "POST", Some(&post_body), "UTF-8", headers).await?;
    save_cookies(url, &response);
    let bytes = response
        .bytes()
        .await
        .map_err(|e| format!("读取 WAF 验证响应失败: {e}"))?;
    let text = String::from_utf8_lossy(&bytes).to_string();
    let ok = text.contains("\"ok\":true")
        || text.contains("\"ok\": true")
        || text.contains("'ok':true");
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
    super::ssrf::assert_public_http_url(url)?;
    let _permit = super::rate_limit::acquire_host_permit(url).await?;
    if method == "POST" {
        let post_body = body.unwrap_or("");
        let encoded = charset::encode_form_body(post_body, charset);
        headers.insert(
            "Content-Type",
            HeaderValue::from_static("application/x-www-form-urlencoded"),
        );
        http_client()?
            .post(url)
            .headers(headers)
            .body(encoded)
            .send()
            .await
            .map_err(|e| format!("POST 请求失败: {e}"))
    } else {
        http_client()?
            .get(url)
            .headers(headers)
            .send()
            .await
            .map_err(|e| format!("GET 请求失败: {e}"))
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
