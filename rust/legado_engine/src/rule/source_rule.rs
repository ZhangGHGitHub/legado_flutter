use std::collections::HashMap;

/// A rule segment after the same normalization performed by Legado's SourceRule.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RuleMode {
    XPath,
    Json,
    Default,
    Js,
    Regex,
    WebJs,
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum TemplatePart {
    Literal(String),
    Get(String),
    Js(String),
    ResultParam(usize, String),
}

/// One ordered source-rule segment and its `@put` side effects.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SourceRule {
    pub mode: RuleMode,
    pub rule: String,
    pub put_map: HashMap<String, String>,
    pub replace_regex: String,
    pub replacement: String,
    pub replace_first: bool,
    parts: Vec<TemplatePart>,
}

/// The mutable variables shared by a rule chain.
#[derive(Debug, Default, Clone)]
pub struct RuleState {
    variables: HashMap<String, String>,
}

/// Rule text ready for the mode-specific analyzer.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MaterializedRule {
    pub mode: RuleMode,
    pub rule: String,
    pub replace_regex: String,
    pub replacement: String,
    pub replace_first: bool,
}

impl RuleState {
    pub fn get(&self, key: &str) -> &str {
        self.variables.get(key).map(String::as_str).unwrap_or("")
    }

    pub fn variables(&self) -> &HashMap<String, String> {
        &self.variables
    }

    /// Apply a segment's `@put` map immediately before that segment executes.
    pub fn apply_put(&mut self, put_map: &HashMap<String, String>) {
        for (key, value) in put_map {
            let expanded = expand_simple_template(value, &self.variables);
            self.variables.insert(key.clone(), expanded);
        }
    }

    /// Materialize a segment after its side effects have become visible.
    pub fn materialize<F>(
        &mut self,
        source_rule: &SourceRule,
        result: Option<&[Option<String>]>,
        mut eval_js: F,
    ) -> MaterializedRule
    where
        F: FnMut(&str, Option<&str>, &HashMap<String, String>) -> Option<String>,
    {
        self.apply_put(&source_rule.put_map);
        source_rule.materialize(result, &self.variables, |expr, result_text| {
            eval_js(expr, result_text, &self.variables)
        })
    }
}

impl SourceRule {
    pub fn new(rule_str: &str, mut mode: RuleMode) -> Self {
        let mut rule = normalize_mode(rule_str, &mut mode);
        let put_map = split_put_rule(&mut rule);
        let parts = split_template_parts(&rule);
        Self {
            mode,
            rule,
            put_map,
            replace_regex: String::new(),
            replacement: String::new(),
            replace_first: false,
            parts,
        }
    }

    /// Expand `@get`, `{{...}}` and `$1` parameters, then split `##` metadata.
    pub fn materialize<F>(
        &self,
        result: Option<&[Option<String>]>,
        variables: &HashMap<String, String>,
        mut eval_js: F,
    ) -> MaterializedRule
    where
        F: FnMut(&str, Option<&str>) -> Option<String>,
    {
        let mut expanded = String::new();
        for part in &self.parts {
            match part {
                TemplatePart::Literal(value) => expanded.push_str(value),
                TemplatePart::Get(key) => {
                    expanded.push_str(variables.get(key).map(String::as_str).unwrap_or_default())
                }
                TemplatePart::Js(expr) => {
                    let result_text = result
                        .and_then(|items| items.iter().filter_map(|item| item.as_deref()).next());
                    if let Some(value) = variables
                        .get(expr.trim())
                        .cloned()
                        .or_else(|| eval_js(expr, result_text))
                    {
                        expanded.push_str(&value);
                    }
                }
                TemplatePart::ResultParam(index, original) => {
                    if let Some(value) = result
                        .and_then(|items| items.get(*index))
                        .and_then(|item| item.as_deref())
                    {
                        expanded.push_str(value);
                    } else {
                        expanded.push_str(original);
                    }
                }
            }
        }

        let (rule, replace_regex, replacement, replace_first) = split_regex_suffix(&expanded);
        MaterializedRule {
            mode: self.mode,
            rule,
            replace_regex,
            replacement,
            replace_first,
        }
    }
}

