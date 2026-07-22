use std::io::{Cursor, Read};

use quick_xml::events::Event;
use quick_xml::Reader;
use regex::Regex;
use scraper::{Html, Selector};
use zip::ZipArchive;

use super::{LocalBookInfo, LocalChapterItem};

/// TXT 分章 — 匹配常见章节标题
pub fn parse_txt_chapters(content: &str) -> Vec<LocalChapterItem> {
    let patterns = [
        r"第[一二三四五六七八九十百千零0-9]+章\s*[^\n\r]*",
        r"第[一二三四五六七八九十百千零0-9]+节\s*[^\n\r]*",
        r"第[一二三四五六七八九十百千零0-9]+回\s*[^\n\r]*",
        r"(?i)Chapter\s+[0-9]+\s*[^\n\r]*",
        r"(?i)VOL\.[0-9]+\s*[^\n\r]*",
    ];

    let mut used: Option<Regex> = None;
    for p in patterns {
        if let Ok(re) = Regex::new(p) {
            if re.is_match(content) {
                used = Some(re);
                break;
            }
        }
    }

    let Some(re) = used else {
        return Vec::new();
    };

    let matches: Vec<_> = re.find_iter(content).collect();
    if matches.is_empty() {
        return Vec::new();
    }

    let mut chapters = Vec::with_capacity(matches.len());
    for (i, m) in matches.iter().enumerate() {
        let title = m.as_str().trim().to_string();
        let start = m.end();
        let end = matches
            .get(i + 1)
            .map(|n| n.start())
            .unwrap_or(content.len());
        let body = content[start..end].trim().to_string();
        if body.is_empty() {
            continue;
        }
        chapters.push(LocalChapterItem {
            title,
            content: body,
        });
    }
    chapters
}

/// EPUB 解析 — zip → OPF spine → 章节正文
pub fn parse_epub(data: &[u8]) -> Result<LocalBookInfo, String> {
    let cursor = Cursor::new(data);
    let mut archive = ZipArchive::new(cursor).map_err(|e| format!("EPUB 解压失败: {e}"))?;

    let container = read_zip_entry(&mut archive, "META-INF/container.xml")?;
    let opf_path = opf_path_from_container(&container)?;
    let opf_xml = read_zip_entry(&mut archive, &opf_path)?;
    let opf_base = path_dir(&opf_path);

    let meta = parse_opf(&opf_xml)?;
    let mut chapters = Vec::new();

    for (idx, item_id) in meta.spine.iter().enumerate() {
        let href = meta
            .manifest
            .get(item_id)
            .ok_or_else(|| format!("spine 项缺失: {item_id}"))?;
        let entry_path = join_zip_path(&opf_base, href);
        let html = read_zip_entry(&mut archive, &entry_path).unwrap_or_default();
        if html.trim().is_empty() {
            continue;
        }
        let text = html_to_plain(&html);
        if text.trim().len() < 10 {
            continue;
        }
        let title = chapter_title_from_html(&html).unwrap_or_else(|| format!("第{}章", idx + 1));
        chapters.push(LocalChapterItem {
            title,
            content: text,
        });
    }

    if chapters.is_empty() {
        return Err("EPUB 未解析到有效章节".into());
    }

    Ok(LocalBookInfo {
        title: meta.title,
        author: meta.author,
        chapters,
    })
}

struct OpfMeta {
    title: String,
    author: String,
    manifest: std::collections::HashMap<String, String>,
    spine: Vec<String>,
}

fn read_zip_entry(archive: &mut ZipArchive<Cursor<&[u8]>>, path: &str) -> Result<String, String> {
    let normalized = path.replace('\\', "/");
    let mut file = archive
        .by_name(&normalized)
        .map_err(|_| format!("EPUB 缺少文件: {normalized}"))?;
    let mut buf = String::new();
    file.read_to_string(&mut buf)
        .map_err(|e| format!("读取 {normalized} 失败: {e}"))?;
    Ok(buf)
}

