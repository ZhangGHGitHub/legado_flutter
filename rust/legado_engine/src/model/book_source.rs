use serde_json::Value;
use std::collections::HashMap;

/// Legado 书源模型（从 JSON 解析）
#[derive(Debug, Clone)]
pub struct BookSource {
    pub book_source_url: String,
    pub book_source_name: String,
    pub rule_search_url: String,
    pub rule_search_list: String,
    pub rule_search_name: String,
    pub rule_search_author: String,
    pub rule_search_cover_url: String,
    pub rule_search_kind: String,
    pub rule_search_note: String,
    pub rule_search_book_url: String,
    pub rule_toc_chapter_list: String,
    pub rule_toc_chapter_name: String,
    pub rule_toc_chapter_url: String,
    pub rule_toc_next_toc_url: String,
    pub rule_book_info_toc_url: String,
    pub rule_book_info_name: String,
    pub rule_book_info_author: String,
    pub rule_book_info_cover_url: String,
    pub rule_book_info_intro: String,
    pub rule_book_info_kind: String,
    pub rule_book_info_last_chapter: String,
    pub rule_explore_url: String,
    pub rule_explore_list: String,
    pub rule_explore_name: String,
    pub rule_explore_author: String,
    pub rule_explore_cover_url: String,
    pub rule_explore_book_url: String,
    pub rule_explore_kind: String,
    pub rule_explore_note: String,
    pub rule_explore_intro: String,
    pub rule_content: String,
    pub rule_content_next_url: String,
    pub rule_content_replace_regex: Option<String>,
    pub concurrent_rate: Option<String>,
    pub js_lib: String,
    pub raw_json: String,
    pub rule_search_obj: Option<Value>,
    pub rule_toc_obj: Option<Value>,
    pub rule_content_obj: Option<Value>,
    pub rule_book_info_obj: Option<Value>,
    pub rule_explore_obj: Option<Value>,
}

impl BookSource {
    pub fn from_json(json_str: &str) -> Result<Self, String> {
        let obj: Value =
            serde_json::from_str(json_str).map_err(|e| format!("书源 JSON 解析失败: {e}"))?;
        let map = obj.as_object().ok_or("书源 JSON 必须是对象")?;

        let nested = |outer: &str, inner: &str, flat: &str| -> String {
            if let Some(v) = map.get(flat).and_then(|v| v.as_str()) {
                if !v.is_empty() {
                    return v.to_string();
                }
            }
            map.get(outer)
                .and_then(|o| o.get(inner))
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string()
        };

        let rule_search_obj = map.get("ruleSearch").cloned();
        let rule_toc_obj = map.get("ruleToc").cloned();
        let rule_content_obj = map.get("ruleContent").cloned();
        let rule_book_info_obj = map.get("ruleBookInfo").cloned();
        let rule_explore_obj = map.get("ruleExplore").cloned();

        let rule_content_replace_regex = rule_content_obj
            .as_ref()
            .and_then(|o| o.get("replaceRegex"))
            .and_then(|v| v.as_str())
            .map(|s| s.to_string());

        Ok(Self {
            book_source_url: str_field(map, "bookSourceUrl"),
            book_source_name: str_field(map, "bookSourceName"),
            rule_search_url: {
                let a = str_field(map, "ruleSearchUrl");
                if a.is_empty() {
                    str_field(map, "searchUrl")
                } else {
                    a
                }
            },
            rule_search_list: nested("ruleSearch", "bookList", "ruleSearchList"),
            rule_search_name: nested("ruleSearch", "name", "ruleSearchName"),
            rule_search_author: nested("ruleSearch", "author", "ruleSearchAuthor"),
            rule_search_cover_url: nested("ruleSearch", "coverUrl", "ruleSearchCoverUrl"),
            rule_search_kind: nested("ruleSearch", "kind", "ruleSearchKind"),
            rule_search_note: nested("ruleSearch", "note", "ruleSearchNote"),
            rule_search_book_url: nested("ruleSearch", "bookUrl", "ruleSearchBookUrl"),
            rule_toc_chapter_list: nested("ruleToc", "chapterList", "ruleChapterList"),
            rule_toc_chapter_name: nested("ruleToc", "chapterName", "ruleChapterName"),
            rule_toc_chapter_url: nested("ruleToc", "chapterUrl", "ruleChapterUrl"),
            rule_toc_next_toc_url: nested("ruleToc", "nextTocUrl", "rulePageNext"),
            rule_book_info_toc_url: nested("ruleBookInfo", "tocUrl", "ruleBookTocUrl"),
            rule_book_info_name: nested("ruleBookInfo", "name", "ruleBookName"),
            rule_book_info_author: nested("ruleBookInfo", "author", "ruleBookAuthor"),
            rule_book_info_cover_url: nested("ruleBookInfo", "coverUrl", "ruleBookCoverUrl"),
            rule_book_info_intro: nested("ruleBookInfo", "intro", "ruleBookNote"),
            rule_book_info_kind: nested("ruleBookInfo", "kind", "ruleBookKind"),
            rule_book_info_last_chapter: nested("ruleBookInfo", "lastChapter", "ruleBookLastChapter"),
            rule_explore_url: {
                let a = str_field(map, "exploreUrl");
                if a.is_empty() {
                    str_field(map, "ruleExploreUrl")
                } else {
                    a
                }
            },
            rule_explore_list: nested("ruleExplore", "bookList", "ruleExploreList"),
            rule_explore_name: nested("ruleExplore", "name", "ruleExploreName"),
            rule_explore_author: nested("ruleExplore", "author", "ruleExploreAuthor"),
            rule_explore_cover_url: nested("ruleExplore", "coverUrl", "ruleExploreCoverUrl"),
            rule_explore_book_url: nested("ruleExplore", "bookUrl", "ruleExploreBookUrl"),
            rule_explore_kind: nested("ruleExplore", "kind", "ruleExploreKind"),
            rule_explore_note: nested("ruleExplore", "note", "ruleExploreNote"),
            rule_explore_intro: nested("ruleExplore", "intro", "ruleExploreIntro"),
            rule_content: nested("ruleContent", "content", "ruleContent"),
            rule_content_next_url: nested("ruleContent", "nextContentUrl", "rulePageNext"),
            rule_content_replace_regex,
            concurrent_rate: map.get("concurrentRate").and_then(|v| match v {
                Value::String(s) if !s.is_empty() => Some(s.clone()),
                Value::Number(n) => Some(n.to_string()),
                _ => None,
            }),
            js_lib: str_field(map, "jsLib"),
            raw_json: json_str.to_string(),
            rule_search_obj,
            rule_toc_obj,
            rule_content_obj,
            rule_book_info_obj,
            rule_explore_obj,
        })
    }