/// Split a rule into ordered plain, `<js>` and `@webjs:` segments.
pub fn split_source_rules(rule: &str, all_in_one: bool) -> Vec<SourceRule> {
    if rule.is_empty() {
        return Vec::new();
    }

    let mut default_mode = RuleMode::Default;
    let mut start = 0;
    if all_in_one && rule.starts_with(':') {
        default_mode = RuleMode::Regex;
        start = 1;
    }

    let mut output = Vec::new();
    let mut cursor = start;
    let lower = rule.to_ascii_lowercase();
    while cursor < rule.len() {
        let js_at = lower[cursor..].find("<js>").map(|i| cursor + i);
        let at_js = lower[cursor..].find("@js:").map(|i| cursor + i);
        let web_at = lower[cursor..].find("@webjs:").map(|i| cursor + i);
        let next = [
            js_at.map(|at| (at, 0)),
            at_js.map(|at| (at, 1)),
            web_at.map(|at| (at, 2)),
        ]
        .into_iter()
        .flatten()
        .min_by_key(|(at, _)| *at);
        let Some((marker_at, marker_kind)) = next else {
            break;
        };
        push_plain_segment(&mut output, &rule[cursor..marker_at], default_mode);

        if marker_kind == 1 {
            let script_start = marker_at + "@js:".len();
            if script_start < rule.len() {
                output.push(SourceRule::new(&rule[script_start..], RuleMode::Js));
            }
            return output;
        }

        if marker_kind == 2 {
            let script_start = marker_at + "@webjs:".len();
            if script_start < rule.len() {
                output.push(SourceRule::new(&rule[script_start..], RuleMode::WebJs));
            }
            return output;
        }

        let script_start = marker_at + "<js>".len();
        let Some(relative_end) = lower[script_start..].find("</js>") else {
            push_plain_segment(&mut output, &rule[marker_at..], default_mode);
            return output;
        };
        let script_end = script_start + relative_end;
        output.push(SourceRule::new(
            &rule[script_start..script_end],
            RuleMode::Js,
        ));
        cursor = script_end + "</js>".len();
    }

    push_plain_segment(&mut output, &rule[cursor..], default_mode);
    output
}

fn push_plain_segment(output: &mut Vec<SourceRule>, raw: &str, mode: RuleMode) {
    let value = raw.trim();
    if !value.is_empty() {
        output.push(SourceRule::new(value, mode));
    }
}

fn normalize_mode(rule_str: &str, mode: &mut RuleMode) -> String {
    if matches!(mode, RuleMode::Js | RuleMode::Regex) {
        return rule_str.to_string();
    }
    let lower = rule_str.to_ascii_lowercase();
    if lower.starts_with("@css:") {
        return rule_str.to_string();
    }
    if rule_str.starts_with("@@") {
        return rule_str[2..].to_string();
    }
    if lower.starts_with("@xpath:") {
        *mode = RuleMode::XPath;
        return rule_str[7..].to_string();
    }
    if lower.starts_with("@json:") {
        *mode = RuleMode::Json;
        return rule_str[6..].to_string();
    }
    if rule_str.starts_with("$.") || rule_str.starts_with("$[") {
        *mode = RuleMode::Json;
    } else if rule_str.starts_with('/') {
        *mode = RuleMode::XPath;
    }
    rule_str.to_string()
}

fn split_put_rule(rule: &mut String) -> HashMap<String, String> {
    let mut put_map = HashMap::new();
    let mut output = String::with_capacity(rule.len());
    let mut cursor = 0;
    let lower = rule.to_ascii_lowercase();

    while let Some(relative) = lower[cursor..].find("@put:") {
        let start = cursor + relative;
        output.push_str(&rule[cursor..start]);
        let json_start = start + "@put:".len();
        let Some(json_end) = balanced_object_end(rule, json_start) else {
            output.push_str(&rule[start..]);
            cursor = rule.len();
            break;
        };
        if let Ok(values) =
            serde_json::from_str::<HashMap<String, String>>(&rule[json_start..json_end])
        {
            put_map.extend(values);
        } else {
            output.push_str(&rule[start..json_end]);
        }
        cursor = json_end;
    }
    if cursor < rule.len() {
        output.push_str(&rule[cursor..]);
    }
    *rule = output;
    put_map
}

