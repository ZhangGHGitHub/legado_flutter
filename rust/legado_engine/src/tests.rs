#[cfg(test)]
mod engine_tests {
    use crate::model::book_source::BookSource;
    use crate::rule::{html_book_info, html_content, html_search, html_toc};

    const FIXTURE_SOURCE: &str = r##"{
        "bookSourceUrl": "http://test.example.com/",
        "bookSourceName": "测试书源",
        "searchUrl": "http://test.example.com/search?key={{key}}",
        "ruleSearch": {
            "bookList": ".item",
            "name": ".name@text",
            "author": ".author@text",
            "bookUrl": "a@href",
            "coverUrl": "img@src",
            "kind": ".kind@text"
        },
        "ruleBookInfo": {
            "name": "h1@text",
            "author": ".author@text",
            "coverUrl": "img.cover@src",
            "intro": ".intro@text",
            "kind": ".kind@text",
            "lastChapter": ".latest@text",
            "tocUrl": "a.read@href"
        },
        "ruleToc": {
            "chapterList": ".chapter-list li",
            "chapterName": "a@text",
            "chapterUrl": "a@href"
        },
        "ruleContent": {
            "content": "#content@text"
        },
        "ruleExplore": {
            "bookList": ".item",
            "name": ".name@text",
            "author": ".author@text",
            "bookUrl": "a@href"
        }
    }"##;

    const SEARCH_HTML: &str = r#"
    <html><body>
      <div class="item">
        <div class="name"><a href="/book/1">斗破苍穹</a></div>
        <div class="author">天蚕土豆</div>
        <div class="kind">玄幻</div>
        <img src="/cover/1.jpg"/>
      </div>
      <div class="item">
        <div class="name"><a href="/book/2">完美世界</a></div>
        <div class="author">辰东</div>
        <div class="kind">玄幻</div>
        <img src="/cover/2.jpg"/>
      </div>
    </body></html>
    "#;

    const BOOK_INFO_HTML: &str = r#"
    <html><body>
      <h1>斗破苍穹</h1>
      <div class="author">作者：天蚕土豆</div>
      <div class="kind">分类：玄幻</div>
      <div class="intro">这是一个测试简介。</div>
      <div class="latest">最新：第100章</div>
      <img class="cover" src="/cover/1.jpg"/>
      <a class="read" href="/book/1/toc">开始阅读</a>
    </body></html>
    "#;

    const TOC_HTML: &str = r#"
    <html><body>
      <ul class="chapter-list">
        <li><a href="/book/1/1">第一章</a></li>
        <li><a href="/book/1/2">第二章</a></li>
        <li><a href="/book/1/3">第三章</a></li>
      </ul>
    </body></html>
    "#;

    const CONTENT_HTML: &str = r#"
    <html><body>
      <div id="content">正文第一段。

