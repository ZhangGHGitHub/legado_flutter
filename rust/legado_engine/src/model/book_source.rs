use serde::{Deserialize, Serialize};
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
    pub rule_toc_is_volume: String,
    pub rule_toc_update_time: String,
    pub rule_toc_is_vip: String,
    pub rule_toc_is_pay: String,
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
    /// 顶层 `loginCheckJs` — 请求后检查登录态，可改写响应体（对齐 Jingshiro AnalyzeUrl）
    pub login_check_js: String,
    /// `ruleToc.preUpdateJs` — 拉取目录前执行（对齐 Jingshiro getChapterListAwait）
    pub pre_update_js: String,
    pub js_lib: String,
    pub raw_json: String,
    pub rule_search_obj: Option<Value>,
    pub rule_toc_obj: Option<Value>,
    pub rule_content_obj: Option<Value>,
    pub rule_book_info_obj: Option<Value>,
    pub rule_explore_obj: Option<Value>,
}

/// Flutter/domain-facing projection of a Legado book source.
///
/// The parser keeps the complete source JSON in `raw_source_json`; this DTO
/// exposes only the stable flat fields shared by the current Flutter model.
#[derive(Debug, Clone, Deserialize, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BookSourceDto {
    pub book_source_url: String,
    pub book_source_name: String,
    pub book_source_type: String,
    pub book_source_group: String,
    pub enabled: bool,
    pub custom_order: i64,
    pub last_update_time: i64,
    pub weight: i64,
    pub enabled_explore: bool,
    pub respond_time: i64,
    pub rule_search_url: String,
    pub rule_search_list: String,
    pub rule_search_name: String,
    pub rule_search_author: String,
    pub rule_search_cover_url: String,
    pub rule_search_kind: String,
    pub rule_search_note: String,
    pub rule_book_url_pattern: String,
    pub rule_book_name: String,
    pub rule_book_author: String,
    pub rule_book_cover_url: String,
    pub rule_book_kind: String,
    pub rule_book_note: String,
    pub rule_book_last_chapter: String,
    pub rule_chapter_list: String,
    pub rule_chapter_name: String,
    pub rule_chapter_url: String,
    pub rule_chapter_url_is_full: String,
    pub rule_content_url: String,
    pub rule_content: String,
    pub rule_content_remove: String,
    pub rule_page_url: String,
    pub rule_page_next: String,
    pub book_source_comment: String,
    pub raw_source_json: String,
}

impl BookSource {
    pub fn to_dto(&self) -> BookSourceDto {
        BookSourceDto::from(self)
    }

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
            rule_toc_is_volume: nested("ruleToc", "isVolume", "ruleChapterIsVolume"),
            rule_toc_update_time: nested("ruleToc", "updateTime", "ruleChapterUpdateTime"),
            rule_toc_is_vip: nested("ruleToc", "isVip", "ruleChapterIsVip"),
            rule_toc_is_pay: nested("ruleToc", "isPay", "ruleChapterIsPay"),
            rule_toc_next_toc_url: nested("ruleToc", "nextTocUrl", "rulePageNext"),
            rule_book_info_toc_url: nested("ruleBookInfo", "tocUrl", "ruleBookTocUrl"),
            rule_book_info_name: nested("ruleBookInfo", "name", "ruleBookName"),
            rule_book_info_author: nested("ruleBookInfo", "author", "ruleBookAuthor"),
            rule_book_info_cover_url: nested("ruleBookInfo", "coverUrl", "ruleBookCoverUrl"),
            rule_book_info_intro: nested("ruleBookInfo", "intro", "ruleBookNote"),
            rule_book_info_kind: nested("ruleBookInfo", "kind", "ruleBookKind"),
            rule_book_info_last_chapter: nested(
                "ruleBookInfo",
                "lastChapter",
                "ruleBookLastChapter",
            ),
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
            login_check_js: str_field(map, "loginCheckJs"),
            pre_update_js: rule_toc_obj
                .as_ref()
                .and_then(|o| o.get("preUpdateJs"))
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string(),
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
        field_needs_js(&self.raw_json)
    }

    pub fn needs_dart_js_for_search(&self) -> bool {
        any_field_needs_js(&[
            &self.rule_search_url,
            &self.rule_search_list,
            &self.rule_search_name,
            &self.rule_search_author,
            &self.rule_search_cover_url,
            &self.rule_search_kind,
            &self.rule_search_note,
            &self.rule_search_book_url,
        ]) || json_needs_js(&self.rule_search_obj)
    }

    pub fn needs_dart_js_for_toc(&self) -> bool {
        any_field_needs_js(&[
            &self.rule_toc_chapter_list,
            &self.rule_toc_chapter_name,
            &self.rule_toc_chapter_url,
            &self.rule_toc_next_toc_url,
            &self.rule_book_info_toc_url,
            &self.pre_update_js,
        ]) || json_needs_js(&self.rule_toc_obj)
    }

    pub fn needs_dart_js_for_content(&self) -> bool {
        any_field_needs_js(&[&self.rule_content, &self.rule_content_next_url])
            || json_needs_js(&self.rule_content_obj)
    }

    pub fn needs_dart_js_for_book_info(&self) -> bool {
        any_field_needs_js(&[
            &self.rule_book_info_toc_url,
            &self.rule_book_info_name,
            &self.rule_book_info_author,
            &self.rule_book_info_cover_url,
            &self.rule_book_info_intro,
            &self.rule_book_info_kind,
            &self.rule_book_info_last_chapter,
        ]) || json_needs_js(&self.rule_book_info_obj)
    }

    pub fn needs_dart_js_for_explore(&self) -> bool {
        any_field_needs_js(&[
            &self.rule_explore_url,
            &self.rule_explore_list,
            &self.rule_explore_name,
            &self.rule_explore_author,
            &self.rule_explore_cover_url,
            &self.rule_explore_book_url,
            &self.rule_explore_kind,
            &self.rule_explore_note,
            &self.rule_explore_intro,
        ]) || json_needs_js(&self.rule_explore_obj)
    }
}

