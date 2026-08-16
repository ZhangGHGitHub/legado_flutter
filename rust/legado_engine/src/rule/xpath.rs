use regex::Regex;
use scraper::{ElementRef, Selector};

/// 是否为 XPath 规则
pub fn is_xpath_rule(rule: &str) -> bool {
    let s = rule.trim();
    s.starts_with("//")
        || s.starts_with("@XPath:")
        || s.starts_with("@xpath:")
        || s.starts_with("XPath:")
        || s.starts_with("xpath:")
        || (s.starts_with('/') && !s.starts_with("/*") && s.contains('/'))
}

fn strip_xpath_prefix(rule: &str) -> &str {
    let s = rule.trim();
    for prefix in ["@XPath:", "@xpath:", "XPath:", "xpath:"] {
        if let Some(rest) = s.strip_prefix(prefix) {
            return rest.trim();
        }
    }
    s
}

/// 在元素上执行 XPath，返回匹配元素
pub fn query_all<'a>(root: &ElementRef<'a>, xpath: &str) -> Vec<ElementRef<'a>> {
    let xpath = strip_xpath_prefix(xpath);
    if xpath.is_empty() {
        return vec![];
    }

    let steps = match parse_steps(xpath) {
        Ok(s) => s,
        Err(_) => return vec![],
    };
    if steps.is_empty() {
        return vec![];
    }

    let last = steps.last().unwrap();
    if last.is_terminal {
        let mut current = vec![root.clone()];
        for step in &steps[..steps.len() - 1] {
            current = apply_step(&current, step);
            if current.is_empty() {
                return vec![];
            }
        }
        return current;
    }

    let mut current = vec![root.clone()];
    for step in &steps {
        current = apply_step(&current, step);
        if current.is_empty() {
            return vec![];
        }
    }
    current
}

/// 执行 XPath 并提取文本
pub fn extract_text(root: &ElementRef<'_>, xpath: &str) -> String {
    let xpath = strip_xpath_prefix(xpath);
    let steps = match parse_steps(xpath) {
        Ok(s) => s,
        Err(_) => return String::new(),
    };
    if steps.is_empty() {
        return String::new();
    }

    let last = steps.last().unwrap();
    if last.is_terminal && last.terminal_type.as_deref() == Some("text") {
        let mut current = vec![root.clone()];
        for step in &steps[..steps.len() - 1] {
            current = apply_step(&current, step);
            if current.is_empty() {
                return String::new();
            }
        }
        return current
            .iter()
            .map(|e| e.text().collect::<String>().trim().to_string())
            .filter(|s| !s.is_empty())
            .collect::<Vec<_>>()
            .join("\n");
    }

    query_all(root, xpath)
        .iter()
        .map(|e| e.text().collect::<String>().trim().to_string())
        .filter(|s| !s.is_empty())
        .collect::<Vec<_>>()
        .join("\n")
}

/// 执行 XPath 并提取属性（规则含 `@href` 终端）
pub fn extract_attr(root: &ElementRef<'_>, xpath: &str) -> String {
    let xpath = strip_xpath_prefix(xpath);
    let steps = match parse_steps(xpath) {
        Ok(s) => s,
        Err(_) => return String::new(),
    };
    if steps.is_empty() {
        return String::new();
    }

    let last = steps.last().unwrap();
    if last.is_terminal && last.terminal_type.as_deref() == Some("attr") {
        let mut current = vec![root.clone()];
        for step in &steps[..steps.len() - 1] {
            current = apply_step(&current, step);
            if current.is_empty() {
                return String::new();
            }
        }
        if let Some(el) = current.first() {
            let attr = last.attr_name.as_deref().unwrap_or("");
            return el.value().attr(attr).unwrap_or("").to_string();
        }
    }
    String::new()
}

#[derive(Debug, Clone)]
struct XPathStep {
    axis: String,
    tag_name: String,
    is_terminal: bool,
    terminal_type: Option<String>,
    attr_name: Option<String>,
    predicates: Vec<XPathPredicate>,
}