正文第二段。</div>
    </body></html>
    "#;

    fn fixture_source() -> BookSource {
        BookSource::from_json(FIXTURE_SOURCE).expect("fixture source")
    }

    #[test]
    fn parse_html_search_returns_books() {
        let source = fixture_source();
        let results = html_search::parse_html_search(SEARCH_HTML, &source).unwrap();
        assert_eq!(results.len(), 2);
        assert_eq!(results[0].name, "斗破苍穹");
        assert_eq!(results[0].author, "天蚕土豆");
        assert_eq!(results[0].book_url, "/book/1");
    }

    #[test]
    fn parse_html_book_info_extracts_fields() {
        let source = fixture_source();
        let info = html_book_info::parse_html_book_info(BOOK_INFO_HTML, &source).unwrap();
        assert_eq!(info.name, "斗破苍穹");
        // Legado 链式规则由 legado_rule 模块单独测试
        assert_eq!(info.author, "作者：天蚕土豆");
        assert_eq!(info.intro, "这是一个测试简介。");
        assert_eq!(info.toc_url, "/book/1/toc");
    }

    #[test]
    fn parse_html_toc_returns_chapters() {
        let source = fixture_source();
        let chapters = html_toc::parse_html_toc(TOC_HTML, &source).unwrap();
        assert_eq!(chapters.len(), 3);
        assert_eq!(chapters[0].title, "第一章");
        assert_eq!(chapters[0].url, "/book/1/1");
    }

    #[test]
    fn parse_html_content_extracts_text() {
        let source = fixture_source();
        let content = html_content::parse_html_content(CONTENT_HTML, &source).unwrap();
        assert!(content.contains("正文第一段"));
        assert!(content.contains("正文第二段"));
    }

    #[test]
    fn parse_url_config_replaces_page_placeholder() {
        let cfg = crate::http::client::parse_url_config_with_page(
            "/sort/1_{{page}}/",
            "",
            3,
        );
        assert_eq!(cfg.url, "/sort/1_3/");
    }

    #[test]
    fn needs_dart_js_only_for_at_js_url() {
        let js_source = r#"{"bookSourceUrl":"http://x.com","searchUrl":"@js:java.ajax(...)"}"#;
        let js = BookSource::from_json(js_source).unwrap();
        assert!(js.needs_dart_js_for_search());
        assert!(!fixture_source().needs_dart_js_for_search());
    }

    #[test]
    fn scoped_js_rust_handles_bishu_html_js() {
        let raw = include_str!("../../../assets/builtin_sources/7565.json");
        let json = raw.trim_start_matches('\u{feff}');
        let source = if json.starts_with('[') {
            let arr: Vec<serde_json::Value> = serde_json::from_str(json).unwrap();
            BookSource::from_json(&arr[0].to_string()).unwrap()
        } else {
            BookSource::from_json(json).unwrap()
        };
        assert!(!source.needs_dart_js_for_search());
        assert!(!source.needs_dart_js_for_content());
        assert!(!source.needs_dart_js_for_toc());
        assert!(!source.needs_dart_js_for_book_info());
        assert!(!source.needs_dart_js_for_explore());
    }

    #[test]
    fn tomato_json_content_clean_js() {
        let raw = include_str!("../../../assets/builtin_sources/7497.json");
        let json = raw.trim_start_matches('\u{feff}');
        let source = if json.starts_with('[') {
            let arr: Vec<serde_json::Value> = serde_json::from_str(json).unwrap();
            BookSource::from_json(&arr[0].to_string()).unwrap()
        } else {
            BookSource::from_json(json).unwrap()
        };
        let data: serde_json::Value = serde_json::json!({
            "data": { "content": "<p>第一段</p><br><p>第二段</p>" }
        });
        let content =
            crate::rule::json_content::parse_json_content(&data, &source).unwrap();
        assert!(content.contains("第一段"));
        assert!(content.contains("第二段"));
        assert!(!content.contains("<p>"));
    }

    #[test]
    #[serial_test::serial(js_cache)]
    fn tomato_json_book_info_resolves_toc_url() {
        let raw = include_str!("../../../assets/builtin_sources/7497.json");
        let json = raw.trim_start_matches('\u{feff}');
        let source = if json.starts_with('[') {
            let arr: Vec<serde_json::Value> = serde_json::from_str(json).unwrap();
            BookSource::from_json(&arr[0].to_string()).unwrap()
        } else {
            BookSource::from_json(json).unwrap()
        };
        let _ = crate::rule::js_engine::reset_cache();
        let data: serde_json::Value = serde_json::json!({
            "data": {
                "articlename": "测试书",
                "author": "作者",
                "articleid": "12345",
                "intro": "简介",
                "lastchapter": "第1章"
            }
        });
        let book_url = "https://novel.cooks.tw/api/novel/detail/12345?lang=zh-CN";
        let info = crate::rule::json_book_info::parse_json_book_info(&data, &source, book_url)
            .unwrap();
        assert_eq!(info.name, "测试书");
        assert!(info.toc_url.contains("/api/chapter/list/12345"));
    }

    #[test]
    #[serial_test::serial(js_cache)]
    fn tomato_json_toc_chapter_url_uses_list_base() {
        let _ = crate::rule::js_engine::reset_cache();
        let raw = include_str!("../../../assets/builtin_sources/7497.json");
        let json = raw.trim_start_matches('\u{feff}');
        let source = if json.starts_with('[') {
            let arr: Vec<serde_json::Value> = serde_json::from_str(json).unwrap();
            BookSource::from_json(&arr[0].to_string()).unwrap()
        } else {
            BookSource::from_json(json).unwrap()
        };
        let data: serde_json::Value = serde_json::json!({
            "data": [{ "chapterid": "100", "chaptername": "第一章" }]
        });
        let list_url = "https://novel.cooks.tw/api/chapter/list/3814?lang=zh-CN";
        let chapters =
            crate::rule::json_toc::parse_json_toc(&data, &source, list_url).unwrap();
        assert_eq!(chapters.len(), 1);
        assert!(
            chapters[0].url.contains("/api/chapter/content/3814/100"),
            "chapterUrl 应含 articleid: {}",
            chapters[0].url
        );
    }
}

#[cfg(test)]
mod resolve_url_tests {
    use crate::http::client::resolve_url as client_resolve;
    use crate::rule::engine::resolve_url as engine_resolve;

    #[test]
    fn empty_cover_stays_empty() {
        assert_eq!(engine_resolve("", "https://site.com"), "");
        assert_eq!(client_resolve("  ", "https://site.com/path"), "");
    }

    #[test]
    fn protocol_relative_uses_base_scheme() {
        assert_eq!(
            engine_resolve("//cdn.example.com/a.jpg", "https://site.com/search"),
            "https://cdn.example.com/a.jpg"
        );
        assert_eq!(
            client_resolve("//cdn.example.com/a.jpg", "http://site.com/"),
            "http://cdn.example.com/a.jpg"
        );
    }

    #[test]
    fn absolute_http_unchanged() {
        assert_eq!(
            engine_resolve("https://img.com/c.jpg", "https://site.com"),
            "https://img.com/c.jpg"
        );
    }

    #[test]
    fn root_relative_joins_origin() {
        let out = engine_resolve("/cover/1.jpg", "https://site.com/books/");
        assert_eq!(out, "https://site.com/cover/1.jpg");
    }
}
