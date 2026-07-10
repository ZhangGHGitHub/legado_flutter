use crate::model::book_source::BookSource;
use crate::rule::engine;
use scraper::{Html, Selector};

/// 搜索结果条目（内部）
#[derive(Debug, Clone)]
pub struct HtmlSearchResult {
    pub name: String,
    pub author: String,
    pub cover_url: String,
    pub book_url: String,
    pub kind: String,
    pub note: String,
}

/// 从 HTML 页面解析搜索结果
pub fn parse_html_search(html: &str, source: &BookSource) -> Result<Vec<HtmlSearchResult>, String> {
    let document = Html::parse_document(html);
    let body = document
        .select(&Selector::parse("body").unwrap())
        .next()
        .ok_or("HTML 无 body 元素")?;

    let has_custom = !source.rule_search_list.is_empty();
    let items = if has_custom {
        engine::query_all(&document, &body, &source.rule_search_list)
    } else {
        engine::query_all(&document, &body, "")
    };

    let mut results = Vec::new();
    for item in items {
        let name = if has_custom {
            engine::extract_text(&item, &source.rule_search_name)
        } else {
            smart_text(&item, "a")
        };

        if name.is_empty() {
            continue;
        }

        let author = if has_custom {
            engine::extract_text(&item, &source.rule_search_author)
        } else {
            String::new()
        };

        let url_rule = if !source.rule_search_book_url.is_empty() {
            &source.rule_search_book_url
        } else {
            &source.rule_search_name
        };
        let book_url = engine::extract_attr(&item, url_rule, "href");

        let cover_url = if has_custom {
            engine::extract_attr(&item, &source.rule_search_cover_url, "src")
        } else {
            String::new()
        };

        let kind = if has_custom {
            engine::extract_text(&item, &source.rule_search_kind)
        } else {
            String::new()
        };

        let note = if has_custom {
            engine::extract_text(&item, &source.rule_search_note)
        } else {
            String::new()
        };

        if !book_url.is_empty() {
            results.push(HtmlSearchResult {
                name,
                author,
                cover_url,
                book_url,
                kind,
                note,
            });
        }
    }

    Ok(results)
}

fn smart_text(element: &scraper::ElementRef<'_>, selector: &str) -> String {
    if let Ok(sel) = Selector::parse(selector) {
        if let Some(el) = element.select(&sel).next() {
            return el.text().collect::<String>().trim().to_string();
        }
    }
    element.text().collect::<String>().trim().to_string()
}
