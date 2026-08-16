use base64::Engine;
use regex::Regex;
use scraper::{Html, Selector};

use super::AppError;
use crate::http::{analyze_url, client};
use crate::rule::{engine, js_engine, json_rule, source_rule};
use source_rule::{RuleMode, RuleState};

/// 执行字典规则，对齐原版 DictRule.search 的 AnalyzeUrl -> showRule 链路。
pub async fn query_dict_rule(rule_json: String, word: String) -> Result<String, AppError> {
    let key = word.trim();
    if key.is_empty() {
        return Err(AppError::Validation("请输入测试词".to_string()));
    }

    let rule: serde_json::Value = serde_json::from_str(&rule_json)
        .map_err(|error| AppError::Parse(format!("字典规则 JSON 无效: {error}")))?;
    let url_rule = rule
        .get("urlRule")
        .and_then(serde_json::Value::as_str)
        .unwrap_or("")
        .trim();
    if url_rule.is_empty() {
        return Err(AppError::Validation("URL 规则为空".to_string()));
    }
    let show_rule = rule
        .get("showRule")
        .and_then(serde_json::Value::as_str)
        .unwrap_or("");

    let request = analyze_url::resolve_request(url_rule, key, 1, "", "").map_err(map_rule_error)?;
    if request.url.trim().is_empty() {
        return Err(AppError::Parse("字典 URL 规则解析为空".to_string()));
    }
    let body = if request.url.starts_with("data:") {
        decode_data_url(&request.url)?
    } else {
        client::fetch_request_config(&request, None)
            .await
            .map_err(AppError::Network)?
    };
    if show_rule.trim().is_empty() {
        return Ok(body);
    }

    let base_url = if request.url.starts_with("http://") || request.url.starts_with("https://") {
        client::base_url(&request.url)
    } else {
        String::new()
    };
    apply_show_rule(show_rule, &body, &base_url)
}

fn decode_data_url(url: &str) -> Result<String, AppError> {
    let (metadata, payload) = url
        .split_once(',')
        .ok_or_else(|| AppError::Parse("data URL 缺少内容分隔符".to_string()))?;
    if metadata.to_ascii_lowercase().ends_with(";base64") {
        let bytes = base64::engine::general_purpose::STANDARD
            .decode(payload)
            .map_err(|error| AppError::Parse(format!("data URL Base64 无效: {error}")))?;
        return String::from_utf8(bytes)
            .map_err(|error| AppError::Parse(format!("data URL 不是 UTF-8: {error}")));
    }
    Ok(payload.to_string())
}

fn apply_show_rule(show_rule: &str, body: &str, base_url: &str) -> Result<String, AppError> {
    let rules = source_rule::split_source_rules(show_rule, false);
    if rules.is_empty() {
        return Ok(body.to_string());
    }

    let mut current = body.to_string();
    let mut state = RuleState::default();
    for source in rules {
        let input = current.clone();
        let materialized = state.materialize(&source, None, |expression, result, _variables| {
            js_engine::run_with_result_as_string(expression, result.unwrap_or(&input), "", base_url)
                .ok()
        });
        current = match materialized.mode {
            RuleMode::Js => {
                js_engine::run_with_result_as_string(&materialized.rule, &current, "", base_url)
                    .map_err(AppError::JsExecution)?
            }
            RuleMode::Json => {
                let value: serde_json::Value = serde_json::from_str(&current).map_err(|error| {
                    AppError::Parse(format!("字典 showRule JSON 输入无效: {error}"))
                })?;
                json_rule::resolve_field(&value, &materialized.rule, "", base_url)
            }
            RuleMode::Default | RuleMode::XPath => extract_html_rule(&current, &materialized.rule)?,
            RuleMode::Regex => Regex::new(&materialized.rule)
                .map_err(|error| AppError::Parse(format!("字典 showRule 正则无效: {error}")))?
                .find(&current)
                .map(|value| value.as_str().to_string())
                .unwrap_or_default(),
            RuleMode::WebJs => {
                return Err(AppError::Unsupported(
                    "字典 showRule 的 @webjs 需要 WebView".to_string(),
                ))
            }
        };
        if !materialized.replace_regex.is_empty() {
            let regex = Regex::new(&materialized.replace_regex)
                .map_err(|error| AppError::Parse(format!("字典 showRule 替换正则无效: {error}")))?;
            current = if materialized.replace_first {
                regex
                    .replace(&current, materialized.replacement.as_str())
                    .to_string()
            } else {
                regex
                    .replace_all(&current, materialized.replacement.as_str())
                    .to_string()
            };
        }
    }
    Ok(current)
}

fn extract_html_rule(html: &str, rule: &str) -> Result<String, AppError> {
    let document = Html::parse_document(html);
    let body = document
        .select(&Selector::parse("body").expect("body selector is valid"))
        .next()
        .unwrap_or_else(|| document.root_element());
    Ok(engine::extract_text(&body, rule))
}

