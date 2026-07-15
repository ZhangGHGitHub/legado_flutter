//! 人人书云MAX / GE-UA 浏览器检查页自动通过。
//!
//! 站点返回短 HTML（含 `var cpk` / `X-GE-UA-Step`），浏览器会：
//! 1. 读取 Cookie（通常为 `ge_ua_p`）
//! 2. 按 nonce 对 cookie 字符加权求和
//! 3. POST 同 URL（`sum`+`nonce`，头 `X-GE-UA-Step`）
//! 4. 获得 `ge_ua_key` 后再 reload
//!
//! 安卓 Legado 多依赖 WebView 执行该脚本；本引擎无 WebView，在 HTTP 层复现该协议。

use once_cell::sync::Lazy;
use regex::Regex;

static NONCE_RE: Lazy<Regex> = Lazy::new(|| Regex::new(r#"var\s+nonce\s*=\s*(\d+)"#).unwrap());
static CPK_RE: Lazy<Regex> = Lazy::new(|| Regex::new(r#"var\s+cpk\s*=\s*"([^"]+)""#).unwrap());
static STEP_RE: Lazy<Regex> = Lazy::new(|| Regex::new(r#"var\s+step\s*=\s*"([^"]+)""#).unwrap());

/// 是否为 GE-UA / 人人书云MAX 挑战页
pub fn is_challenge(html: &str) -> bool {
    if html.len() > 20_000 {
        return false;
    }
    let markers = [
        "ui-uam-box",
        "X-GE-UA-Step",
        "var cpk",
        "人人书云",
        "Checking your browser before accessing",
        "在访问",
    ];
    let has_marker = markers.iter().any(|m| html.contains(m));
    if !has_marker {
        return false;
    }
    // 脚本里的 nonce + cookie 名是协议核心
    NONCE_RE.is_match(html) && (html.contains("ge_ua_p") || CPK_RE.is_match(html))
}

#[derive(Debug, Clone)]
pub struct ChallengeParams {
    pub cpk: String,
    pub step: String,
    pub nonce: i64,
}

pub fn parse_challenge(html: &str) -> Option<ChallengeParams> {
    let nonce = NONCE_RE
        .captures(html)?
        .get(1)?
        .as_str()
        .parse::<i64>()
        .ok()?;
    let cpk = CPK_RE
        .captures(html)
        .and_then(|c| c.get(1).map(|m| m.as_str().to_string()))
        .unwrap_or_else(|| "ge_ua_p".to_string());
    let step = STEP_RE
        .captures(html)
        .and_then(|c| c.get(1).map(|m| m.as_str().to_string()))
        .unwrap_or_else(|| "prev".to_string());
    Some(ChallengeParams { cpk, step, nonce })
}

/// 与页面 JS 一致：仅对 `[a-zA-Z0-9]` 累计 `charCode * (nonce + index)`。
/// Cookie 值使用 Set-Cookie 原文（常见 URL 编码如 `%2B...`），勿事先 decode。
pub fn compute_sum(cookie_value: &str, nonce: i64) -> i64 {
    let mut sum: i64 = 0;
    for (i, ch) in cookie_value.chars().enumerate() {
        if ch.is_ascii_alphanumeric() {
            sum += (ch as i64) * (nonce + i as i64);
        }
    }
    sum
}

pub fn origin_of(url: &str) -> String {
    url::Url::parse(url)
        .ok()
        .map(|u| {
            let origin = u.origin().ascii_serialization();
            if origin.is_empty() {
                format!("{}://{}", u.scheme(), u.host_str().unwrap_or(""))
            } else {
                origin
            }
        })
        .unwrap_or_else(|| url.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE: &str = r#"<!DOCTYPE html>
<html><head><title></title>
<script type="text/javascript">
var cpk = "ge_ua_p"
var step = "prev";
var nonce = 2894;
function loadFunc(){var e=document.cookie;s.setRequestHeader("X-GE-UA-Step",step)}
</script></head>
<body><div class="ui-uam-box">
<h1>Checking your browser before accessing www.rrssk.com</h1>
<p>DDoS protection by 人人书云MAX</p>
</div></body></html>"#;

    #[test]
    fn detects_challenge_page() {
        assert!(is_challenge(SAMPLE));
        assert!(!is_challenge("<html><body>normal search</body></html>"));
        assert!(!is_challenge(&"x".repeat(25_000)));
    }

    #[test]
    fn parses_params() {
        let p = parse_challenge(SAMPLE).unwrap();
        assert_eq!(p.cpk, "ge_ua_p");
        assert_eq!(p.step, "prev");
        assert_eq!(p.nonce, 2894);
    }

    #[test]
    fn sum_matches_known_vector() {
        // 与 tools/_ge_ua_probe3.py 一次成功的向量一致
        let n = "%2BmQfM8J8xn7H9ZMBFRmaqg%2Fs0zzGj%2FcAxYc0MDImNSbk";
        let nonce = 2894i64;
        assert_eq!(compute_sum(n, nonce), 11_470_316);
    }

    #[test]
    fn origin_strips_path() {
        assert_eq!(
            origin_of("https://www.rrssk.com/k-abc.html"),
            "https://www.rrssk.com"
        );
    }
}
