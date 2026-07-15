use crate::model::book_source::BookSource;
use crate::rule::{engine, js_engine};
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
    let base = source.book_source_url.as_str();
    let js_lib = source.js_lib.as_str();
    let html = preprocess_book_list_html(html, &source.rule_search_list, js_lib, base);
    let list_rule = js_engine::css_suffix_after_js(&source.rule_search_list);

    let document = Html::parse_document(&html);
    let body = document
        .select(&Selector::parse("body").unwrap())
        .next()
        .ok_or("HTML 无 body 元素")?;

    let has_custom = !list_rule.is_empty();
    let items = if has_custom {
        engine::query_all(&document, &body, list_rule)
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
        let book_url = resolve_field_with_js(&item, url_rule, js_lib, base);

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

/// 对齐 Jingshiro：列表项字段可为整段 `<js>`（`result` = 该项 outerHTML）
fn resolve_field_with_js(
    item: &scraper::ElementRef<'_>,
    rule: &str,
    js_lib: &str,
    base_url: &str,
) -> String {
    let rule = rule.trim();
    if js_engine::contains_js_block(rule) {
        if let Some(script) = js_engine::extract_js_block(rule) {
            let outer = item.html();
            if let Ok(out) = js_engine::run_with_result(&script, &outer, js_lib, base_url) {
                let out = out.trim().to_string();
                if !out.is_empty() && out != "null" && out != "undefined" {
                    return out;
                }
            }
        }
        return String::new();
    }
    let mut url = engine::extract_attr(item, rule, "href");
    if url.is_empty() {
        url = engine::extract_text(item, rule);
    }
    url
}

pub fn preprocess_book_list_html(
    html: &str,
    book_list_rule: &str,
    js_lib: &str,
    base_url: &str,
) -> String {
    if !js_engine::contains_js_block(book_list_rule) {
        return html.to_string();
    }
    let Some(script) = js_engine::extract_js_block(book_list_rule) else {
        return html.to_string();
    };
    js_engine::run_html_js(&script, html, js_lib, base_url).unwrap_or_else(|_| html.to_string())
}

fn smart_text(element: &scraper::ElementRef<'_>, selector: &str) -> String {
    if let Ok(sel) = Selector::parse(selector) {
        if let Some(el) = element.select(&sel).next() {
            return el.text().collect::<String>().trim().to_string();
        }
    }
    element.text().collect::<String>().trim().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn search_book_url_js_extracts_kelexs_link() {
        let source_json = r##"{
            "bookSourceUrl": "https://www.rrssk.com/",
            "ruleSearch": {
                "bookList": ".rankIBox.searchIBox li",
                "name": ".txtb .name.font18 a@text",
                "bookUrl": "<js>var html=result.toString();var match=html.match(/upclick\\('([^']+)'\\)/);var id='';if(match != null){id=match[1];}'https://www.kelexs.com/book/'+id+'.html'</js>"
            }
        }"##;
        let html = r##"<html><body><ul class="rankIBox searchIBox">
<li onclick="upclick('AIJGIFF')">
  <div class="txtb"><div class="name font18"><a href="javascript:;">重生之我在仙界</a></div></div>
</li>
</ul></body></html>"##;
        let source = BookSource::from_json(source_json).unwrap();
        let rows = parse_html_search(html, &source).unwrap();
        assert_eq!(rows.len(), 1);
        assert_eq!(rows[0].book_url, "https://www.kelexs.com/book/AIJGIFF.html");
        assert!(rows[0].name.contains("重生"));
    }
}