fn balanced_object_end(input: &str, start: usize) -> Option<usize> {
    let bytes = input.as_bytes();
    if bytes.get(start) != Some(&b'{') {
        return None;
    }
    let mut depth = 0;
    let mut quoted = false;
    let mut escaped = false;
    for (offset, byte) in bytes.iter().enumerate().skip(start) {
        if quoted {
            if escaped {
                escaped = false;
            } else if *byte == b'\\' {
                escaped = true;
            } else if *byte == b'"' {
                quoted = false;
            }
            continue;
        }
        match *byte {
            b'"' => quoted = true,
            b'{' => depth += 1,
            b'}' => {
                depth -= 1;
                if depth == 0 {
                    return Some(offset + 1);
                }
            }
            _ => {}
        }
    }
    None
}

fn split_template_parts(rule: &str) -> Vec<TemplatePart> {
    let mut parts = Vec::new();
    let mut literal_start = 0;
    let mut cursor = 0;
    while cursor < rule.len() {
        let rest = &rule[cursor..];
        let mustache = rest.find("{{").map(|i| cursor + i);
        let get = find_get_marker(rule, cursor);
        let param = find_result_param(rule, cursor);
        let Some((start, kind)) = [
            mustache.map(|i| (i, 0)),
            get.map(|i| (i, 1)),
            param.map(|i| (i, 2)),
        ]
        .into_iter()
        .flatten()
        .min_by_key(|(i, _)| *i) else {
            break;
        };

        if start > literal_start {
            parts.push(TemplatePart::Literal(
                rule[literal_start..start].to_string(),
            ));
        }
        match kind {
            0 => {
                let end = rule[start + 2..].find("}}").map(|i| start + 2 + i + 2);
                let Some(end) = end else {
                    parts.push(TemplatePart::Literal(rule[start..].to_string()));
                    literal_start = rule.len();
                    cursor = rule.len();
                    continue;
                };
                parts.push(TemplatePart::Js(rule[start + 2..end - 2].to_string()));
                cursor = end;
                literal_start = end;
            }
            1 => {
                let end = get_marker_end(rule, start);
                parts.push(TemplatePart::Get(rule[start + 5..end].to_string()));
                cursor = end;
                literal_start = end;
            }
            _ => {
                let mut end = start + 1;
                let mut digits = 0;
                while end < rule.len() && digits < 2 {
                    let Some(ch) = rule[end..].chars().next() else {
                        break;
                    };
                    if !ch.is_ascii_digit() {
                        break;
                    }
                    end += ch.len_utf8();
                    digits += 1;
                }
                if digits == 0 {
                    parts.push(TemplatePart::Literal(rule[start..start + 1].to_string()));
                    cursor = start + 1;
                    literal_start = cursor;
                    continue;
                }
                parts.push(TemplatePart::ResultParam(
                    rule[start + 1..end].parse().unwrap_or(0),
                    rule[start..end].to_string(),
                ));
                cursor = end;
                literal_start = end;
            }
        }
    }
    if literal_start < rule.len() {
        parts.push(TemplatePart::Literal(rule[literal_start..].to_string()));
    }
    parts
}

fn find_get_marker(rule: &str, start: usize) -> Option<usize> {
    rule[start..]
        .to_ascii_lowercase()
        .find("@get:")
        .map(|i| start + i)
}

fn get_marker_end(rule: &str, start: usize) -> usize {
    let end = start + 5;
    for (offset, ch) in rule[end..].char_indices() {
        if ch == '@' || ch == '{' || ch == '#' || ch == '$' || ch == '/' || ch.is_whitespace() {
            return end + offset;
        }
    }
    rule.len()
}

fn find_result_param(rule: &str, start: usize) -> Option<usize> {
    let bytes = rule.as_bytes();
    for index in start..bytes.len().saturating_sub(1) {
        if bytes[index] == b'$' && bytes[index + 1].is_ascii_digit() {
            return Some(index);
        }
    }
    None
}

