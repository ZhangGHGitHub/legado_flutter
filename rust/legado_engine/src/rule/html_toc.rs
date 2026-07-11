use crate::model::book_source::BookSource;
use crate::rule::engine;
use scraper::{ElementRef, Html, Selector};
use std::collections::HashSet;

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
        query_toc_list_items(&document, &body, &effective_rule)
    } else {
        smart_chapter_items(&body)
    };

    let mut chapters = Vec::new();
    let mut seen_urls = HashSet::new();
    for item in items {
        let mut title = engine::extract_text(&item, &source.rule_toc_chapter_name);
        let name_rule = source.rule_toc_chapter_name.trim();
        if title.is_empty() && (name_rule == "text" || name_rule.is_empty()) {
            title = item.text().collect::<String>().trim().to_string();
        }
        let mut url = engine::extract_attr(&item, &source.rule_toc_chapter_url, "href");
        let url_rule = source.rule_toc_chapter_url.trim();
        if url.is_empty() && (url_rule == "href" || url_rule.is_empty()) {
            url = item.value().attr("href").unwrap_or("").to_string();
        }
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

        if !title.is_empty() && !url.is_empty() && seen_urls.insert(url.clone()) {
            chapters.push(HtmlChapter { title, url });
        }
    }

    if reverse {
        chapters.reverse();
    }
    Ok(chapters)
}

/// 目录列表查询：限定 body 范围；多容器时取章节最多的一块（避免「最新章节」干扰）
fn query_toc_list_items<'a>(
    document: &'a Html,
    body: &ElementRef<'a>,
    rule: &str,
) -> Vec<ElementRef<'a>> {
    if let Some((container, child)) = split_container_list_rule(rule) {
        let Ok(c_sel) = Selector::parse(&container) else {
            return engine::query_all(document, body, rule);
        };
        let child_sel = if child.is_empty() {
            Selector::parse("a").ok()
        } else {
            Selector::parse(&child).ok()
        };
        if let Some(child_sel) = child_sel {
            let mut best: Vec<ElementRef<'a>> = Vec::new();
            for container_el in body.select(&c_sel) {
                let items: Vec<_> = container_el.select(&child_sel).collect();
                if items.len() > best.len() {
                    best = items;
                }
            }
            if best.len() >= 2 {
                return best;
            }
        }
    }
    engine::query_all(document, body, rule)
}

/// 拆分「容器 + 子选择器」，如 `ul.chapter li a` → (`ul.chapter`, `li a`)
fn split_container_list_rule(rule: &str) -> Option<(String, String)> {
    let parts: Vec<&str> = rule.split_whitespace().collect();
    if parts.len() < 2 {
        return None;
    }
    let head = parts[0];
    if head.starts_with("ul.")
        || head.starts_with('.')
        || head.starts_with('#')
        || head.starts_with("ol.")
    {
        Some((head.to_string(), parts[1..].join(" ")))
    } else {
        None
    }
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

fn smart_chapter_items<'a>(body: &'a ElementRef<'a>) -> Vec<ElementRef<'a>> {
    if let Ok(ul_sel) = Selector::parse("ul.chapter") {
        let mut best: Vec<ElementRef<'a>> = Vec::new();
        if let Ok(a_sel) = Selector::parse("li a") {
            for ul in body.select(&ul_sel) {
                let items: Vec<_> = ul.select(&a_sel).collect();
                if items.len() > best.len() {
                    best = items;
                }
            }
            if best.len() >= 3 {
                return best;
            }
        }
    }
    for fallback in ["#list a", ".chapter-list a", "ul.chapter li a", "#list li a"] {
        if let Ok(sel) = Selector::parse(fallback) {
            let items: Vec<_> = body.select(&sel).collect();
            if items.len() >= 3 {
                return items;
            }
        }
    }
    vec![]
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::book_source::BookSource;

    const SOURCE: &str = r##"{
        "bookSourceUrl": "http://test.example.com/",
        "ruleToc": {
            "chapterList": "ul.chapter li a",
            "chapterName": "a@text",
            "chapterUrl": "a@href"
        }
    }"##;

    #[test]
    fn picks_largest_chapter_container_and_dedupes() {
        let html = r#"
        <html><body>
          <ul class="chapter">
            <li><a href="/b/99.html">第三十章 决战</a></li>
            <li><a href="/b/98.html">第二十九章 前夕</a></li>
          </ul>
          <ul class="chapter">
            <li><a href="/b/1.html">第一章 开始</a></li>
            <li><a href="/b/2.html">第二章 修炼</a></li>
            <li><a href="/b/3.html">第三章 突破</a></li>
            <li><a href="/b/99.html">第三十章 决战</a></li>
          </ul>
        </body></html>
        "#;
        let source = BookSource::from_json(SOURCE).unwrap();
        let chapters = parse_html_toc(html, &source).unwrap();
        assert_eq!(chapters.len(), 4);
        assert_eq!(chapters[0].title, "第一章 开始");
        assert_eq!(chapters[0].url, "/b/1.html");
        assert_eq!(chapters.last().unwrap().title, "第三十章 决战");
    }
}