#[derive(Debug, Clone)]
struct XPathPredicate {
    pred_type: String,
    position: usize,
    attr_name: Option<String>,
    attr_value: Option<String>,
    tag_name: Option<String>,
}

fn parse_steps(xpath: &str) -> Result<Vec<XPathStep>, String> {
    let mut s = xpath.trim().to_string();
    if s.is_empty() {
        return Ok(vec![]);
    }

    let mut first_axis = "child".to_string();
    if s.starts_with("//") {
        first_axis = "descendant".to_string();
        s = s[2..].to_string();
    } else if s.starts_with('/') {
        s = s[1..].to_string();
    }

    let parts = split_path(&s);
    let mut steps = Vec::new();
    let mut next_descendant = false;
    for part in parts {
        if part.is_empty() {
            next_descendant = true;
            continue;
        }
        let mut step = parse_one_step(&part)?;
        if next_descendant {
            step.axis = "descendant".to_string();
            next_descendant = false;
        }
        steps.push(step);
    }

    if let Some(first) = steps.first_mut() {
        if first_axis != "child" {
            first.axis = first_axis;
        }
    }
    Ok(steps)
}

fn split_path(s: &str) -> Vec<String> {
    let mut parts = Vec::new();
    let mut depth = 0i32;
    let mut buf = String::new();
    for ch in s.chars() {
        if ch == '[' {
            depth += 1;
        }
        if ch == ']' {
            depth -= 1;
        }
        if ch == '/' && depth == 0 {
            parts.push(buf.clone());
            buf.clear();
        } else {
            buf.push(ch);
        }
    }
    parts.push(buf);
    parts
}

fn parse_one_step(raw: &str) -> Result<XPathStep, String> {
    let mut s = raw.trim().to_string();

    if s == "text()" {
        return Ok(XPathStep {
            axis: "child".to_string(),
            tag_name: "*".to_string(),
            is_terminal: true,
            terminal_type: Some("text".to_string()),
            attr_name: None,
            predicates: vec![],
        });
    }

    if s.starts_with('@') {
        return Ok(XPathStep {
            axis: "child".to_string(),
            tag_name: "*".to_string(),
            is_terminal: true,
            terminal_type: Some("attr".to_string()),
            attr_name: Some(s[1..].to_string()),
            predicates: vec![],
        });
    }

    let mut axis = "child".to_string();
    let mut tag_name = "*".to_string();

    if let Some(idx) = s.find("::") {
        let axis_part = &s[..idx];
        const VALID: &[&str] = &[
            "child",
            "descendant",
            "parent",
            "self",
            "ancestor",
            "ancestor-or-self",
            "descendant-or-self",
            "following",
            "following-sibling",
            "preceding",
            "preceding-sibling",
        ];
        if VALID.contains(&axis_part) {
            axis = axis_part.to_string();
            s = s[idx + 2..].to_string();
        }
    } else if s.starts_with("//") {
        axis = "descendant".to_string();
        s = s[2..].to_string();
    } else if s.starts_with('/') {
        s = s[1..].to_string();
    }

    if s == "." || s.starts_with(".[") || s.starts_with("./") {
        axis = "self".to_string();
        s = if s == "." {
            String::new()
        } else {
            s[1..].to_string()
        };
    } else if s == ".." || s.starts_with("..[") || s.starts_with("../") {
        axis = "parent".to_string();
        s = if s == ".." {
            String::new()
        } else {
            s[2..].to_string()
        };
    }

    let bracket_idx = s.find('[');
    let (tag_part, rest) = if let Some(idx) = bracket_idx {
        (s[..idx].to_string(), s[idx..].to_string())
    } else {
        (s.clone(), String::new())
    };

    if !tag_part.is_empty() && tag_part != "*" {
        tag_name = tag_part;
    }

    let predicates = parse_predicates(&rest);
    Ok(XPathStep {
        axis,
        tag_name,
        is_terminal: false,
        terminal_type: None,
        attr_name: None,
        predicates,
    })
}

