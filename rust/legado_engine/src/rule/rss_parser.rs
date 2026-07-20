//! RSS 解析 — 对齐 Jingshiro [RssParserByRule] / [RssParserDefault]

use crate::http::client;
use crate::rule::engine;
use crate::rule::js_engine;
use quick_xml::events::Event;
use quick_xml::Reader;
use scraper::{Html, Selector};
use serde::Deserialize;

#[derive(Debug, Clone, Default)]
pub struct RssArticleItem {
    pub title: String,
    pub link: String,
    pub pub_date: String,
    pub description: String,
    pub content: String,
    pub image: String,
    pub origin: String,
    pub sort: String,
}

#[derive(Debug, Clone, Default, Deserialize)]
#[serde(default)]
pub struct RssSourceJson {
    #[serde(rename = "sourceUrl")]
    pub source_url: String,
    #[serde(rename = "sourceName")]
    pub source_name: String,
    #[serde(rename = "jsLib")]
    pub js_lib: String,
    #[serde(rename = "header")]
    pub header: String,
    #[serde(rename = "loginCheckJs")]
    pub login_check_js: String,
    #[serde(rename = "sortUrl")]
    pub sort_url: String,
    #[serde(rename = "singleUrl", default)]
    pub single_url: bool,
    #[serde(rename = "ruleArticles")]
    pub rule_articles: String,
    #[serde(rename = "ruleNextPage")]
    pub rule_next_page: String,
    #[serde(rename = "ruleTitle")]
    pub rule_title: String,
    #[serde(rename = "rulePubDate")]
    pub rule_pub_date: String,
    #[serde(rename = "ruleDescription")]
    pub rule_description: String,
    #[serde(rename = "ruleImage")]
    pub rule_image: String,
    #[serde(rename = "ruleLink")]
    pub rule_link: String,
    #[serde(rename = "ruleContent")]
    pub rule_content: String,
    #[serde(rename = "type", default)]
    pub article_type: i32,
}

fn parse_source(json: &str) -> Result<RssSourceJson, String> {
    serde_json::from_str(json).map_err(|e| format!("RSS 源 JSON 解析失败: {e}"))
}

/// 对齐 Jingshiro Rss.getArticlesAwait
pub async fn get_articles(
    source_json: &str,
    sort_url: &str,
    sort_name: &str,
    page: i32,
) -> Result<(Vec<RssArticleItem>, Option<String>), String> {
    let source = parse_source(source_json)?;
    let url = if sort_url.is_empty() {
        if source.sort_url.is_empty() {
            source.source_url.clone()
        } else {
            source.sort_url.clone()
        }
    } else {
        sort_url.to_string()
    };
    let url = substitute_page(&url, page);
    let cfg = client::parse_url_config(&url, "");
    let body = client::fetch_text(
        &cfg.url,
        &cfg.method,
        cfg.body.as_deref(),
        &cfg.charset,
        None,
        &source.source_url,
    )
    .await
    .map_err(|e| format!("获取 RSS 失败: {e}"))?;
    // 对齐 Jingshiro Rss：请求后执行 loginCheckJs（可改写 body）
    let body = if source.login_check_js.trim().is_empty() {
        body
    } else {
        // 构造最小 JSON 供 apply_login_check_js 读取字段
        let mini = serde_json::json!({
            "loginCheckJs": source.login_check_js,
            "jsLib": source.js_lib,
        })
        .to_string();
        js_engine::apply_login_check_js(&mini, &body, &url, "GET", None, "UTF-8").body
    };
    parse_xml(sort_name, &url, &url, &body, &source)
}

