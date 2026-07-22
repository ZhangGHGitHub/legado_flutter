use regex::Regex;

/// 对齐 AnalyzeByRegex.getElement：返回首个匹配及其捕获组。
pub fn get_element(result: &str, rules: &[&str]) -> Option<Vec<String>> {
    if rules.is_empty() {
        return None;
    }
    let mut current = result.to_string();
    for (index, rule) in rules.iter().enumerate() {
        let regex = Regex::new(rule).ok()?;
        if index + 1 == rules.len() {
            let captures = regex.captures(&current)?;
            return Some(
                captures
                    .iter()
                    .map(|capture| capture.map(|m| m.as_str()).unwrap_or_default().to_string())
                    .collect(),
            );
        }
        current = regex
            .find_iter(&current)
            .map(|m| m.as_str())
            .collect::<String>();
        if current.is_empty() {
            return None;
        }
    }
    None
}

/// 对齐 AnalyzeByRegex.getElements：返回所有最终匹配及其捕获组。
pub fn get_elements(result: &str, rules: &[&str]) -> Vec<Vec<String>> {
    if rules.is_empty() {
        return Vec::new();
    }
    let mut current = result.to_string();
    for (index, rule) in rules.iter().enumerate() {
        let Ok(regex) = Regex::new(rule) else {
            return Vec::new();
        };
        if index + 1 == rules.len() {
            return regex
                .captures_iter(&current)
                .map(|captures| {
                    captures
                        .iter()
                        .map(|capture| capture.map(|m| m.as_str()).unwrap_or_default().to_string())
                        .collect()
                })
                .collect();
        }
        current = regex
            .find_iter(&current)
            .map(|m| m.as_str())
            .collect::<String>();
        if current.is_empty() {
            return Vec::new();
        }
    }
    Vec::new()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn get_element_returns_full_match_and_capture_groups() {
        assert_eq!(
            get_element("第一章12 第二章34", &[r"(第一章)(\d+)"]),
            Some(vec![
                "第一章12".to_string(),
                "第一章".to_string(),
                "12".to_string()
            ])
        );
    }

    #[test]
    fn get_elements_preserves_every_match_and_empty_groups() {
        assert_eq!(
            get_elements("a1 b2", &[r"([a-z])(\d)"]),
            vec![
                vec!["a1".to_string(), "a".to_string(), "1".to_string()],
                vec!["b2".to_string(), "b".to_string(), "2".to_string()]
            ]
        );
        assert_eq!(
            get_elements("a", &[r"(a)(b)?"]),
            vec![vec!["a".to_string(), "a".to_string(), "".to_string()]]
        );
    }
}