fn parse_predicates(rest: &str) -> Vec<XPathPredicate> {
    let mut predicates = Vec::new();
    let mut i = 0;
    let chars: Vec<char> = rest.chars().collect();
    while i < chars.len() {
        if chars[i] == '[' {
            if let Some(end) = find_bracket_end(&chars, i) {
                let inner: String = chars[i + 1..end].iter().collect();
                predicates.push(parse_predicate(&inner));
                i = end + 1;
            } else {
                i += 1;
            }
        } else {
            i += 1;
        }
    }
    predicates
}

fn find_bracket_end(chars: &[char], start: usize) -> Option<usize> {
    let mut depth = 1;
    for i in start + 1..chars.len() {
        if chars[i] == '[' {
            depth += 1;
        }
        if chars[i] == ']' {
            depth -= 1;
            if depth == 0 {
                return Some(i);
            }
        }
    }
    None
}

fn parse_predicate(raw: &str) -> XPathPredicate {
    let s = raw.trim();
    if let Ok(num) = s.parse::<usize>() {
        return XPathPredicate {
            pred_type: "position".to_string(),
            position: num,
            attr_name: None,
            attr_value: None,
            tag_name: None,
        };
    }

    if let Some(caps) = Regex::new(r"position\s*\(\s*\)\s*=\s*(\d+)")
        .ok()
        .and_then(|re| re.captures(s))
    {
        let pos = caps
            .get(1)
            .and_then(|m| m.as_str().parse().ok())
            .unwrap_or(1);
        return XPathPredicate {
            pred_type: "position".to_string(),
            position: pos,
            attr_name: None,
            attr_value: None,
            tag_name: None,
        };
    }

    if let Some(caps) = Regex::new(r#"@([\w-]+)\s*=\s*"([^"]*)""#)
        .ok()
        .and_then(|re| re.captures(s))
        .or_else(|| {
            Regex::new(r#"@([\w-]+)\s*=\s*'([^']*)'"#)
                .ok()
                .and_then(|re| re.captures(s))
        })
    {
        return XPathPredicate {
            pred_type: "attr_eq".to_string(),
            position: 1,
            attr_name: caps.get(1).map(|m| m.as_str().to_string()),
            attr_value: caps.get(2).map(|m| m.as_str().to_string()),
            tag_name: None,
        };
    }

    if let Some(caps) = Regex::new(r#"contains\s*\(\s*@([\w-]+)\s*,\s*"([^"]*)"\s*\)"#)
        .ok()
        .and_then(|re| re.captures(s))
    {
        return XPathPredicate {
            pred_type: "contains".to_string(),
            position: 1,
            attr_name: caps.get(1).map(|m| m.as_str().to_string()),
            attr_value: caps.get(2).map(|m| m.as_str().to_string()),
            tag_name: None,
        };
    }

    if Regex::new(r"^[\w-]+$")
        .ok()
        .is_some_and(|re| re.is_match(s))
    {
        return XPathPredicate {
            pred_type: "has_child".to_string(),
            position: 1,
            attr_name: None,
            attr_value: None,
            tag_name: Some(s.to_string()),
        };
    }

    XPathPredicate {
        pred_type: "unknown".to_string(),
        position: 1,
        attr_name: None,
        attr_value: None,
        tag_name: None,
    }
}

fn apply_step<'a>(elements: &[ElementRef<'a>], step: &XPathStep) -> Vec<ElementRef<'a>> {
    if step.is_terminal {
        return elements.to_vec();
    }

    let mut result = Vec::new();
    for el in elements {
        let mut candidates = match step.axis.as_str() {
            "descendant" | "descendant-or-self" => query_descendants(el, &step.tag_name),
            "parent" => query_parent(el),
            "self" => vec![el.clone()],
            _ => query_children(el, &step.tag_name),
        };

        for pred in &step.predicates {
            candidates = apply_predicate(&candidates, pred);
            if candidates.is_empty() {
                break;
            }
        }
        result.extend(candidates);
    }
    result
}