fn map_rule_error(message: String) -> AppError {
    let lower = message.to_ascii_lowercase();
    if lower.contains("javascript") || lower.contains("quickjs") || lower.contains("js ") {
        AppError::JsExecution(message)
    } else {
        AppError::Parse(message)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::{Read, Write};
    use std::net::TcpListener;
    use std::sync::{Arc, Mutex};
    use std::thread;

    fn start_fixture(response_body: &'static str) -> (String, Arc<Mutex<String>>) {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let address = listener.local_addr().unwrap();
        let request = Arc::new(Mutex::new(String::new()));
        let captured = Arc::clone(&request);
        thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            stream
                .set_read_timeout(Some(std::time::Duration::from_secs(2)))
                .unwrap();
            let mut bytes = [0_u8; 8192];
            let size = stream.read(&mut bytes).unwrap();
            *captured.lock().unwrap() = String::from_utf8_lossy(&bytes[..size]).to_string();
            let response = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                response_body.len(),
                response_body
            );
            stream.write_all(response.as_bytes()).unwrap();
        });
        (format!("http://{address}"), request)
    }

    fn rule_json(url_rule: &str, show_rule: &str) -> String {
        serde_json::json!({
            "name": "fixture",
            "urlRule": url_rule,
            "showRule": show_rule,
        })
        .to_string()
    }

    #[tokio::test]
    async fn get_request_replaces_key_and_applies_html_show_rule() {
        let (base, request) = start_fixture("<html><body><b>字典释义</b></body></html>");
        let result = query_dict_rule(
            rule_json(&format!("{base}/dict?q={{{{key}}}}"), "tag.body@all"),
            "测试 词".to_string(),
        )
        .await
        .unwrap();

        assert_eq!(result, "<body><b>字典释义</b></body>");
        assert!(request.lock().unwrap().contains("GET /dict?q="));
    }

    #[tokio::test]
    async fn post_request_keeps_body_and_headers() {
        let (base, request) = start_fixture("posted");
        let options = serde_json::json!({
            "method": "POST",
            "headers": {"X-Dict-Test": "{{key}}"},
            "body": "word={{key}}"
        });
        let result = query_dict_rule(
            rule_json(&format!("{base}/dict,{options}"), ""),
            "term".to_string(),
        )
        .await
        .unwrap();

        assert_eq!(result, "posted");
        let request = request.lock().unwrap();
        assert!(request.starts_with("POST /dict HTTP/1.1"));
        assert!(request.to_ascii_lowercase().contains("x-dict-test:"));
        assert!(request.ends_with("word=term"));
    }

    #[tokio::test]
    async fn data_url_and_js_show_rule_are_supported() {
        let result = query_dict_rule(
            rule_json("data:text/plain;base64,5rWL6K+V", "@js:result + '完成'"),
            "unused".to_string(),
        )
        .await
        .unwrap();
        assert_eq!(result, "测试完成");
    }

    #[tokio::test]
    async fn js_url_rule_and_jsoup_show_rule_are_supported() {
        let html = "<html><body><b>Jsoup释义</b></body></html>";
        let encoded = base64::engine::general_purpose::STANDARD.encode(html);
        let url_rule = format!("@js:'data:text/html;base64,{encoded}'");
        let result = query_dict_rule(
            rule_json(
                &url_rule,
                "@js:var j=org.jsoup.Jsoup.parse(result); j.select('b').text();",
            ),
            "unused".to_string(),
        )
        .await
        .unwrap();
        assert_eq!(result, "Jsoup释义");
    }

    #[tokio::test]
    async fn rhino_dict_helpers_run_in_the_query_pipeline() {
        let show_rule = r#"@js:
let key = java.hexDecodeToString(result);
var aly = new JavaImporter(Packages.com.jayway.jsonpath);
with (aly) {
  var rr = JsonPath.using(
    Configuration.builder().options(Option.SUPPRESS_EXCEPTIONS).build()
  ).parse('{"data":{"pinyin":"pin"}}');
}
key + ':' + rr.read('$.data.pinyin');"#;
        let result = query_dict_rule(
            rule_json("data:;base64,{{java.base64Encode(key)}}", show_rule),
            "测试".to_string(),
        )
        .await
        .unwrap();
        assert_eq!(result, "测试:pin");
    }

    #[tokio::test]
    async fn rejects_empty_inputs_and_private_hosts() {
        assert!(matches!(
            query_dict_rule(rule_json("https://example.com", ""), " ".to_string())
            .await
            .unwrap_err(),
            AppError::Validation(ref message) if message == "请输入测试词"
        ));
        assert!(matches!(
            query_dict_rule(rule_json("", ""), "word".to_string())
                .await
                .unwrap_err(),
            AppError::Validation(ref message) if message == "URL 规则为空"
        ));
        assert!(matches!(
            query_dict_rule(
                rule_json("http://127.0.0.1/private", ""),
                "word".to_string(),
            )
            .await
            .unwrap_err(),
            AppError::Network(ref message) if message.contains("SSRF")
        ));
    }

    #[tokio::test]
    async fn preserves_parse_and_js_error_categories_and_text() {
        let parse_error = query_dict_rule("{".to_string(), "word".to_string())
            .await
            .unwrap_err();
        assert!(matches!(
            parse_error,
            AppError::Parse(ref message) if message.starts_with("字典规则 JSON 无效:")
        ));

        let js_error = query_dict_rule(rule_json("@js:(", ""), "word".to_string())
            .await
            .unwrap_err();
        assert!(matches!(
            js_error,
            AppError::JsExecution(ref message) if message.starts_with("JS 执行失败:")
        ));
    }
}
