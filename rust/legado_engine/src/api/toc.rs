use super::ChapterItem;
use crate::api::book_info;
use crate::http;
use crate::model::book_source::BookSource;
use crate::rule;
use std::collections::HashSet;

use crate::rule::js_engine;

/// 获取目录
pub async fn get_toc(source_json: &str, book_url: &str) -> Result<Vec<ChapterItem>, String> {
    let source = BookSource::from_json(source_json)?;
    // 不清空 js_cache：详情 tocUrl 的 java.ajax 可能已写入 kelexs_key/iv
    if source.needs_dart_js_for_toc() {
        return Err("书源含 JS 规则，需 Dart 引擎".to_string());
    }

    if let Some(rate) = &source.concurrent_rate {
        http::rate_limit::configure(&source.book_source_url, rate);
    }

    let fetch_url = resolve_toc_fetch_url(&source, book_url).await?;
    let mut merged = Vec::new();
    let mut seen = HashSet::new();
    let mut visited_pages = HashSet::new();
    let mut current_url = fetch_url;
    let base_url = http::client::base_url(&current_url);
    let max_pages = 50;
    let mut last_body = String::new();

    for _page in 0..max_pages {
        if current_url.is_empty() || visited_pages.contains(&current_url) {
            break;
        }
        visited_pages.insert(current_url.clone());

        http::rate_limit::wait_if_needed(&source.book_source_url).await?;
        let body = http::client::fetch_with_source(
            &current_url,
            "GET",
            None,
            "UTF-8",
            &source.raw_json,
        )
        .await?;
        last_body = body.clone();

        let batch = if let Ok(data) = serde_json::from_str::<serde_json::Value>(&body) {
            if source.is_json_api() {
                rule::json_toc::parse_json_toc(&data, &source, &current_url)?
                    .into_iter()
                    .map(|c| ChapterItem {
                        title: c.title,
                        url: http::client::resolve_url(&c.url, &base_url),
                    })
                    .collect()
            } else {
                parse_html_toc_items(&body, &source, &base_url, &current_url)?
            }
        } else {
            parse_html_toc_items(&body, &source, &base_url, &current_url)?
        };

        let mut added = 0;
        for ch in batch {
            if seen.insert(ch.url.clone()) {
                merged.push(ch);
                added += 1;
            }
        }

        if added == 0 && !merged.is_empty() {
            break;
        }

        let next = if let Ok(data) = serde_json::from_str::<serde_json::Value>(&body) {
            if source.is_json_api() {
                rule::json_toc::extract_json_next_url(&data, &source.rule_toc_next_toc_url)
            } else {
                String::new()
            }
        } else {
            let book_url_guess = current_url.replace("/chapter/", "/book/");
            rule::html_toc::extract_next_toc_url_at(
                &body,
                &source,
                &current_url,
                &book_url_guess,
            )
        };

        if next.is_empty() {
            break;
        }
        // nextTocUrl 可能是 `url,{json}` AnalyzeUrl 形态
        let (next_url, next_method, next_body) = split_analyze_url(&next);
        let resolved = if next_url.starts_with("http") {
            next_url
        } else {
            http::client::resolve_url(&next_url, &base_url)
        };
        if visited_pages.contains(&resolved) {
            break;
        }

        if next_method.eq_ignore_ascii_case("POST") {
            // 分页 Ajax：连续 POST，直到无新增章节或无下一页
            let mut post_url = resolved;
            let mut post_payload = next_body;
            for _ in 0..max_pages {
                if !visited_pages.insert(post_url.clone()) {
                    break;
                }
                http::rate_limit::wait_if_needed(&source.book_source_url).await?;
                let post_resp = http::client::fetch_with_source(
                    &post_url,
                    "POST",
                    post_payload.as_deref(),
                    "UTF-8",
                    &source.raw_json,
                )
                .await?;
                last_body = post_resp.clone();
                let post_batch =
                    parse_html_toc_items(&post_resp, &source, &base_url, &post_url)?;
                let mut added = 0;
                for ch in post_batch {
                    if seen.insert(ch.url.clone()) {
                        merged.push(ch);
                        added += 1;
                    }
                }
                if added == 0 {
                    break;
                }
                let book_url_guess = book_url.replace("/chapter/", "/book/");
                let more = rule::html_toc::extract_next_toc_url_at(
                    &post_resp,
                    &source,
                    &post_url,
                    &book_url_guess,
                );
                if more.is_empty() {
                    break;
                }
                let (u, m, b) = split_analyze_url(&more);
                if !m.eq_ignore_ascii_case("POST") {
                    current_url = if u.starts_with("http") {
                        u
                    } else {
                        http::client::resolve_url(&u, &base_url)
                    };
                    break;
                }
                post_url = if u.starts_with("http") {
                    u
                } else {
                    http::client::resolve_url(&u, &base_url)
                };
                post_payload = b;
            }
            // POST 链结束后退出外层；若切回 GET 则由外层继续
            if current_url.is_empty() || visited_pages.contains(&current_url) {
                break;
            }
            continue;
        }
        current_url = resolved;
    }

    if merged.is_empty() {
        if let Some(msg) = upstream_toc_failure_message(&last_body) {
            return Err(msg);
        }
    }

    Ok(merged)
}

