use crate::model::book_source::BookSource;
use crate::rule::engine;
use scraper::{Html, Selector};

#[derive(Debug, Clone)]
pub struct HtmlChapter {
    pub title: String,
    pub url: String,
}

pub fn parse_html_toc(html: &str, source: &BookSource) -> Result<Vec<HtmlChapter>, String> {
    let document = Html::parse_document(html);
    let body = document
        .select(&Selector::parse("body").unwrap())
        .next()
        .ok_or("HTML 无 body 元素")?;

    let list_rule = source.rule_toc_chapter_list.trim();
    let mut reverse = false;
    let mut effective_rule = list_rule.to_string();
    if effective_rule.starts_with('-') {
        reverse = true;
        effective_rule = effective_rule[1..].trim().to_string();
    }

    let items = if !effective_rule.is_empty() {
        engine::query_all(&document, &body, &effective_rule)
    } else {
        smart_chapter_items(&document)
    };

    let mut chapters = Vec::new();
    for item in items {
        let mut title = engine::extract_text(&item, &source.rule_toc_chapter_name);
        let mut url = engine::extract_attr(&item, &source.rule_toc_chapter_url, "href");
        if url.is_empty() {
            url = engine::extract_text(&item, &source.rule_toc_chapter_url);
        }

        if title.is_empty() {
            if let Ok(sel) = Selector::parse("a") {
                if let Some(link) = item.select(&sel).next() {
                    title = link.text().collect::<String>().trim().to_string();
                    if url.is_empty() {
                        url = link
                            .value()
                            .attr("href")
                            .unwrap_or("")
                            .to_string();
                    }
                }
            }
        }
        if title.is_empty() {
            title = item.text().collect::<String>().trim().to_string();
        }

        if !title.is_empty() && !url.is_empty() {
            chapters.push(HtmlChapter { title, url });
        }
    }

    if reverse {
        chapters.reverse();
    }
    Ok(chapters)
}

pub fn extract_next_toc_url(html: &str, source: &BookSource, base_url: &str) -> String {
    let rule = source.rule_toc_next_toc_url.trim();
    if rule.is_empty() {
        return String::new();
    }
    let document = Html::parse_document(html);
    let body = match document.select(&Selector::parse("body").unwrap()).next() {
        Some(b) => b,
        None => return String::new(),
    };

    let mut url = engine::extract_attr(&body, rule, "href");
    if url.is_empty() {
        url = engine::extract_text(&body, rule);
    }
    if url.is_empty() {
        return String::new();
    }
    engine::resolve_url(&url, base_url)
}

fn smart_chapter_items(document: &Html) -> Vec<scraper::ElementRef<'_>> {
    for fallback in ["#list a", ".chapter-list a", "ul.chapter li a", "#list li a"] {
        if let Ok(sel) = Selector::parse(fallback) {
            let items: Vec<_> = document.select(&sel).collect();
            if items.len() >= 3 {
                return items;
            }
        }
    }
    vec![]
}
