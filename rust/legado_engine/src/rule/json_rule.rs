use serde_json::Value;

use super::js_engine;
use super::json_util;
use super::replace_regex;

/// 解析 JSON 字段规则（支持 `$.path` + `\n<js>` 后缀、`||` 多路径）
pub fn resolve_field(data: &Value, rule: &str, js_lib: &str, base_url: &str) -> String {
    resolve_field_list(data, rule, js_lib, base_url).join("\n")
}

/// Resolve a JSON rule without collapsing multiple values.
pub fn resolve_field_list(data: &Value, rule: &str, js_lib: &str, base_url: &str) -> Vec<String> {
    let parts: Vec<&str> = if js_engine::contains_js_block(rule) {
        vec![rule]
    } else {
        rule.split("||").collect()
    };
    for part in parts {
        let values = resolve_field_single_list(data, part.trim(), js_lib, base_url);
        if !values.is_empty() {
            return values;
        }
    }
    Vec::new()
}

fn resolve_field_single_list(
    data: &Value,
    rule: &str,
    js_lib: &str,
    base_url: &str,
) -> Vec<String> {
    if rule.is_empty() {
        return Vec::new();
    }

    if js_engine::contains_js_block(rule) && !rule.contains('\n') && rule.starts_with("<js>") {
        let input = serde_json::to_string(data).unwrap_or_else(|_| data.to_string());
        if let Some(script) = js_engine::extract_js_block(rule) {
            if let Ok(out) = js_engine::run_with_result(&script, &input, js_lib, base_url) {
                return parse_structured_strings(&out);
            }
        }
        return Vec::new();
    }

    let (json_part, js_part) = split_json_and_js(rule);
    let mut values = if json_part.starts_with('$') || json_part.starts_with('@') {
        json_util::resolve_strings(data, json_part.trim())
    } else if !json_part.is_empty() {
        vec![json_part.to_string()]
    } else {
        vec![data.to_string()]
    };

    if let Some(script) = js_part {
        let input = values.join("\n");
        if let Ok(out) = js_engine::run_with_result(&script, &input, js_lib, base_url) {
            values = parse_structured_strings(&out);
        }
    }

    if rule.contains("##") {
        values
            .into_iter()
            .map(|value| replace_regex::apply_rule_regex_suffix(rule, &value))
            .filter(|value| !value.is_empty())
            .collect()
    } else {
        values
    }
}

fn parse_structured_strings(value: &str) -> Vec<String> {
    if let Ok(json) = serde_json::from_str::<Value>(value) {
        let values = json_util::value_to_strings(&json);
        if !values.is_empty() {
            return values;
        }
    }
    if value.is_empty() {
        Vec::new()
    } else {
        vec![value.to_string()]
    }
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

#[cfg(test)]
mod return_semantics_tests {
    use super::*;

    #[test]
    fn json_string_rule_joins_multiple_values_like_legado_get_string() {
        let data = serde_json::json!({
            "items": [{"name": "第一项"}, {"name": "第二项"}]
        });
        assert_eq!(
            resolve_field(&data, "$.items[*].name", "", ""),
            "第一项\n第二项"
        );
    }
}