/// 站点返回错误页 / 明文异常时，避免静默「目录 0 条」
fn upstream_toc_failure_message(body: &str) -> Option<String> {
    let t = body.trim();
    if t.is_empty() {
        return Some("目录页为空响应".to_string());
    }
    if t.contains("数据库")
        || t.contains("SQLSTATE")
        || t.contains("Too many connections")
        || t.contains("连接失败")
    {
        let head: String = t.chars().take(160).collect();
        return Some(format!("目录页站点异常: {head}"));
    }
    if t.len() < 120 && !t.contains('<') && !t.starts_with('{') && !t.starts_with('[') {
        let head: String = t.chars().take(160).collect();
        return Some(format!("目录页异常文本: {head}"));
    }
    None
}

/// 拆分 `https://host/path,{"method":"POST","body":"..."}`（Legado AnalyzeUrl）
fn split_analyze_url(raw: &str) -> (String, String, Option<String>) {
    let raw = raw.trim();
    if let Some(comma) = raw.find(",{") {
        let url = raw[..comma].trim().to_string();
        if let Ok(cfg) = serde_json::from_str::<serde_json::Value>(&raw[comma + 1..]) {
            let method = cfg
                .get("method")
                .and_then(|v| v.as_str())
                .unwrap_or("GET")
                .to_string();
            let body = cfg
                .get("body")
                .and_then(|v| v.as_str())
                .map(|s| s.to_string());
            return (url, method, body);
        }
    }
    (raw.to_string(), "GET".to_string(), None)
}

/// 解析目录页 URL：支持 ruleBookInfo.tocUrl 为 `<js>`（可乐小说：/book/→/chapter/）
async fn resolve_toc_fetch_url(source: &BookSource, book_url: &str) -> Result<String, String> {
    let flat_rule = source.rule_book_info_toc_url.trim();
    let obj_toc = source
        .rule_book_info_obj
        .as_ref()
        .and_then(|o| o.get("tocUrl"))
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let toc_rule = if flat_rule.is_empty() {
        obj_toc
    } else {
        flat_rule
    };

    if js_engine::contains_js_block(toc_rule) {
        if let Some(script) = js_engine::extract_js_block(toc_rule) {
            // tocUrl JS 会 java.ajax(book.bookUrl) 抽 AES 密钥，须用详情页而非目录页
            let book_for_ajax = book_url
                .replace("/chapter/", "/book/")
                .replace("/read/", "/book/");
            if let Ok(out) = js_engine::run_with_result_opts(
                &script,
                "",
                &source.js_lib,
                book_url,
                Some(&book_for_ajax),
            ) {
                let out = out.trim().to_string();
                if !out.is_empty() && out != "null" {
                    return Ok(if out.starts_with("http") {
                        out
                    } else {
                        http::client::resolve_url(&out, book_url)
                    });
                }
            }
        }
    }

    if source.is_json_api() && (flat_rule.contains("<js>") || obj_toc.contains("<js>")) {
        let info = book_info::get_book_info(&source.raw_json, book_url).await?;
        if !info.toc_url.is_empty() {
            return Ok(info.toc_url);
        }
    }

    if !toc_rule.is_empty() && !js_engine::contains_js_block(toc_rule) {
        return Ok(if toc_rule.starts_with("http") {
            toc_rule.to_string()
        } else {
            http::client::resolve_url(toc_rule, book_url)
        });
    }

    // 已是目录页，或调用方已传入 tocUrl
    if book_url.contains("/chapter/") {
        return Ok(book_url.to_string());
    }
    Ok(book_url.to_string())
}

fn parse_html_toc_items(
    body: &str,
    source: &BookSource,
    base_url: &str,
    page_url: &str,
) -> Result<Vec<ChapterItem>, String> {
    Ok(rule::html_toc::parse_html_toc_at(body, source, page_url)?
        .into_iter()
        .map(|c| ChapterItem {
            title: c.title,
            url: if c.url.starts_with("http") {
                c.url
            } else {
                http::client::resolve_url(&c.url, base_url)
            },
        })
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn upstream_sql_error_detected() {
        let msg = upstream_toc_failure_message(
            "数据库连接失败:SQLSTATE[08004] [1040] Too many connections",
        );
        assert!(msg.unwrap().contains("站点异常"));
    }

    #[test]
    fn normal_html_not_flagged_as_upstream_error() {
        assert!(upstream_toc_failure_message(
            r#"<html><body><ul class="chapList chapListBody"><li><a href="/r/1">一</a></li></ul></body></html>"#
        )
        .is_none());
    }
}