impl From<&BookSource> for BookSourceDto {
    fn from(source: &BookSource) -> Self {
        let raw = serde_json::from_str::<Value>(&source.raw_json).unwrap_or(Value::Null);
        let rule_page_next = first_non_empty([
            root_string(&raw, "rulePageNext"),
            source.rule_toc_next_toc_url.clone(),
            source.rule_content_next_url.clone(),
        ]);

        Self {
            book_source_url: source.book_source_url.clone(),
            book_source_name: source.book_source_name.clone(),
            book_source_type: root_string_or(&raw, "bookSourceType", "0"),
            book_source_group: root_string(&raw, "bookSourceGroup"),
            enabled: root_bool_or(&raw, "enabled", true),
            custom_order: root_i64(&raw, "customOrder"),
            last_update_time: root_i64(&raw, "lastUpdateTime"),
            weight: root_i64(&raw, "weight"),
            enabled_explore: root_bool_or(&raw, "enabledExplore", true),
            respond_time: root_i64_or(&raw, "respondTime", 180000),
            rule_search_url: source.rule_search_url.clone(),
            rule_search_list: source.rule_search_list.clone(),
            rule_search_name: source.rule_search_name.clone(),
            rule_search_author: source.rule_search_author.clone(),
            rule_search_cover_url: source.rule_search_cover_url.clone(),
            rule_search_kind: source.rule_search_kind.clone(),
            rule_search_note: source.rule_search_note.clone(),
            rule_book_url_pattern: root_string_or(
                &raw,
                "ruleBookUrlPattern",
                &nested_string(&raw, "ruleBookInfo", "bookUrl"),
            ),
            rule_book_name: source.rule_book_info_name.clone(),
            rule_book_author: source.rule_book_info_author.clone(),
            rule_book_cover_url: source.rule_book_info_cover_url.clone(),
            rule_book_kind: source.rule_book_info_kind.clone(),
            rule_book_note: source.rule_book_info_intro.clone(),
            rule_book_last_chapter: source.rule_book_info_last_chapter.clone(),
            rule_chapter_list: source.rule_toc_chapter_list.clone(),
            rule_chapter_name: source.rule_toc_chapter_name.clone(),
            rule_chapter_url: source.rule_toc_chapter_url.clone(),
            rule_chapter_url_is_full: root_string(&raw, "ruleChapterUrlIsFull"),
            rule_content_url: root_string(&raw, "ruleContentUrl"),
            rule_content: source.rule_content.clone(),
            rule_content_remove: root_string(&raw, "ruleContentRemove"),
            rule_page_url: root_string(&raw, "rulePageUrl"),
            rule_page_next,
            book_source_comment: root_string(&raw, "bookSourceComment"),
            raw_source_json: source.raw_json.clone(),
        }
    }
}

fn first_non_empty<const N: usize>(values: [String; N]) -> String {
    values
        .into_iter()
        .find(|value| !value.is_empty())
        .unwrap_or_default()
}

fn root_value<'a>(raw: &'a Value, key: &str) -> Option<&'a Value> {
    raw.as_object().and_then(|object| object.get(key))
}

fn root_string(raw: &Value, key: &str) -> String {
    root_value(raw, key)
        .and_then(Value::as_str)
        .unwrap_or_default()
        .to_string()
}

fn root_string_or(raw: &Value, key: &str, default: &str) -> String {
    let value = root_string(raw, key);
    if value.is_empty() {
        default.to_string()
    } else {
        value
    }
}

fn root_i64(raw: &Value, key: &str) -> i64 {
    root_value(raw, key)
        .and_then(Value::as_i64)
        .unwrap_or_default()
}

fn root_i64_or(raw: &Value, key: &str, default: i64) -> i64 {
    root_value(raw, key)
        .and_then(Value::as_i64)
        .unwrap_or(default)
}

