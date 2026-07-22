use crate::model::book_source::BookSource;
use crate::rule::{json_rule, json_util};
use serde_json::Value;

#[derive(Debug, Clone)]
pub struct JsonChapter {
    pub title: String,
    pub url: String,
    pub is_volume: bool,
    pub is_vip: bool,
    pub is_pay: bool,
    pub tag: String,
    pub base_url: String,
}

pub fn parse_json_toc(
    data: &Value,
    source: &BookSource,
    js_base_url: &str,
) -> Result<Vec<JsonChapter>, String> {
    let rule_toc = source.rule_toc_obj.as_ref().ok_or("无 ruleToc 对象")?;

    let list_path = rule_toc
        .get("chapterList")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    if list_path.is_empty() {
        return Ok(vec![]);
    }

    let mut reverse = false;
    let mut list_paths = list_path.trim().to_string();
    if list_paths.starts_with('-') {
        reverse = true;
        list_paths = list_paths[1..].trim().to_string();
    }

    let base = js_base_url;
    let js_lib = source.js_lib.as_str();
    let name_paths = rule_toc
        .get("chapterName")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let url_paths = rule_toc
        .get("chapterUrl")
        .and_then(|v| v.as_str())
        .unwrap_or("");

    let items = json_util::collect_array(data, &list_paths);
    let mut chapters = Vec::new();
    for (index, item) in items.into_iter().enumerate() {
        let title = json_rule::resolve_field(&item, name_paths, js_lib, base);
        let mut url = json_rule::resolve_field(&item, url_paths, js_lib, base);
        if url.contains("{{") {
            url = json_util::resolve_template(&url, &item);
        }
        let is_volume = is_true(json_rule::resolve_field(
            &item,
            &source.rule_toc_is_volume,
            js_lib,
            base,
        ));
        if url.is_empty() {
            url = if is_volume {
                format!("{title}{index}")
            } else {
                base.to_string()
            };
        }
        if !title.is_empty() {
            chapters.push(JsonChapter {
                title,
                url,
                is_volume,
                is_vip: is_true(json_rule::resolve_field(
                    &item,
                    &source.rule_toc_is_vip,
                    js_lib,
                    base,
                )),
                is_pay: is_true(json_rule::resolve_field(
                    &item,
                    &source.rule_toc_is_pay,
                    js_lib,
                    base,
                )),
                tag: json_rule::resolve_field(&item, &source.rule_toc_update_time, js_lib, base),
                base_url: base.to_string(),
            });
        }
    }
    if reverse {
        chapters.reverse();
    }
    Ok(chapters)
}

fn is_true(value: String) -> bool {
    matches!(
        value.trim().to_ascii_lowercase().as_str(),
        "1" | "true" | "yes" | "y" | "是" | "卷"
    )
}

pub fn extract_json_next_url(data: &Value, next_rule: &str) -> String {
    if next_rule.is_empty() {
        return String::new();
    }
    json_util::resolve_string(data, next_rule)
}