    pub fn is_json_api(&self) -> bool {
        for rule in [
            &self.rule_search_obj,
            &self.rule_toc_obj,
            &self.rule_content_obj,
            &self.rule_book_info_obj,
            &self.rule_explore_obj,
        ] {
            if let Some(r) = rule {
                if has_json_rule(r) {
                    return true;
                }
            }
        }
        false
    }

    pub fn needs_dart_js(&self) -> bool {
        self.raw_json.contains("@js:")
    }

    pub fn needs_dart_js_for_search(&self) -> bool {
        false
    }

    pub fn needs_dart_js_for_toc(&self) -> bool {
        false
    }

    pub fn needs_dart_js_for_content(&self) -> bool {
        false
    }

    pub fn needs_dart_js_for_book_info(&self) -> bool {
        false
    }

    pub fn needs_dart_js_for_explore(&self) -> bool {
        false
    }
}

/// 是否含 JS 规则片段（仅 @js: URL 模板需强制 Dart）
pub fn field_needs_js(s: &str) -> bool {
    s.contains("@js:")
}

pub fn field_has_js_block(s: &str) -> bool {
    s.contains("<js>") || s.contains("@js:")
}

fn json_needs_js(value: &Option<Value>) -> bool {
    value
        .as_ref()
        .map(|v| {
            let text = v.to_string();
            field_needs_js(&text)
        })
        .unwrap_or(false)
}

fn any_field_needs_js(fields: &[&str]) -> bool {
    fields.iter().any(|f| field_needs_js(f))
}

fn str_field(map: &serde_json::Map<String, Value>, key: &str) -> String {
    map.get(key)
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string()
}

fn has_json_rule(rule: &Value) -> bool {
    match rule {
        Value::Object(obj) => obj.values().any(|v| {
            if let Some(s) = v.as_str() {
                s.starts_with('$')
            } else {
                false
            }
        }),
        Value::String(s) => s.starts_with('$'),
        _ => false,
    }
}

/// 书源自定义请求头（兼容 Legado：`header` 为 object 或 JSON 字符串）
pub fn custom_headers(json_str: &str) -> HashMap<String, String> {
    let mut headers = HashMap::new();
    let Ok(obj) = serde_json::from_str::<Value>(json_str) else {
        return headers;
    };
    let Some(header_val) = obj.get("header") else {
        return headers;
    };
    let header_obj = match header_val {
        Value::Object(map) => Some(map.clone()),
        Value::String(s) => serde_json::from_str::<Value>(s)
            .ok()
            .and_then(|v| v.as_object().cloned()),
        _ => None,
    };
    if let Some(header) = header_obj {
        for (k, v) in header {
            let s = match v {
                Value::String(s) => s,
                other => other.to_string(),
            };
            if !s.is_empty() {
                headers.insert(k, s);
            }
        }
    }
    headers
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn custom_headers_parses_json_string() {
        let src = r#"{
            "bookSourceUrl":"https://novel.cooks.tw",
            "header":"{\"User-Agent\":\"UA-TEST\",\"Referer\":\"https://novel.cooks.tw/\"}"
        }"#;
        let h = custom_headers(src);
        assert_eq!(h.get("User-Agent").map(String::as_str), Some("UA-TEST"));
        assert_eq!(
            h.get("Referer").map(String::as_str),
            Some("https://novel.cooks.tw/")
        );
    }

    #[test]
    fn custom_headers_parses_object() {
        let src = r#"{"header":{"Accept-Language":"zh-CN"}}"#;
        let h = custom_headers(src);
        assert_eq!(h.get("Accept-Language").map(String::as_str), Some("zh-CN"));
    }

    #[test]
    fn from_json_accepts_flat_rule_content_string() {
        let src = r#"{
            "bookSourceUrl":"https://novel.cooks.tw",
            "ruleContent":"$.data.content\n<js>Clean(result)</js>",
            "jsLib":"function Clean(r){return r}"
        }"#;
        let bs = BookSource::from_json(src).unwrap();
        assert!(bs.is_json_api());
        assert_eq!(
            bs.rule_content,
            "$.data.content\n<js>Clean(result)</js>"
        );
        // 扁平字符串仍要能识别为 JSON 规则
        assert!(matches!(
            bs.rule_content_obj,
            Some(Value::String(ref s)) if s.starts_with("$.data.content")
        ));
    }
}
