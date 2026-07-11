use crate::model::book_source::BookSource;
use crate::rule::{json_rule, replace_regex};
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

    let base = source.book_source_url.as_str();
    let js_lib = source.js_lib.as_str();
    let mut content = json_rule::resolve_field(data, content_path, js_lib, base);

    if let Some(re) = rule_content
        .get("replaceRegex")
        .and_then(|v| v.as_str())
        .or(source.rule_content_replace_regex.as_deref())
    {
        content = replace_regex::apply_replace_regex(&content, re);
    }

    Ok(content.trim().to_string())
}

pub fn extract_json_next_url(data: &Value, next_rule: &str) -> String {
    if next_rule.is_empty() {
        return String::new();
    }
    crate::rule::json_util::resolve_string(data, next_rule)
}
