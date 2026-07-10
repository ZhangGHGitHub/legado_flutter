use serde_json::Value;
use std::str::FromStr;

use jsonpath_rust::JsonPath;

pub fn resolve_path(data: &Value, path: &str) -> Result<Value, String> {
    let jp = JsonPath::from_str(path).map_err(|e| format!("JSONPath 解析失败: {e}"))?;
    let results = jp.find_slice(data);
    let values: Vec<Value> = results
        .into_iter()
        .filter(|v| v.has_value())
        .map(|v| v.to_data())
        .collect();

    if values.is_empty() {
        return Err(format!("JSONPath 无结果: {path}"));
    }
    if values.len() == 1 {
        Ok(values.into_iter().next().unwrap())
    } else {
        Ok(Value::Array(values))
    }
}

pub fn resolve_string(item: &Value, path: &str) -> String {
    if path.is_empty() {
        return String::new();
    }
    if let Ok(jp) = JsonPath::from_str(path) {
        let results = jp.find_slice(item);
        if let Some(val) = results.into_iter().find(|v| v.has_value()) {
            return value_to_string(&val.to_data());
        }
    }
    String::new()
}

pub fn resolve_first_string(item: &Value, paths: &str) -> String {
    for part in paths.split("||") {
        let s = resolve_string(item, part.trim());
        if !s.is_empty() {
            return s;
        }
    }
    String::new()
}

pub fn resolve_template(template: &str, item: &Value) -> String {
    let mut result = template.to_string();
    if let Some(obj) = item.as_object() {
        for (key, val) in obj {
            let placeholder = format!("{{{{{key}}}}}");
            if result.contains(&placeholder) {
                result = result.replace(&placeholder, &value_to_string(val));
            }
        }
    }
    result
}

pub fn value_to_string(val: &Value) -> String {
    match val {
        Value::String(s) => s.clone(),
        Value::Number(n) => n.to_string(),
        Value::Bool(b) => b.to_string(),
        Value::Array(arr) => arr.first().map(value_to_string).unwrap_or_default(),
        _ => val.to_string(),
    }
}

pub fn collect_array(data: &Value, list_paths: &str) -> Vec<Value> {
    for part in list_paths.split("||") {
        let path = part.trim();
        if path.is_empty() {
            continue;
        }
        if let Ok(val) = resolve_path(data, path) {
            match val {
                Value::Array(arr) if !arr.is_empty() => return arr,
                other if !other.is_null() => return vec![other],
                _ => {}
            }
        }
    }
    vec![]
}