/// 对齐 Jingshiro Rss.getContentAwait
pub async fn get_content(source_json: &str, article_link: &str) -> Result<String, String> {
    let source = parse_source(source_json)?;
    if source.rule_content.is_empty() {
        return Ok(String::new());
    }
    let cfg = client::parse_url_config(article_link, "");
    let body = client::fetch_text(
        &cfg.url,
        &cfg.method,
        cfg.body.as_deref(),
        &cfg.charset,
        Some(&source.source_url),
        &source.source_url,
    )
    .await
    .map_err(|e| format!("获取正文失败: {e}"))?;
    let document = Html::parse_document(&body);
    let body_el = document
        .select(&Selector::parse("body").unwrap())
        .next()
        .ok_or("HTML 无 body")?;
    Ok(engine::extract_text(&body_el, &source.rule_content))
}

/// 对齐 Jingshiro RssParserByRule.parseXML
pub fn parse_xml(
    sort_name: &str,
    sort_url: &str,
    _redirect_url: &str,
    body: &str,
    source: &RssSourceJson,
) -> Result<(Vec<RssArticleItem>, Option<String>), String> {
    if body.trim().is_empty() {
        return Err("获取网页内容失败".into());
    }
    let mut rule_articles = source.rule_articles.trim().to_string();
    if rule_articles.is_empty() {
        return Ok((parse_default(sort_name, body, &source.source_url)?, None));
    }

    let mut reverse = false;
    if let Some(rest) = rule_articles.strip_prefix('-') {
        reverse = true;
        rule_articles = rest.to_string();
    }

    let document = Html::parse_document(body);
    let root = document
        .select(&Selector::parse("body").unwrap())
        .next()
        .ok_or("HTML 无 body")?;

    let list_rule = js_engine::css_suffix_after_js(&rule_articles);
    let collections = engine::query_all(&document, &root, list_rule);

    let mut next_url = None;
    if !source.rule_next_page.is_empty() {
        if source.rule_next_page.eq_ignore_ascii_case("PAGE") {
            next_url = Some(sort_url.to_string());
        } else {
            let n = engine::extract_text(&root, &source.rule_next_page);
            if !n.is_empty() {
                next_url = Some(engine::resolve_url(&n, sort_url));
            }
        }
    }

    let mut articles = Vec::new();
    for item in collections {
        let title = engine::extract_text(&item, &source.rule_title);
        if title.trim().is_empty() {
            continue;
        }
        let link_raw = if source.rule_link.is_empty() {
            engine::extract_attr(&item, &source.rule_title, "href")
        } else {
            let t = engine::extract_text(&item, &source.rule_link);
            if t.is_empty() {
                engine::extract_attr(&item, &source.rule_link, "href")
            } else {
                t
            }
        };
        let link = engine::resolve_url(&link_raw, &source.source_url);
        let pub_date = engine::extract_text(&item, &source.rule_pub_date);
        let description = if source.rule_description.is_empty() {
            String::new()
        } else {
            engine::extract_text(&item, &source.rule_description)
        };
        let image = if source.rule_image.is_empty() {
            String::new()
        } else {
            let img = engine::extract_attr(&item, &source.rule_image, "src");
            if img.is_empty() {
                let t = engine::extract_text(&item, &source.rule_image);
                engine::resolve_url(&t, &source.source_url)
            } else {
                engine::resolve_url(&img, &source.source_url)
            }
        };
        articles.push(RssArticleItem {
            title,
            link,
            pub_date,
            description,
            content: String::new(),
            image,
            origin: source.source_url.clone(),
            sort: sort_name.to_string(),
        });
    }
    if reverse {
        articles.reverse();
    }
    Ok((articles, next_url))
}

