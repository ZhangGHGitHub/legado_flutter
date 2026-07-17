use super::css;
use super::legado_rule;
use super::xpath;
use scraper::{ElementRef, Html, Selector};

/// 从 HTML 元素按规则提取文本
pub fn extract_text(element: &ElementRef<'_>, rule: &str) -> String {
    if rule.is_empty() {
        return String::new();
    }

    if rule.contains("||") {
        for part in split_top_level(rule, "||") {
            let result = extract_text(element, part.trim());
            if !result.is_empty() {
                return result;
            }
        }
        return String::new();
    }

    if rule.contains("&&") {
        return split_top_level(rule, "&&")
            .iter()
            .map(|p| extract_text(element, p.trim()))
            .collect::<Vec<_>>()
            .join("");
    }

    let mut processed = rule.trim().to_string();
    while processed.starts_with('@') && !processed.starts_with("@@") {
        processed = processed[1..].trim().to_string();
    }
    if processed.starts_with("@@") {
        processed = processed[2..].trim().to_string();
    }

    if let Some(expr) = processed.strip_prefix("@css:") {
        return css::extract_text(element, expr.trim());
    }
    if let Some(expr) = processed.strip_prefix("@CSS:") {
        return css::extract_text(element, expr.trim());
    }

    if xpath::is_xpath_rule(&processed) {
        let out = xpath::extract_text(element, &processed);
        if !out.is_empty() {
            return out;
        }
    }

    let legado = legado_rule::extract_text(element, &processed);
    if !legado.is_empty() || legado_rule::is_legado_chain_rule(&processed) {
        return legado;
    }

    if processed.starts_with(':') {
        let expr = processed[1..].trim();
        return expr
            .split("&&")
            .map(|p| css::extract_text(element, p.trim()))
            .collect::<Vec<_>>()
            .join("");
    }

    // 默认当作 CSS 规则
    css::extract_text(element, &processed)
}

/// 从 HTML 元素按规则提取属性
pub fn extract_attr(element: &ElementRef<'_>, rule: &str, attr: &str) -> String {
    if rule.is_empty() {
        return String::new();
    }

    if rule.contains("||") {
        for part in split_top_level(rule, "||") {
            let result = extract_attr(element, part.trim(), attr);
            if !result.is_empty() {
                return result;
            }
        }
        return String::new();
    }

    let mut processed = rule.trim().to_string();
    while processed.starts_with('@') && !processed.starts_with("@@") {
        processed = processed[1..].trim().to_string();
    }

    if let Some(expr) = processed.strip_prefix("@css:") {
        return css::extract_attr(element, expr.trim(), attr);
    }

    if xpath::is_xpath_rule(&processed) {
        let out = xpath::extract_attr(element, &processed);
        if !out.is_empty() {
            return out;
        }
    }

    let legado = legado_rule::extract_attr(element, &processed, attr);
    if !legado.is_empty() || legado_rule::is_legado_chain_rule(&processed) {
        return legado;
    }

    css::extract_attr(element, &processed, attr)
}

/// 查询匹配规则的元素列表
pub fn query_all<'a>(_html: &'a Html, body: &ElementRef<'a>, rule: &str) -> Vec<ElementRef<'a>> {
    if rule.is_empty() {
        return vec![body.clone()];
    }

    let mut processed = rule.trim().to_string();
    if let Some(expr) = processed.strip_prefix("@css:") {
        processed = expr.trim().to_string();
    }
    if processed.starts_with(':') {
        processed = processed[1..].trim().to_string();
    }

    // Jingshiro 列表规则：`||` 取首个非空；`&&` 取并集
    if processed.contains("||") {
        for part in split_top_level(&processed, "||") {
            let items = query_all(_html, body, part.trim());
            if !items.is_empty() {
                return items;
            }
        }
        return vec![];
    }
    if processed.contains("&&") {
        let mut all = Vec::new();
        for part in split_top_level(&processed, "&&") {
            all.extend(query_all(_html, body, part.trim()));
        }
        return all;
    }

    if xpath::is_xpath_rule(&processed) {
        return xpath::query_all(body, &processed);
    }

    if let Ok(sel) = Selector::parse(&processed) {
        return body.select(&sel).collect();
    }

    // 智能兜底（限定 body）
    for fallback in [".result-item", ".search-item", ".list-item", "li"] {
        if let Ok(sel) = Selector::parse(fallback) {
            let items: Vec<_> = body.select(&sel).collect();
            if items.len() >= 3 {
                return items;
            }
        }
    }
    vec![]
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

fn split_top_level(s: &str, sep: &str) -> Vec<String> {
    let mut parts = Vec::new();
    let mut current = String::new();
    let sep_len = sep.len();
    let mut i = 0;
    let chars: Vec<char> = s.chars().collect();
    while i < chars.len() {
        if i + sep_len <= chars.len() {
            let candidate: String = chars[i..i + sep_len].iter().collect();
            if candidate == sep {
                parts.push(current.clone());
                current.clear();
                i += sep_len;
                continue;
            }
        }
        current.push(chars[i]);
        i += 1;
    }
    parts.push(current);
    parts
}
