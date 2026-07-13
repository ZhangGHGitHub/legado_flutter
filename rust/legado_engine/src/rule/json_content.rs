use crate::model::book_source::BookSource;
use crate::rule::{json_rule, replace_regex};
use serde_json::Value;

pub fn parse_json_content(data: &Value, source: &BookSource) -> Result<String, String> {
    // Legado / Dart 扁平化：`ruleContent` 可能是对象 `{content:..}`，或直接是路径字符串
    let (mut content_path, replace_from_obj) = match source.rule_content_obj.as_ref() {
        Some(Value::Object(obj)) => (
            obj.get("content")
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string(),
            obj.get("replaceRegex")
                .and_then(|v| v.as_str())
                .map(|s| s.to_string()),
        ),
        Some(Value::String(s)) => (s.clone(), None),
        Some(_) => (String::new(), None),
        None => (String::new(), None),
    };
    if content_path.is_empty() {
        content_path = source.rule_content.clone();
    }
    if content_path.is_empty() {
        return Err("无 ruleContent 规则".to_string());
    }

    let base = source.book_source_url.as_str();
    let js_lib = source.js_lib.as_str();
    let mut content = json_rule::resolve_field(data, &content_path, js_lib, base);

    let replace = replace_from_obj
        .as_deref()
        .or(source.rule_content_replace_regex.as_deref());
    if let Some(re) = replace {
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