fn opf_path_from_container(xml: &str) -> Result<String, String> {
    let re = Regex::new(r#"full-path="([^"]+)""#).unwrap();
    re.captures(xml)
        .and_then(|c| c.get(1))
        .map(|m| m.as_str().to_string())
        .ok_or_else(|| "container.xml 未找到 OPF 路径".into())
}

fn parse_opf(xml: &str) -> Result<OpfMeta, String> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);

    let mut title = String::new();
    let mut author = String::new();
    let mut manifest: std::collections::HashMap<String, String> = std::collections::HashMap::new();
    let mut spine = Vec::new();

    let mut buf = Vec::new();
    let mut in_title = false;
    let mut in_creator = false;
    let mut current_item_id: Option<String> = None;
    let mut current_item_href: Option<String> = None;

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref()).to_string();
                match name.as_str() {
                    "dc:title" => in_title = true,
                    "dc:creator" => in_creator = true,
                    "item" => {
                        current_item_id = attr_value(&e, "id");
                        current_item_href = attr_value(&e, "href");
                    }
                    "itemref" => {
                        if let Some(idref) = attr_value(&e, "idref") {
                            spine.push(idref);
                        }
                    }
                    _ => {}
                }
            }
            Ok(Event::Text(t)) => {
                let text = t.unescape().unwrap_or_default().into_owned();
                if in_title && title.is_empty() {
                    title = text.trim().to_string();
                }
                if in_creator && author.is_empty() {
                    author = text.trim().to_string();
                }
            }
            Ok(Event::End(e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref()).to_string();
                match name.as_str() {
                    "dc:title" => in_title = false,
                    "dc:creator" => in_creator = false,
                    "item" => {
                        if let (Some(id), Some(href)) =
                            (current_item_id.take(), current_item_href.take())
                        {
                            manifest.insert(id, href);
                        }
                    }
                    _ => {}
                }
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(format!("OPF 解析失败: {e}")),
            _ => {}
        }
        buf.clear();
    }

    if title.is_empty() {
        title = "本地 EPUB".into();
    }
    if author.is_empty() {
        author = "未知作者".into();
    }
    if spine.is_empty() {
        return Err("OPF spine 为空".into());
    }

    Ok(OpfMeta {
        title,
        author,
        manifest,
        spine,
    })
}

fn attr_value(e: &quick_xml::events::BytesStart, key: &str) -> Option<String> {
    e.attributes()
        .filter_map(|a| a.ok())
        .find(|a| a.key.as_ref() == key.as_bytes())
        .map(|a| String::from_utf8_lossy(&a.value).into_owned())
}

fn path_dir(path: &str) -> String {
    path.rfind('/')
        .map(|i| path[..i].to_string())
        .unwrap_or_default()
}

fn join_zip_path(base: &str, href: &str) -> String {
    if base.is_empty() {
        return href.replace('\\', "/");
    }
    format!(
        "{}/{}",
        base.trim_end_matches('/'),
        href.trim_start_matches('/')
    )
}

fn html_to_plain(html: &str) -> String {
    let doc = Html::parse_document(html);
    if let Ok(sel) = Selector::parse("body") {
        if let Some(body) = doc.select(&sel).next() {
            return collapse_blank_lines(&body.text().collect::<Vec<_>>().join(""));
        }
    }
    let strip = Regex::new(r"<[^>]+>").unwrap();
    collapse_blank_lines(&strip.replace_all(html, " "))
}

fn chapter_title_from_html(html: &str) -> Option<String> {
    let doc = Html::parse_document(html);
    for tag in ["h1", "h2", "h3", "title"] {
        if let Ok(sel) = Selector::parse(tag) {
            if let Some(el) = doc.select(&sel).next() {
                let t = el.text().collect::<String>().trim().to_string();
                if !t.is_empty() {
                    return Some(t);
                }
            }
        }
    }
    None
}

fn collapse_blank_lines(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut prev_blank = false;
    for line in text.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() {
            if !prev_blank {
                out.push('\n');
                prev_blank = true;
            }
        } else {
            if !out.is_empty() && !out.ends_with('\n') {
                out.push('\n');
            }
            out.push_str(trimmed);
            out.push('\n');
            prev_blank = false;
        }
    }
    out.trim().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn txt_splits_chapters() {
        let text = "前言\n\n第1章 开始\n正文一\n\n第2章 继续\n正文二";
        let chapters = parse_txt_chapters(text);
        assert_eq!(chapters.len(), 2);
        assert!(chapters[0].title.contains("第1章"));
        assert!(chapters[0].content.contains("正文一"));
        assert!(chapters[1].content.contains("正文二"));
    }

    #[test]
    fn txt_no_chapters_returns_empty() {
        assert!(parse_txt_chapters("没有章节标记的纯文本").is_empty());
    }
}