/// 对齐 Jingshiro RssParserDefault.parseXML（XmlPullParser 风格）
fn parse_default(
    sort_name: &str,
    xml: &str,
    source_url: &str,
) -> Result<Vec<RssArticleItem>, String> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);
    let mut buf = Vec::new();
    let mut articles = Vec::new();
    let mut current = RssArticleItem::default();
    let mut inside_item = false;
    let mut current_tag = String::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) => {
                let name = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                let name_l = name.to_lowercase();
                if name_l == "item" || name_l == "entry" {
                    inside_item = true;
                    current = RssArticleItem {
                        origin: source_url.to_string(),
                        sort: sort_name.to_string(),
                        ..Default::default()
                    };
                    current_tag.clear();
                    continue;
                }
                if !inside_item {
                    continue;
                }
                current_tag = name_l.clone();
                if name_l == "thumbnail" || name_l.ends_with(":thumbnail") {
                    if let Some(url) = attr_value(&e, "url") {
                        current.image = url;
                    }
                } else if name_l == "enclosure" {
                    let ty = attr_value(&e, "type").unwrap_or_default();
                    if ty.contains("image/") {
                        if let Some(url) = attr_value(&e, "url") {
                            current.image = url;
                        }
                    }
                } else if name_l == "link" {
                    if let Some(href) = attr_value(&e, "href") {
                        if current.link.is_empty() {
                            current.link = href;
                        }
                    }
                }
            }
            Ok(Event::Text(t)) => {
                if !inside_item || current_tag.is_empty() {
                    continue;
                }
                let text = t.unescape().unwrap_or_default().trim().to_string();
                apply_text(&mut current, &current_tag, text);
            }
            Ok(Event::CData(t)) => {
                if !inside_item || current_tag.is_empty() {
                    continue;
                }
                let text = String::from_utf8_lossy(&t).trim().to_string();
                apply_text(&mut current, &current_tag, text);
            }
            Ok(Event::End(e)) => {
                let name = String::from_utf8_lossy(e.local_name().as_ref()).to_lowercase();
                if name == "item" || name == "entry" {
                    inside_item = false;
                    if !current.title.is_empty() {
                        articles.push(std::mem::take(&mut current));
                    }
                }
                current_tag.clear();
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(format!("RSS XML 解析失败: {e}")),
            _ => {}
        }
        buf.clear();
    }
    Ok(articles)
}

fn apply_text(current: &mut RssArticleItem, tag: &str, text: String) {
    if text.is_empty() {
        return;
    }
    match tag {
        "title" => current.title = text,
        "link" => {
            if current.link.is_empty() {
                current.link = text;
            }
        }
        "description" | "summary" => {
            current.description = text.clone();
            if current.image.is_empty() {
                if let Some(img) = get_image_url(&text) {
                    current.image = img;
                }
            }
        }
        "encoded" | "content" => {
            current.content = text.clone();
            if current.image.is_empty() {
                if let Some(img) = get_image_url(&text) {
                    current.image = img;
                }
            }
        }
        "pubdate" | "published" | "updated" | "time" => current.pub_date = text,
        _ => {}
    }
}

fn attr_value(e: &quick_xml::events::BytesStart<'_>, key: &str) -> Option<String> {
    for a in e.attributes().flatten() {
        let k = String::from_utf8_lossy(a.key.as_ref());
        if k.eq_ignore_ascii_case(key) || k.ends_with(&format!(":{key}")) {
            return Some(a.unescape_value().ok()?.trim().to_string());
        }
    }
    None
}

fn get_image_url(input: &str) -> Option<String> {
    let re = regex::Regex::new(r#"(?i)<img[^>]+src\s*=\s*"([^"]+)""#).ok()?;
    re.captures(input)
        .and_then(|c| c.get(1))
        .map(|m| m.as_str().trim().to_string())
}

fn substitute_page(url: &str, page: i32) -> String {
    if url.contains("{{page}}") {
        url.replace("{{page}}", &page.to_string())
    } else {
        url.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_default_rss_item() {
        let xml = r#"<?xml version="1.0"?>
        <rss><channel>
          <item>
            <title>Hello</title>
            <link>https://example.com/a</link>
            <pubDate>Mon, 01 Jan 2024</pubDate>
            <description>Desc &lt;img src="https://example.com/i.png"/&gt;</description>
          </item>
        </channel></rss>"#;
        let list = parse_default("", xml, "https://origin").unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list[0].title, "Hello");
        assert_eq!(list[0].link, "https://example.com/a");
        assert!(list[0].image.contains("i.png"));
    }
}
