use super::charset;
use super::cookie::CookieJar;
use crate::model::book_source::custom_headers;
use once_cell::sync::Lazy;
use reqwest::blocking::Client;
use reqwest::header::{HeaderMap, HeaderName, HeaderValue, ACCEPT, ACCEPT_LANGUAGE, USER_AGENT};
use std::sync::Mutex;
use std::time::Duration;

static CLIENT: Lazy<Client> = Lazy::new(|| {
    Client::builder()
        .timeout(Duration::from_secs(30))
        .connect_timeout(Duration::from_secs(15))
        .redirect(reqwest::redirect::Policy::limited(5))
        .danger_accept_invalid_certs(true)
        .build()
        .expect("failed to build HTTP client")
});

static COOKIE_JAR: Lazy<Mutex<CookieJar>> = Lazy::new(|| Mutex::new(CookieJar::new()));

const USER_AGENT_STR: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) \
AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

/// URL 请求配置
#[derive(Debug, Clone)]
pub struct RequestConfig {
    pub url: String,
    pub method: String,
    pub body: Option<String>,
    pub charset: String,
}

/// 解析 Legado ruleSearchUrl 格式
pub fn parse_url_config(raw_url: &str, keyword: &str) -> RequestConfig {
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
    url_part = url_part
        .replace("{{key}}", &encoded_key)
        .replace("{{page}}", "1")
        .replace("{{limit}}", "20");

    if let Some(ref mut body) = body_str {
        *body = body
            .replace("{{key}}", keyword)
            .replace("{{page}}", "1")
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

/// 发送 HTTP 请求并返回解码文本
pub fn fetch_text(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    referer: Option<&str>,
    _source_key: &str,
) -> Result<String, String> {
    let mut headers = HeaderMap::new();
    headers.insert(USER_AGENT, HeaderValue::from_static(USER_AGENT_STR));
    headers.insert(
        ACCEPT,
        HeaderValue::from_static("application/json, text/plain, */*"),
    );
    headers.insert(
        ACCEPT_LANGUAGE,
        HeaderValue::from_static("zh-CN,zh;q=0.9,en;q=0.8"),
    );

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

    let response = if method == "POST" {
        let post_body = body.unwrap_or("");
        let encoded = charset::encode_form_body(post_body, charset);
        headers.insert(
            "Content-Type",
            HeaderValue::from_static("application/x-www-form-urlencoded"),
        );
        CLIENT
            .post(url)
            .headers(headers)
            .body(encoded)
            .send()
            .map_err(|e| format!("POST 请求失败: {e}"))?
    } else {
        CLIENT
            .get(url)
            .headers(headers)
            .send()
            .map_err(|e| format!("GET 请求失败: {e}"))?
    };

    let set_cookies: Vec<String> = response
        .headers()
        .get_all("set-cookie")
        .iter()
        .filter_map(|v| v.to_str().ok().map(|s| s.to_string()))
        .collect();
    if !set_cookies.is_empty() {
        COOKIE_JAR.lock().unwrap().save_from_headers(url, &set_cookies);
    }

    let bytes = response
        .bytes()
        .map_err(|e| format!("读取响应失败: {e}"))?;
    charset::decode_bytes(&bytes, charset)
}

/// 带书源自定义头发送请求
pub fn fetch_with_source(
    url: &str,
    method: &str,
    body: Option<&str>,
    charset: &str,
    source_json: &str,
) -> Result<String, String> {
    let source: serde_json::Value =
        serde_json::from_str(source_json).unwrap_or(serde_json::json!({}));
    let source_url = source
        .get("bookSourceUrl")
        .and_then(|v| v.as_str())
        .unwrap_or(url);

    let mut headers = HeaderMap::new();
    headers.insert(USER_AGENT, HeaderValue::from_static(USER_AGENT_STR));
    headers.insert(
        ACCEPT,
        HeaderValue::from_static("application/json, text/plain, */*"),
    );
    headers.insert(
        ACCEPT_LANGUAGE,
        HeaderValue::from_static("zh-CN,zh;q=0.9,en;q=0.8"),
    );
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

    let cookie_str = COOKIE_JAR.lock().unwrap().get_cookie(url);
    if !cookie_str.is_empty() {
        if let Ok(v) = HeaderValue::from_str(&cookie_str) {
            headers.insert("Cookie", v);
        }
    }

    let response = if method == "POST" {
        let post_body = body.unwrap_or("");
        let encoded = charset::encode_form_body(post_body, charset);
        headers.insert(
            "Content-Type",
            HeaderValue::from_static("application/x-www-form-urlencoded"),
        );
        CLIENT
            .post(url)
            .headers(headers)
            .body(encoded)
            .send()
            .map_err(|e| format!("POST 请求失败: {e}"))?
    } else {
        CLIENT
            .get(url)
            .headers(headers)
            .send()
            .map_err(|e| format!("GET 请求失败: {e}"))?
    };

    let set_cookies: Vec<String> = response
        .headers()
        .get_all("set-cookie")
        .iter()
        .filter_map(|v| v.to_str().ok().map(|s| s.to_string()))
        .collect();
    if !set_cookies.is_empty() {
        COOKIE_JAR.lock().unwrap().save_from_headers(url, &set_cookies);
    }

    let bytes = response
        .bytes()
        .map_err(|e| format!("读取响应失败: {e}"))?;
    charset::decode_bytes(&bytes, charset)
}

pub fn resolve_url(url: &str, base_url: &str) -> String {
    if url.starts_with("http") {
        return url.to_string();
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
