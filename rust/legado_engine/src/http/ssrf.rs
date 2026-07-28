//! 书源 HTTP 请求的基础 SSRF 防护（不约束 Web API 本机监听）。
//!
//! 限制（刻意不做 DNS 解析）：仅校验 URL 字面量 host（localhost / 私网 IP 段等）。
//! 重定向由 HTTP 客户端对每跳目标再调 [assert_public_http_url]；
//! 无法阻止「公网域名解析到内网」类 DNS rebinding。

/// 若 URL 指向明显内网 / 回环 / 链路本地目标则返回错误。
pub fn assert_public_http_url(url: &str) -> Result<(), String> {
    let trimmed = url.trim();
    let parsed = url::Url::parse(trimmed).map_err(|_| "无效的 URL".to_string())?;
    let scheme = parsed.scheme().to_ascii_lowercase();
    if scheme != "http" && scheme != "https" {
        return Err("仅允许 http/https 请求".to_string());
    }
    let host = match parsed.host_str() {
        Some(h) => h.to_ascii_lowercase(),
        None => return Err("无效的 URL".to_string()),
    };
    // 仅给 crate 单元测试的本地 HTTP fixture 放行带显式端口的 loopback。
    // 正式构建没有这段 cfg，生产网络策略仍拒绝所有 loopback/private host。
    #[cfg(test)]
    if host == "127.0.0.1" && parsed.port().is_some() {
        return Ok(());
    }
    if host == "localhost" || host == "0.0.0.0" || host == "::1" {
        return Err(format!("禁止访问本机/回环地址（SSRF 防护）: {host}"));
    }
    if is_blocked_host(&host) {
        return Err(format!("禁止访问内网/私有地址（SSRF 防护）: {host}"));
    }
    Ok(())
}

fn is_blocked_host(host: &str) -> bool {
    if host == "::1" {
        return true;
    }
    if host.starts_with("fe80:") || host.starts_with("fc") || host.starts_with("fd") {
        return true;
    }
    let parts: Vec<&str> = host.split('.').collect();
    if parts.len() != 4 {
        return false;
    }
    let nums: Option<Vec<u8>> = parts.iter().map(|p| p.parse::<u8>().ok()).collect();
    let Some(nums) = nums else {
        return false;
    };
    let a = nums[0];
    let b = nums[1];
    // 127.0.0.0/8
    if a == 127 {
        return true;
    }
    // 10.0.0.0/8
    if a == 10 {
        return true;
    }
    // 192.168.0.0/16
    if a == 192 && b == 168 {
        return true;
    }
    // 172.16.0.0/12
    if a == 172 && (16..=31).contains(&b) {
        return true;
    }
    // 169.254.0.0/16
    if a == 169 && b == 254 {
        return true;
    }
    // 0.0.0.0/8
    if a == 0 {
        return true;
    }
    false
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn allows_public_https() {
        assert!(assert_public_http_url("https://example.com/search").is_ok());
    }

    #[test]
    fn blocks_localhost() {
        assert!(assert_public_http_url("http://localhost:8080/x").is_err());
        assert!(assert_public_http_url("http://127.0.0.1/x").is_err());
    }

    #[test]
    fn blocks_private_ranges() {
        assert!(assert_public_http_url("http://10.0.0.1/").is_err());
        assert!(assert_public_http_url("http://192.168.1.1/").is_err());
        assert!(assert_public_http_url("http://172.16.0.1/").is_err());
        assert!(assert_public_http_url("http://169.254.1.1/").is_err());
    }

    #[test]
    fn allows_public_ipv4() {
        assert!(assert_public_http_url("http://8.8.8.8/dns").is_ok());
    }
}
