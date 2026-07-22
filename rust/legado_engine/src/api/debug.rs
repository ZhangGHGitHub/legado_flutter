use super::{DebugItem, DebugResult, RuleDebugStep};
use crate::http;
use crate::model::book_source::BookSource;
use crate::rule;

fn push_step(steps: &mut Vec<RuleDebugStep>, step: &str, rule: &str, result: &str, ok: bool) {
    steps.push(RuleDebugStep {
        step: step.to_string(),
        rule: rule.to_string(),
        result: result.to_string(),
        ok,
    });
}

fn preview_body(body: &str, max: usize) -> String {
    if body.len() <= max {
        body.to_string()
    } else {
        format!(
            "{}\n\n... (truncated, {} chars total)",
            &body[..max],
            body.len()
        )
    }
}

fn search_items_to_debug(items: Vec<super::SearchItem>) -> Vec<DebugItem> {
    items
        .into_iter()
        .map(|r| DebugItem {
            name: r.name,
            author: r.author,
            cover_url: r.cover_url,
            book_url: r.book_url,
            kind: r.kind,
            note: r.note,
        })
        .collect()
}

/// 分步调试搜索
pub async fn debug_search(source_json: &str, keyword: &str) -> Result<DebugResult, String> {
    let source = BookSource::from_json(source_json)?;
    let mut steps = Vec::new();

    if source.rule_search_url.is_empty() {
        push_step(&mut steps, "检查搜索 URL", "ruleSearchUrl", "未配置", false);
        return Ok(DebugResult {
            request_url: String::new(),
            request_method: "GET".to_string(),
            response_status: String::new(),
            response_charset: String::new(),
            response_size: 0,
            response_body_preview: String::new(),
            rule_steps: steps,
            results: vec![],
        });
    }

    push_step(
        &mut steps,
        "原始搜索 URL",
        "ruleSearchUrl",
        &source.rule_search_url,
        true,
    );

    let cfg = match http::analyze_url::resolve_search_request(&source, keyword, 1) {
        Ok(c) => c,
        Err(e) => {
            push_step(&mut steps, "解析搜索 URL", "ruleSearchUrl", &e, false);
            return Err(e);
        }
    };

    let mut resolved_url = cfg.url.clone();
    if !resolved_url.starts_with("http") {
        resolved_url = http::client::resolve_url(&resolved_url, &source.book_source_url);
    }

    push_step(
        &mut steps,
        "解析搜索 URL",
        &source.rule_search_url,
        &format!("{} {} charset={}", cfg.method, resolved_url, cfg.charset),
        !resolved_url.is_empty(),
    );

    if resolved_url.is_empty() {
        return Ok(DebugResult {
            request_url: resolved_url,
            request_method: cfg.method,
            response_status: String::new(),
            response_charset: cfg.charset,
            response_size: 0,
            response_body_preview: String::new(),
            rule_steps: steps,
            results: vec![],
        });
    }

    if let Some(rate) = &source.concurrent_rate {
        http::rate_limit::configure(&source.book_source_url, rate);
    }
    http::rate_limit::wait_if_needed(&source.book_source_url).await?;

    let fetch = http::client::fetch_with_source_meta(
        &resolved_url,
        &cfg.method,
        cfg.body.as_deref(),
        &cfg.charset,
        &source.raw_json,
    )
    .await?;

    push_step(
        &mut steps,
        "HTTP 响应",
        &resolved_url,
        &format!("status={} size={} bytes", fetch.status_code, fetch.byte_len),
        fetch.status_code == 200,
    );

    let body = &fetch.body;
    let preview = preview_body(body, 2000);

    // JSON API 路径
    if let Ok(data) = serde_json::from_str::<serde_json::Value>(body) {
        push_step(&mut steps, "响应类型", "Content-Type", "JSON", true);

        if source.is_json_api() {
            let list_rule = source
                .rule_search_obj
                .as_ref()
                .and_then(|o| o.get("bookList"))
                .and_then(|v| v.as_str())
                .unwrap_or("");
            push_step(
                &mut steps,
                "JSON 列表规则",
                "ruleSearch.bookList",
                list_rule,
                !list_rule.is_empty(),
            );

            match rule::json_search::parse_json_search(&data, &source) {
                Ok(items) if !items.is_empty() => {
                    let base = http::client::base_url(&source.book_source_url);
                    let results: Vec<super::SearchItem> = items
                        .into_iter()
                        .map(|r| super::SearchItem {
                            name: r.name,
                            author: r.author,
                            cover_url: rule::engine::resolve_url(&r.cover_url, &base),
                            book_url: rule::engine::resolve_url(&r.book_url, &base),
                            kind: r.kind,
                            note: r.note,
                        })
                        .collect();
                    push_step(
                        &mut steps,
                        "解析搜索结果",
                        "ruleSearch",
                        &format!("{} 条", results.len()),
                        true,
                    );
                    return Ok(DebugResult {
                        request_url: resolved_url,
                        request_method: cfg.method,
                        response_status: fetch.status_code.to_string(),
                        response_charset: cfg.charset,
                        response_size: fetch.byte_len as i32,
                        response_body_preview: preview,
                        rule_steps: steps,
                        results: search_items_to_debug(results),
                    });
                }
                Ok(_) => {
                    push_step(&mut steps, "解析搜索结果", "ruleSearch", "0 条", false);
                }
                Err(e) => {
                    push_step(&mut steps, "解析搜索结果", "ruleSearch", &e, false);
                }
            }
        }
    } else {
        push_step(&mut steps, "响应类型", "Content-Type", "HTML/Text", true);
    }

    // HTML 路径
    push_step(
        &mut steps,
        "HTML 列表规则",
        "ruleSearchList",
        &source.rule_search_list,
        !source.rule_search_list.is_empty(),
    );

    match rule::html_search::parse_html_search(body, &source) {
        Ok(items) => {
            let base = http::client::base_url(&source.book_source_url);
            let results: Vec<super::SearchItem> = items
                .into_iter()
                .map(|r| super::SearchItem {
                    name: r.name,
                    author: r.author,
                    cover_url: rule::engine::resolve_url(&r.cover_url, &base),
                    book_url: rule::engine::resolve_url(&r.book_url, &base),
                    kind: r.kind,
                    note: r.note,
                })
                .collect();
            push_step(
                &mut steps,
                "解析搜索结果",
                "ruleSearchList",
                &format!("{} 条", results.len()),
                !results.is_empty(),
            );
            if !results.is_empty() {
                let first = &results[0];
                push_step(
                    &mut steps,
                    "首条样例",
                    "ruleSearchName",
                    &format!(
                        "name={} author={} url={}",
                        first.name, first.author, first.book_url
                    ),
                    true,
                );
            }
            Ok(DebugResult {
                request_url: resolved_url,
                request_method: cfg.method,
                response_status: fetch.status_code.to_string(),
                response_charset: cfg.charset,
                response_size: fetch.byte_len as i32,
                response_body_preview: preview,
                rule_steps: steps,
                results: search_items_to_debug(results),
            })
        }
        Err(e) => {
            push_step(&mut steps, "解析搜索结果", "ruleSearchList", &e, false);
            Ok(DebugResult {
                request_url: resolved_url,
                request_method: cfg.method,
                response_status: fetch.status_code.to_string(),
                response_charset: cfg.charset,
                response_size: fetch.byte_len as i32,
                response_body_preview: preview,
                rule_steps: steps,
                results: vec![],
            })
        }
    }
}