fn split_regex_suffix(value: &str) -> (String, String, String, bool) {
    let mut parts = value.split("##");
    let rule = parts.next().unwrap_or_default().trim().to_string();
    let replace_regex = parts.next().unwrap_or_default().to_string();
    let replacement = parts.next().unwrap_or_default().to_string();
    let replace_first = parts.next().is_some();
    (rule, replace_regex, replacement, replace_first)
}

fn expand_simple_template(value: &str, variables: &HashMap<String, String>) -> String {
    let mut out = value.to_string();
    let mut cursor = 0;
    while let Some(relative) = out[cursor..].find("{{") {
        let start = cursor + relative;
        let Some(relative_end) = out[start + 2..].find("}}") else {
            break;
        };
        let end = start + 2 + relative_end;
        let key = out[start + 2..end].trim();
        let replacement = variables.get(key).cloned().unwrap_or_default();
        out.replace_range(start..end + 2, &replacement);
        cursor = start + replacement.len();
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn source_rule_keeps_plain_js_plain_order() {
        let rules = split_source_rules(
            "@put:{\"marker\":\"one\"}.first@text <JS>result + marker</Js> .last@text",
            false,
        );
        assert_eq!(rules.len(), 3);
        assert_eq!(rules[0].mode, RuleMode::Default);
        assert_eq!(rules[0].rule, " .first@text".trim());
        assert_eq!(rules[1].mode, RuleMode::Js);
        assert_eq!(rules[1].rule, "result + marker");
        assert_eq!(rules[2].rule, ".last@text");
        assert_eq!(rules[0].put_map.get("marker"), Some(&"one".to_string()));
    }

    #[test]
    fn at_js_is_a_case_insensitive_tail_segment() {
        let rules = split_source_rules(".first@text @JS:result", false);
        assert_eq!(rules.len(), 2);
        assert_eq!(rules[0].rule, ".first@text");
        assert_eq!(rules[1].mode, RuleMode::Js);
        assert_eq!(rules[1].rule, "result");
    }

    #[test]
    fn put_is_visible_before_the_current_segment_only() {
        let rules = split_source_rules(
            "@put:{\"token\":\"ready\"}first@text <js>{{token}}</js>",
            false,
        );
        let mut state = RuleState::default();
        let mut seen = Vec::new();
        for rule in &rules {
            let materialized = state.materialize(rule, None, |_expr, _result, vars| {
                vars.get("token").cloned()
            });
            seen.push((materialized.rule, state.get("token").to_string()));
        }
        assert_eq!(seen[0], ("first@text".to_string(), "ready".to_string()));
        assert_eq!(seen[1], ("ready".to_string(), "ready".to_string()));
    }

    #[test]
    fn makeup_expands_get_mustache_and_result_parameter_before_regex_suffix() {
        let rule = SourceRule::new(
            "/item/{{page + 1}}/@get:key/$1##广告####",
            RuleMode::Default,
        );
        let mut vars = HashMap::new();
        vars.insert("key".to_string(), "书名".to_string());
        let out = rule.materialize(
            Some(&[Some("正文".to_string()), Some("尾".to_string())]),
            &vars,
            |expr, _| {
                assert_eq!(expr, "page + 1");
                Some("3".to_string())
            },
        );
        assert_eq!(out.mode, RuleMode::XPath);
        assert_eq!(out.rule, "/item/3/书名/尾");
        assert_eq!(out.replace_regex, "广告");
        assert_eq!(out.replacement, "");
        assert!(out.replace_first);
    }

    #[test]
    fn put_values_can_see_existing_variables_when_applied() {
        let mut state = RuleState::default();
        state.variables.insert("page".to_string(), "2".to_string());
        let rule = SourceRule::new("@put:{\"url\":\"/p/{{page}}\"}/item", RuleMode::Default);
        let _ = state.materialize(&rule, None, |_expr, _result, _vars| None);
        assert_eq!(state.get("url"), "/p/2");
    }
}
