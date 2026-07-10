use crate::model::book_source::BookSource;
use crate::rule::json_util;
use serde_json::Value;

pub fn parse_json_content(data: &Value, source: &BookSource) -> Result<String, String> {
    let rule_content = source
        .rule_content_obj
        .as_ref()
        .ok_or("无 ruleContent 对象")?;

    let content_path = rule_content
        .get("content")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    if content_path.is_empty() {
        return Ok(String::new());
    }

    if content_path.contains("<js>") {
        return Err("JSON 正文含 JS 规则".to_string());
    }

    let raw_path = content_path
        .split("<js>")
        .next()
        .unwrap_or(content_path)
        .trim();

    let content = json_util::resolve_string(data, raw_path);
    Ok(content.trim().to_string())
}

pub fn extract_json_next_url(data: &Value, next_rule: &str) -> String {
    if next_rule.is_empty() {
        return String::new();
    }
    json_util::resolve_string(data, next_rule)
}
