use crate::model::book_source::BookSource;
use jsonpath_rust::JsonPath;
use serde_json::Value;
use std::str::FromStr;

/// JSON 搜索结果（内部）
#[derive(Debug, Clone)]
pub struct JsonSearchResult {
    pub name: String,
    pub author: String,
    pub cover_url: String,
    pub book_url: String,
    pub kind: String,
    pub note: String,
}

pub fn parse_json_search(data: &Value, source: &BookSource) -> Result<Vec<JsonSearchResult>, String> {
    let rule_search = source
        .rule_search_obj
        .as_ref()
        .ok_or("无 ruleSearch 对象")?;

    let book_list_path = rule_search
        .get("bookList")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    if book_list_path.is_empty() {
        return Ok(vec![]);
    }

    let items = resolve_path(data, book_list_path)?;
    let items = match items {
        Value::Array(arr) => arr,
        other => vec![other],
    };

    let name_path = rule_search.get("name").and_then(|v| v.as_str()).unwrap_or("");
    let author_path = rule_search
        .get("author")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let book_url_path = rule_search
        .get("bookUrl")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let cover_url_path = rule_search
        .get("coverUrl")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let intro_path = rule_search
        .get("intro")
        .and_then(|v| v.as_str())
        .unwrap_or("");

    let mut results = Vec::new();
    for item in items {
        let name = resolve_string(&item, name_path);
        if name.is_empty() {
            continue;
        }

        let book_url = if book_url_path.contains("{{") {
            resolve_template(book_url_path, &item)
        } else {
            resolve_string(&item, book_url_path)
        };

        results.push(JsonSearchResult {
            name,
            author: resolve_string(&item, author_path),
            cover_url: resolve_string(&item, cover_url_path),
            book_url,
            kind: String::new(),
            note: resolve_string(&item, intro_path),
        });
    }

    Ok(results)
}

fn resolve_path(data: &Value, path: &str) -> Result<Value, String> {
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

fn resolve_string(item: &Value, path: &str) -> String {
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

fn resolve_template(template: &str, item: &Value) -> String {
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

fn value_to_string(val: &Value) -> String {
    match val {
        Value::String(s) => s.clone(),
        Value::Number(n) => n.to_string(),
        Value::Bool(b) => b.to_string(),
        Value::Array(arr) => arr.first().map(value_to_string).unwrap_or_default(),
        _ => val.to_string(),
    }
}
