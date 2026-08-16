use base64::Engine;
use scraper::Html;

use super::AppError;
use crate::http::{analyze_url, client};
use crate::rule::{engine, js_engine, json_rule};

#[flutter_rust_bridge::frb]
pub async fn search_cover_by_rule(
    rule_json: String,
    name: String,
    author: String,
) -> Result<Option<String>, AppError> {
    let config: serde_json::Value = serde_json::from_str(&rule_json)
        .map_err(|error| AppError::Parse(format!("封面规则 JSON 无效: {error}")))?;
    if !config
        .get("enable")
        .and_then(serde_json::Value::as_bool)
        .unwrap_or(true)
    {
        return Ok(None);
    }
    let search_url = config
        .get("searchUrl")
        .and_then(serde_json::Value::as_str)
        .unwrap_or("")
        .trim();
    let cover_rule = config
        .get("coverRule")
        .and_then(serde_json::Value::as_str)
        .unwrap_or("")
        .trim();
    if search_url.is_empty() || cover_rule.is_empty() {
        return Ok(None);
    }

    let request = analyze_url::resolve_request(search_url, name.trim(), 1, "", "")
        .map_err(AppError::Parse)?;
    let body = if request.url.starts_with("data:") {
        decode_data_url(&request.url)?
    } else {
        client::fetch_request_config(&request, None)
            .await
            .map_err(AppError::Network)?
    };
    let base_url = if request.url.starts_with("http://") || request.url.starts_with("https://") {
        client::base_url(&request.url)
    } else {
        String::new()
    };
    let js_lib = config
        .get("jsLib")
        .and_then(serde_json::Value::as_str)
        .unwrap_or("");

    let result = if let Some(script) = strip_at_js(cover_rule) {
        js_engine::run_with_book_as_string(
            script,
            &body,
            js_lib,
            &base_url,
            name.trim(),
            author.trim(),
        )
        .map_err(AppError::JsExecution)?
    } else if cover_rule.starts_with('$') {
        let value: serde_json::Value = serde_json::from_str(&body)
            .map_err(|error| AppError::Parse(format!("封面规则 JSON 输入无效: {error}")))?;
        json_rule::resolve_field(&value, cover_rule, "", &base_url)
    } else {
        let document = Html::parse_document(&body);
        let root = document.root_element();
        engine::extract_text(&root, cover_rule)
    };
    let result = result.trim();
    if result.is_empty() {
        Ok(None)
    } else {
        Ok(Some(engine::resolve_url(result, &base_url)))
    }
}

fn strip_at_js(rule: &str) -> Option<&str> {
    rule.get(..4)
        .filter(|prefix| prefix.eq_ignore_ascii_case("@js:"))
        .map(|_| &rule[4..])
}

fn decode_data_url(url: &str) -> Result<String, AppError> {
    let (metadata, payload) = url
        .split_once(',')
        .ok_or_else(|| AppError::Parse("data URL 缺少内容分隔符".to_string()))?;
    if metadata.to_ascii_lowercase().ends_with(";base64") {
        let bytes = base64::engine::general_purpose::STANDARD
            .decode(payload)
            .map_err(|error| AppError::Parse(format!("data URL Base64 无效: {error}")))?;
        return String::from_utf8(bytes)
            .map_err(|error| AppError::Parse(format!("data URL 不是 UTF-8: {error}")));
    }
    Ok(payload.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn cover_rule_receives_original_book_context() {
        let rule = serde_json::json!({
            "enable": true,
            "searchUrl": "data:text/plain;base64,c2VlZA==",
            "coverRule": "@js:'https://example.test/' + encodeURIComponent(book.name + '|' + book.author + '|' + result)",
        });

        let result = search_cover_by_rule(rule.to_string(), "书名".to_string(), "作者".to_string())
            .await
            .unwrap();

        assert_eq!(
            result.as_deref(),
            Some("https://example.test/%E4%B9%A6%E5%90%8D%7C%E4%BD%9C%E8%80%85%7Cseed")
        );
    }

    #[test]
    fn ajax_all_keeps_original_response_body_contract() {
        let result = js_engine::run_with_book_as_string(
            "java.ajaxAll([]).length",
            "",
            "",
            "",
            "书名",
            "作者",
        )
        .unwrap();
        assert_eq!(result, "0");
    }
}
