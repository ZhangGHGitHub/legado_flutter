use serde_json::Value;

use super::js_engine;
use super::json_util;
use super::replace_regex;

/// 解析 JSON 字段规则（支持 `$.path` + `\n<js>` 后缀、`||` 多路径）
pub fn resolve_field(
    data: &Value,
    rule: &str,
    js_lib: &str,
    base_url: &str,
) -> String {
    let parts: Vec<&str> = if js_engine::contains_js_block(rule) {
        vec![rule]
    } else {
        rule.split("||").collect()
    };
    for part in parts {
        let s = resolve_field_single(data, part.trim(), js_lib, base_url);
        if !s.is_empty() {
            return s;
        }
    }
    String::new()
}

fn resolve_field_single(
    data: &Value,
    rule: &str,
    js_lib: &str,
    base_url: &str,
) -> String {
    if rule.is_empty() {
        return String::new();
    }

    if js_engine::contains_js_block(rule) && !rule.contains('\n') && rule.starts_with("<js>") {
        let input = serde_json::to_string(data).unwrap_or_else(|_| data.to_string());
        if let Some(script) = js_engine::extract_js_block(rule) {
            if let Ok(out) = js_engine::run_with_result(&script, &input, js_lib, base_url) {
                return out;
            }
        }
        return String::new();
    }

    let (json_part, js_part) = split_json_and_js(rule);
    let mut result = if json_part.starts_with('$') || json_part.starts_with('@') {
        json_util::resolve_string(data, json_part.trim())
    } else if !json_part.is_empty() {
        json_part.to_string()
    } else {
        data.to_string()
    };

    if let Some(script) = js_part {
        if let Ok(out) = js_engine::run_with_result(&script, &result, js_lib, base_url) {
            result = out;
        }
    }

    replace_regex::apply_rule_regex_suffix(rule, &result)
}

fn split_json_and_js(rule: &str) -> (&str, Option<String>) {
    if let Some(idx) = rule.find("\n<js>") {
        let json_part = rule[..idx].trim();
        let js_block = &rule[idx + 1..];
        if let Some(script) = js_engine::extract_js_block(js_block) {
            return (json_part, Some(script));
        }
    }
    if rule.starts_with("<js>") {
        if let Some(script) = js_engine::extract_js_block(rule) {
            return ("", Some(script));
        }
    }
    (rule, None)
}