fn root_bool_or(raw: &Value, key: &str, default: bool) -> bool {
    match root_value(raw, key) {
        Some(Value::Bool(value)) => *value,
        Some(Value::Number(value)) => value.as_i64().map(|value| value != 0).unwrap_or(default),
        _ => default,
    }
}

fn nested_string(raw: &Value, outer: &str, inner: &str) -> String {
    root_value(raw, outer)
        .and_then(|value| value.get(inner))
        .and_then(Value::as_str)
        .unwrap_or_default()
        .to_string()
}

/// 是否含 `@js:` 规则片段。
///
/// Rust QuickJS 支持 `<js>...</js>`；`@js:` 是 Legado 的 URL 模板脚本，
/// 仍交由 Dart 兼容层处理，避免把未实现的变量上下文误当成普通 URL。
pub fn field_needs_js(s: &str) -> bool {
    s.as_bytes()
        .windows(b"@js:".len())
        .any(|window| window.eq_ignore_ascii_case(b"@js:"))
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

#[cfg(test)]
mod dto_tests {
    use super::*;

    #[test]
    fn book_source_dto_preserves_legacy_json_contract() {
        let source = BookSource::from_json(
            &serde_json::json!({
                "bookSourceUrl": "https://example.com",
                "bookSourceName": "示例",
                "enabled": false,
                "customOrder": 7,
                "ruleSearch": {"bookList": ".item", "name": "h2"},
                "ruleBookInfo": {"name": "h1", "bookUrl": "a"},
                "ruleToc": {"chapterList": ".chapter", "nextTocUrl": "next"},
                "ruleContent": {"content": ".content", "nextContentUrl": "nextPage"},
                "rulePageNext": "flatNext",
                "customField": {"keep": true}
            })
            .to_string(),
        )
        .unwrap();

        let encoded = serde_json::to_value(source.to_dto()).unwrap();

        assert_eq!(encoded["bookSourceUrl"], "https://example.com");
        assert_eq!(encoded["bookSourceName"], "示例");
        assert_eq!(encoded["enabled"], false);
        assert_eq!(encoded["customOrder"], 7);
        assert_eq!(encoded["ruleSearchList"], ".item");
        assert_eq!(encoded["ruleBookUrlPattern"], "a");
        assert_eq!(encoded["ruleChapterList"], ".chapter");
        assert_eq!(encoded["ruleContent"], ".content");
        assert_eq!(encoded["rulePageNext"], "flatNext");
        assert_eq!(encoded["rawSourceJson"], source.raw_json);
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
        assert_eq!(bs.rule_content, "$.data.content\n<js>Clean(result)</js>");
        // 扁平字符串仍要能识别为 JSON 规则
        assert!(matches!(
            bs.rule_content_obj,
            Some(Value::String(ref s)) if s.starts_with("$.data.content")
        ));
    }

    #[test]
    fn from_json_parses_login_check_and_pre_update_js() {
        let src = r#"{
            "bookSourceUrl":"https://example.com",
            "loginCheckJs":"result",
            "ruleToc":{"preUpdateJs":"cache.put('k','v',0); ''","chapterList":"a"}
        }"#;
        let bs = BookSource::from_json(src).unwrap();
        assert_eq!(bs.login_check_js, "result");
        assert!(bs.pre_update_js.contains("cache.put"));
    }

    #[test]
    fn js_capability_contract_distinguishes_at_js_from_js_block() {
        let source = BookSource::from_json(
            r#"{
                "bookSourceUrl":"https://example.com",
                "searchUrl":"@js:'https://example.com/search?q=' + key",
                "ruleToc":{"chapterList":".chapter@text"},
                "ruleContent":{"content":"<js>result.trim()</js>"}
            }"#,
        )
        .unwrap();

        assert!(source.needs_dart_js());
        assert!(source.needs_dart_js_for_search());
        assert!(!source.needs_dart_js_for_toc());
        assert!(!source.needs_dart_js_for_content());
    }

    #[test]
    fn nested_at_js_is_reported_for_the_matching_pipeline() {
        let source = BookSource::from_json(
            r#"{
                "bookSourceUrl":"https://example.com",
                "ruleToc":{"chapterList":"@js:result"},
                "ruleContent":{"content":"$.data.content"}
            }"#,
        )
        .unwrap();

        assert!(source.needs_dart_js_for_toc());
        assert!(!source.needs_dart_js_for_content());
    }

    #[test]
    fn at_js_detection_is_ascii_case_insensitive_without_changing_js_block_detection() {
        assert!(field_needs_js("@JS:result"));
        assert!(field_needs_js("@Js:result"));
        assert!(field_needs_js("@jS:result"));
        assert!(!field_needs_js("<js>result</js>"));
        assert!(field_has_js_block("<js>result</js>"));
    }

    #[test]
    fn raw_json_js_capability_detection_is_case_insensitive() {
        let source = BookSource::from_json(
            r#"{
                "bookSourceUrl":"https://example.com",
                "searchUrl":"@JS:'https://example.com/search?q=' + key"
            }"#,
        )
        .unwrap();
        assert!(source.needs_dart_js());
    }
}
