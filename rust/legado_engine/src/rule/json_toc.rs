use crate::model::book_source::BookSource;
use crate::rule::json_util;
use serde_json::Value;

#[derive(Debug, Clone)]
pub struct JsonChapter {
    pub title: String,
    pub url: String,
}

pub fn parse_json_toc(data: &Value, source: &BookSource) -> Result<Vec<JsonChapter>, String> {
    let rule_toc = source
        .rule_toc_obj
        .as_ref()
        .ok_or("无 ruleToc 对象")?;

    let list_path = rule_toc
        .get("chapterList")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    if list_path.is_empty() {
        return Ok(vec![]);
    }

    let name_paths = rule_toc
        .get("chapterName")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let url_paths = rule_toc
        .get("chapterUrl")
        .and_then(|v| v.as_str())
        .unwrap_or("");

    let items = json_util::collect_array(data, list_path);
    let mut chapters = Vec::new();
    for item in items {
        let title = json_util::resolve_first_string(&item, name_paths);
        let mut url = json_util::resolve_first_string(&item, url_paths);
        if url.contains("{{") {
            url = json_util::resolve_template(&url, &item);
        }
        if !title.is_empty() && !url.is_empty() {
            chapters.push(JsonChapter { title, url });
        }
    }
    Ok(chapters)
}

pub fn extract_json_next_url(data: &Value, next_rule: &str) -> String {
    if next_rule.is_empty() {
        return String::new();
    }
    json_util::resolve_string(data, next_rule)
}
