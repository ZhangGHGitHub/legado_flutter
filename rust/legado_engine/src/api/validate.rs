use std::time::Instant;

use super::{SearchItem, SourceValidation};
use crate::api::{book_info, content, explore, search, toc};
use crate::model::book_source::BookSource;

fn push_err(errors: &mut Vec<String>, step: &str, msg: impl Into<String>) {
    errors.push(format!("{step}: {}", msg.into()));
}

fn explore_enabled(raw_json: &str) -> bool {
    let Ok(obj) = serde_json::from_str::<serde_json::Value>(raw_json) else {
        return true;
    };
    obj.get("enabledExplore")
        .and_then(|v| v.as_bool())
        .unwrap_or(true)
}

/// 从 exploreUrl JSON 取第一个可点击分类 URL
fn first_explore_category_url(explore_url_json: &str) -> Option<String> {
    let arr: Vec<serde_json::Value> = serde_json::from_str(explore_url_json).ok()?;
    for item in arr {
        let url = item.get("url")?.as_str()?.trim();
        if !url.is_empty() {
            return Some(url.to_string());
        }
    }
    None
}

fn pick_book(items: &[SearchItem]) -> Option<SearchItem> {
    items.iter().find(|b| !b.book_url.is_empty()).cloned()
}

/// 校验书源：搜索 → 发现（可选）→ 目录 → 正文
pub async fn validate_source(source_json: &str, keyword: &str) -> Result<SourceValidation, String> {
    let source = BookSource::from_json(source_json)?;
    let keyword = if keyword.trim().is_empty() {
        "测试"
    } else {
        keyword.trim()
    };

    let mut errors = Vec::new();
    let has_search = !source.rule_search_url.is_empty();
    let explore_url_raw = source.rule_explore_url.clone();
    let has_explore = explore_enabled(&source.raw_json)
        && !explore_url_raw.trim().is_empty()
        && first_explore_category_url(&explore_url_raw).is_some();

    let mut search_ok = !has_search;
    let mut discovery_ok = !has_explore;
    let mut search_time_ms = 0u64;
    let mut book: Option<SearchItem> = None;

    if has_search {
        let started = Instant::now();
        match search::search(source_json, keyword).await {
            Ok(items) if items.is_empty() => {
                search_ok = false;
                push_err(&mut errors, "搜索", "无结果");
            }
            Ok(items) => {
                search_time_ms = started.elapsed().as_millis() as u64;
                search_ok = true;
                book = pick_book(&items);
                if book.is_none() {
                    search_ok = false;
                    push_err(&mut errors, "搜索", "结果缺少 bookUrl");
                }
            }
            Err(e) => {
                search_time_ms = started.elapsed().as_millis() as u64;
                search_ok = false;
                push_err(&mut errors, "搜索", e);
            }
        }
    }

    if has_explore {
        let category_url = first_explore_category_url(&explore_url_raw).unwrap_or_default();
        match explore::explore(source_json, &category_url, 1).await {
            Ok(items) if items.is_empty() => {
                discovery_ok = false;
                push_err(&mut errors, "发现", "无结果");
            }
            Ok(items) => {
                discovery_ok = true;
                if book.is_none() {
                    book = pick_book(&items);
                }
            }
            Err(e) => {
                discovery_ok = false;
                push_err(&mut errors, "发现", e);
            }
        }
    }

    let Some(book) = book else {
        return Ok(SourceValidation {
            search_ok,
            discovery_ok,
            toc_ok: false,
            content_ok: false,
            search_time_ms,
            errors: {
                push_err(
                    &mut errors,
                    "校验",
                    "无法获取测试书籍（搜索/发现均无可用结果）",
                );
                errors
            },
        });
    };

    let info = match book_info::get_book_info(source_json, &book.book_url).await {
        Ok(info) => info,
        Err(e) => {
            push_err(&mut errors, "详情", e.into_legacy());
            return Ok(SourceValidation {
                search_ok,
                discovery_ok,
                toc_ok: false,
                content_ok: false,
                search_time_ms,
                errors,
            });
        }
    };

    let toc_url = if info.toc_url.is_empty() {
        book.book_url.clone()
    } else {
        info.toc_url.clone()
    };

    let chapters = match toc::get_toc(source_json, &toc_url).await {
        Ok(ch) if ch.is_empty() => {
            push_err(&mut errors, "目录", "为空");
            return Ok(SourceValidation {
                search_ok,
                discovery_ok,
                toc_ok: false,
                content_ok: false,
                search_time_ms,
                errors,
            });
        }
        Ok(ch) => ch,
        Err(e) => {
            push_err(&mut errors, "目录", e);
            return Ok(SourceValidation {
                search_ok,
                discovery_ok,
                toc_ok: false,
                content_ok: false,
                search_time_ms,
                errors,
            });
        }
    };

    let toc_ok = true;
    let first_chapter_url = chapters.first().map(|c| c.url.clone()).unwrap_or_default();

    let content_ok = match content::get_content(source_json, &first_chapter_url).await {
        Ok(text) if text.trim().len() >= 20 => true,
        Ok(text) => {
            push_err(
                &mut errors,
                "正文",
                format!("过短 ({} 字符)", text.trim().len()),
            );
            false
        }
        Err(e) => {
            push_err(&mut errors, "正文", e);
            false
        }
    };

    Ok(SourceValidation {
        search_ok,
        discovery_ok,
        toc_ok,
        content_ok,
        search_time_ms,
        errors,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn first_explore_category_skips_headers() {
        let json = r#"[
          {"title":"主站","url":""},
          {"title":"玄幻","url":"/sort/1_{{page}}/"},
          {"title":"都市","url":"/sort/2_{{page}}/"}
        ]"#;
        assert_eq!(
            first_explore_category_url(json).as_deref(),
            Some("/sort/1_{{page}}/")
        );
    }

    #[test]
    fn explore_disabled_when_flag_false() {
        let raw = r#"{"enabledExplore":false,"exploreUrl":"[]"}"#;
        assert!(!explore_enabled(raw));
    }
}