/// 分步调试目录
pub async fn debug_toc(source_json: &str, book_url: &str) -> Result<DebugResult, String> {
    use super::ChapterItem;

    let source = BookSource::from_json(source_json)?;
    let mut steps = Vec::new();

    push_step(
        &mut steps,
        "书籍 URL",
        "bookUrl",
        book_url,
        !book_url.is_empty(),
    );

    if book_url.is_empty() {
        return Ok(DebugResult {
            request_url: String::new(),
            request_method: "GET".to_string(),
            response_status: String::new(),
            response_charset: "UTF-8".to_string(),
            response_size: 0,
            response_body_preview: String::new(),
            rule_steps: steps,
            results: vec![],
        });
    }

    push_step(
        &mut steps,
        "目录列表规则",
        "ruleChapterList",
        &source.rule_toc_chapter_list,
        !source.rule_toc_chapter_list.is_empty(),
    );

    let chapters: Vec<ChapterItem> = match super::toc::get_toc(source_json, book_url).await {
        Ok(c) => c,
        Err(e) => {
            push_step(&mut steps, "获取目录", "get_toc", &e, false);
            return Ok(DebugResult {
                request_url: book_url.to_string(),
                request_method: "GET".to_string(),
                response_status: String::new(),
                response_charset: "UTF-8".to_string(),
                response_size: 0,
                response_body_preview: String::new(),
                rule_steps: steps,
                results: vec![],
            });
        }
    };

    push_step(
        &mut steps,
        "解析目录",
        "ruleChapterList",
        &format!("{} 章", chapters.len()),
        !chapters.is_empty(),
    );

    let results: Vec<DebugItem> = chapters
        .into_iter()
        .map(|c| DebugItem {
            name: c.title,
            author: String::new(),
            cover_url: String::new(),
            book_url: c.url,
            kind: String::new(),
            note: String::new(),
        })
        .collect();

    Ok(DebugResult {
        request_url: book_url.to_string(),
        request_method: "GET".to_string(),
        response_status: "200".to_string(),
        response_charset: "UTF-8".to_string(),
        response_size: 0,
        response_body_preview: String::new(),
        rule_steps: steps,
        results,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn preview_body_truncates() {
        let long = "a".repeat(3000);
        let p = preview_body(&long, 100);
        assert!(p.contains("truncated"));
        assert!(p.len() < 3000);
    }
}
