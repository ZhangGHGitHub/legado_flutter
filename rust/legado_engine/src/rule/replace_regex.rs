use regex::Regex;

fn compile_pattern(pattern: &str) -> Option<Regex> {
    let normalized = pattern
        .replace("\\n", "\n")
        .replace("\\r", "\r")
        .replace("\\t", "\t");
    Regex::new(&normalized).ok()
}

fn normalize_replacement(replacement: &str) -> String {
    replacement
        .replace("\\n", "\n")
        .replace("\\r", "\r")
        .replace("\\t", "\t")
}

/// Legado replaceRegex：多行 `##pattern##replacement`
pub fn apply_replace_regex(content: &str, rules: &str) -> String {
    if content.is_empty() || rules.trim().is_empty() {
        return content.to_string();
    }
    let mut out = content.to_string();
    for line in rules.lines() {
        let mut rule = line.trim();
        if rule.is_empty() {
            continue;
        }
        if rule.starts_with("##") {
            rule = &rule[2..];
        }
        let Some(idx) = rule.find("##") else {
            continue;
        };
        let pattern = &rule[..idx];
        let replacement = normalize_replacement(&rule[idx + 2..]);
        if let Some(re) = compile_pattern(pattern) {
            out = re.replace_all(&out, replacement.as_str()).to_string();
        }
    }
    out
}

/// 规则字段上的 `##pattern##replacement` 后缀（Legado analyzeRule）
pub fn apply_rule_regex_suffix(rule: &str, value: &str) -> String {
    let Some(idx) = rule.find("##") else {
        return value.to_string();
    };
    let after = &rule[idx + 2..];
    let Some(idx2) = after.find("##") else {
        return value.to_string();
    };
    let pattern = &after[..idx2];
    let replacement = &after[idx2 + 2..];
    compile_pattern(pattern)
        .map(|re| {
            re.replace_all(value, normalize_replacement(replacement).as_str())
                .to_string()
        })
        .unwrap_or_else(|| value.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn multi_line_replace() {
        let rules = "##广告##\n##\\n{3,}##\\n\\n";
        let out = apply_replace_regex("正文广告\n\n\n", rules);
        assert_eq!(out, "正文\n\n");
    }
}