fn query_children<'a>(el: &ElementRef<'a>, tag_name: &str) -> Vec<ElementRef<'a>> {
    let sel_str = if tag_name == "*" {
        "> *".to_string()
    } else {
        format!("> {tag_name}")
    };
    Selector::parse(&sel_str)
        .map(|s| el.select(&s).collect())
        .unwrap_or_default()
}

fn query_descendants<'a>(el: &ElementRef<'a>, tag_name: &str) -> Vec<ElementRef<'a>> {
    let sel_str = if tag_name == "*" {
        "*".to_string()
    } else {
        tag_name.to_string()
    };
    Selector::parse(&sel_str)
        .map(|s| el.select(&s).collect())
        .unwrap_or_default()
}

fn query_parent<'a>(el: &ElementRef<'a>) -> Vec<ElementRef<'a>> {
    let mut out = Vec::new();
    let mut node = el.parent();
    while let Some(n) = node {
        if let Some(parent_el) = ElementRef::wrap(n) {
            out.push(parent_el);
            break;
        }
        node = n.parent();
    }
    out
}

fn apply_predicate<'a>(elements: &[ElementRef<'a>], pred: &XPathPredicate) -> Vec<ElementRef<'a>> {
    match pred.pred_type.as_str() {
        "position" => {
            let idx = pred.position.saturating_sub(1);
            elements.get(idx).cloned().into_iter().collect()
        }
        "attr_eq" => elements
            .iter()
            .filter(|e| {
                let name = pred.attr_name.as_deref().unwrap_or("");
                let want = pred.attr_value.as_deref().unwrap_or("");
                e.value().attr(name).unwrap_or("") == want
            })
            .cloned()
            .collect(),
        "contains" => elements
            .iter()
            .filter(|e| {
                let name = pred.attr_name.as_deref().unwrap_or("");
                let needle = pred.attr_value.as_deref().unwrap_or("");
                e.value().attr(name).unwrap_or("").contains(needle)
            })
            .cloned()
            .collect(),
        "has_child" => {
            let tag = pred.tag_name.as_deref().unwrap_or("");
            let sel_str = if tag.is_empty() || tag == "*" {
                "> *".to_string()
            } else {
                format!("> {tag}")
            };
            elements
                .iter()
                .filter(|e| {
                    Selector::parse(&sel_str)
                        .map(|s| e.select(&s).next().is_some())
                        .unwrap_or(false)
                })
                .cloned()
                .collect()
        }
        _ => elements.to_vec(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use scraper::Html;

    #[test]
    fn descendant_with_attr_eq() {
        let doc = Html::parse_fragment(
            r#"<div class="hot_sale"><a href="/1">A</a></div><div class="other"></div>"#,
        );
        let root = doc.root_element();
        let out = extract_text(&root, "//div[@class=\"hot_sale\"]//a/text()");
        assert_eq!(out, "A");
    }

    #[test]
    fn contains_predicate() {
        let doc =
            Html::parse_fragment(r#"<div class="hot_sale_item">X</div><div class="cold">Y</div>"#);
        let root = doc.root_element();
        let items = query_all(&root, "//div[contains(@class, \"hot\")]");
        assert_eq!(items.len(), 1);
    }

    #[test]
    fn position_predicate() {
        let doc = Html::parse_fragment(r#"<ul><li>1</li><li>2</li><li>3</li></ul>"#);
        let root = doc.root_element();
        let out = extract_text(&root, "//li[2]/text()");
        assert_eq!(out, "2");
    }

    #[test]
    fn attr_terminal() {
        let doc = Html::parse_fragment(r#"<a href="/book/1">书名</a>"#);
        let root = doc.root_element();
        let out = extract_attr(&root, "//a/@href");
        assert_eq!(out, "/book/1");
    }

    #[test]
    fn non_terminal_text_joins_all_matching_nodes() {
        let doc =
            Html::parse_fragment(r#"<div class="item">第一项</div><div class="item">第二项</div>"#);
        let root = doc.root_element();
        assert_eq!(
            extract_text(&root, "//div[@class='item']"),
            "第一项\n第二项"
        );
    }
}
