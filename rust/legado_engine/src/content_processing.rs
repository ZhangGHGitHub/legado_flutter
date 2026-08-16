use regex::{Regex, RegexBuilder};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

const MARK_SENTENCES_END: &str = "？。！?!~";
const MARK_SENTENCES_END_P: &str = ".？。！?!~";
const MARK_SENTENCES_MID: &str = ".，、,—…";
const MARK_SENTENCES_SAY: &str = "问说喊唱叫骂道着答";
const MARK_QUOTATION_BEFORE: &str = "，：,:";
const MARK_QUOTATION: &str = "\"“”";
const MARK_QUOTATION_RIGHT: &str = "\"”";
const WORD_MAX_LENGTH: usize = 16;

#[derive(Debug, Clone)]
pub struct ReplaceRuleInput {
    pub pattern: String,
    pub replacement: String,
    pub is_enabled: bool,
    pub is_regex: bool,
}

#[derive(Debug, Clone)]
pub struct SourceRulesInput {
    pub content_replace: String,
    pub content_replace_to: String,
}

#[derive(Debug, Clone)]
pub struct ReadingProcessInput {
    pub raw: String,
    pub chapter_title: String,
    pub book_name: String,
    pub include_title: bool,
    pub use_replace: bool,
    pub paragraph_indent: String,
    pub re_segment: bool,
    pub rules: Vec<ReplaceRuleInput>,
    pub source_rules: Option<SourceRulesInput>,
}

pub fn apply_replace_rules(text: &str, rules: &[ReplaceRuleInput]) -> String {
    if text.is_empty() {
        return text.to_string();
    }

    let mut result = text.to_string();
    for rule in rules {
        if !rule.is_enabled {
            continue;
        }
        if rule.is_regex {
            if let Some(re) = compile_multiline(&rule.pattern) {
                result = re
                    .replace_all(&result, rule.replacement.as_str())
                    .to_string();
            }
        } else if !rule.pattern.is_empty() {
            result = result.replace(&rule.pattern, &rule.replacement);
        }
    }
    result
}

pub fn process(
    raw: &str,
    rules: &[ReplaceRuleInput],
    source_rules: Option<&SourceRulesInput>,
) -> String {
    let mut result = apply_replace_rules(raw, rules);
    if let Some(source_rules) = source_rules {
        if !source_rules.content_replace.is_empty() {
            if let Some(re) = compile_multiline(&source_rules.content_replace) {
                result = re
                    .replace_all(&result, source_rules.content_replace_to.as_str())
                    .to_string();
            }
        }
    }
    result
}

pub fn process_for_reading(input: ReadingProcessInput) -> Result<String, String> {
    let mut content = input.raw;
    if content != "null" {
        content = remove_duplicate_title(&content, &input.chapter_title, &input.book_name);
        if input.re_segment && !content.is_empty() {
            content = re_segment(&content, &input.chapter_title);
        }
        if input.use_replace {
            content = trim_lines(&content);
            content = process(&content, &input.rules, input.source_rules.as_ref());
        }
    }

    if input.include_title && !input.chapter_title.trim().is_empty() {
        content = format!("{}\n{}", input.chapter_title.trim(), content);
    }

    Ok(content
        .split('\n')
        .map(trim_paragraph)
        .filter(|line| !line.is_empty())
        .enumerate()
        .map(|(idx, line)| {
            if idx == 0 && input.include_title {
                line
            } else {
                format!("{}{}", input.paragraph_indent, line)
            }
        })
        .collect::<Vec<_>>()
        .join("\n"))
}

fn re_segment(content: &str, chapter_name: &str) -> String {
    let dict = make_dict(content);
    let re_colon_quotes = Regex::new(r#"[:：]['"‘“”]+"#).unwrap();
    let re_adjacent_quotes = Regex::new(r#"["“”]+\s*["“”][\s"“”]*"#).unwrap();
    let normalized = re_adjacent_quotes
        .replace_all(
            &re_colon_quotes.replace_all(&content.replace("&quot;", "“"), "：“"),
            "”\n“",
        )
        .to_string();
    let split_lines = Regex::new(r"\n(\s*)").unwrap();
    let paragraphs: Vec<&str> = split_lines.split(&normalized).collect();

    let mut buffer = String::from("  ");
    if chapter_name.trim() != paragraphs.first().copied().unwrap_or_default().trim() {
        buffer.push_str(
            &Regex::new(r"[\u{3000}\s]+")
                .unwrap()
                .replace_all(paragraphs.first().copied().unwrap_or_default(), ""),
        );
    }
    for paragraph in paragraphs.iter().skip(1) {
        let chars: Vec<char> = buffer.chars().collect();
        let last = chars.last().copied().unwrap_or_default();
        let previous = chars.get(chars.len().saturating_sub(2)).copied();
        if matches(last, MARK_SENTENCES_END)
            || (matches(last, MARK_QUOTATION_RIGHT)
                && previous.is_some_and(|ch| matches(ch, MARK_SENTENCES_END)))
        {
            buffer.push('\n');
        }
        buffer.push_str(
            &Regex::new(r"[\u{3000}\s]")
                .unwrap()
                .replace_all(paragraph, ""),
        );
    }

    let pre_segmented = Regex::new(r#"["“”]+\s*["“”]+"#)
        .unwrap()
        .replace_all(&buffer, "”\n“")
        .to_string();
    let pre_segmented = Regex::new(r#"["“”]+(？。！?!~)["“”]+"#)
        .unwrap()
        .replace_all(&pre_segmented, "”$1\n“")
        .to_string();
    let pre_segmented = Regex::new(r#"["“”]+(？。！?!~)([^"“”])"#)
        .unwrap()
        .replace_all(&pre_segmented, "”$1\n$2")
        .to_string();
    let pre_segmented = Regex::new(r"([问说喊唱叫骂道着答])[\.。]")
        .unwrap()
        .replace_all(&pre_segmented, "$1。\n")
        .to_string();

    let mut rebuilt = String::new();
    for paragraph in pre_segmented.split('\n') {
        rebuilt.push('\n');
        rebuilt.push_str(&find_new_lines(paragraph, &dict));
    }
    let reduced = reduce_length(&rebuilt);
    let result = Regex::new(r"^\s+")
        .unwrap()
        .replace(&reduced, "")
        .to_string();
    let result = Regex::new(r#"\s*["“”]+\s*["“”][\s"“”]*"#)
        .unwrap()
        .replace_all(&result, "”\n“")
        .to_string();
    let result = Regex::new(r#"[:：][“”"\s]+"#)
        .unwrap()
        .replace_all(&result, "：“")
        .to_string();
    let result = Regex::new(r#"\n["“”]([^\n"“”]+)([,:，：]["“”])([^\n"“”]+)"#)
        .unwrap()
        .replace_all(&result, "\n$1：“$3")
        .to_string();
    Regex::new(r"\n(\s*)")
        .unwrap()
        .replace_all(&result, "\n")
        .to_string()
}

fn reduce_length(text: &str) -> String {
    let mut paragraphs: Vec<String> = text.split('\n').map(str::to_string).collect();
    let is_dialogue: Vec<bool> = paragraphs
        .iter()
        .map(|paragraph| {
            let chars: Vec<char> = paragraph.chars().collect();
            chars.len() >= 2
                && matches(chars[0], MARK_QUOTATION)
                && matches(*chars.last().unwrap(), MARK_QUOTATION)
                && !chars[1..chars.len() - 1]
                    .iter()
                    .any(|ch| matches(*ch, MARK_QUOTATION))
        })
        .collect();
    let mut dialogue = 0;
    for index in 0..paragraphs.len() {
        if is_dialogue[index] {
            if dialogue < 0 {
                dialogue = 1;
            } else if dialogue < 2 {
                dialogue += 1;
            }
        } else if dialogue > 1 {
            paragraphs[index] = split_quote(&paragraphs[index]);
            dialogue -= 1;
        } else if dialogue > 0
            && index < paragraphs.len().saturating_sub(2)
            && is_dialogue[index + 1]
        {
            paragraphs[index] = split_quote(&paragraphs[index]);
        }
    }

    let mut result = String::new();
    for paragraph in paragraphs {
        result.push('\n');
        result.push_str(&paragraph);
    }
    result
}

fn split_quote(text: &str) -> String {
    let chars: Vec<char> = text.chars().collect();
    let length = chars.len();
    if length < 3 {
        return text.to_string();
    }
    if matches(chars[0], MARK_QUOTATION) {
        let index = seek_index(&chars, MARK_QUOTATION, 1, length - 2, true) + 1;
        if index > 1 && !matches(chars[index as usize - 1], MARK_QUOTATION_BEFORE) {
            return format!(
                "{}\n{}",
                chars[..index as usize].iter().collect::<String>(),
                chars[index as usize..].iter().collect::<String>()
            );
        }
    } else if matches(chars[length - 1], MARK_QUOTATION) {
        let distance = seek_index(&chars, MARK_QUOTATION, 1, length - 2, false);
        let index = length as isize - 1 - distance;
        if index > 1 && !matches(chars[index as usize - 1], MARK_QUOTATION_BEFORE) {
            return format!(
                "{}\n{}",
                chars[..index as usize].iter().collect::<String>(),
                chars[index as usize..].iter().collect::<String>()
            );
        }
    }
    text.to_string()
}

fn force_split(
    chars: &[char],
    offset: usize,
    min_sentences: usize,
    gain: usize,
    trigger: usize,
) -> Vec<usize> {
    let mut result = Vec::new();
    let array_end = seek_indexes(
        chars,
        MARK_SENTENCES_END_P,
        0,
        chars.len().saturating_sub(2),
        true,
    );
    let array_mid = seek_indexes(
        chars,
        MARK_SENTENCES_MID,
        0,
        chars.len().saturating_sub(2),
        true,
    );
    if array_end.len() < trigger && array_mid.len() < trigger * 3 {
        return result;
    }
    let mut mid_index = 0;
    let mut end_index = min_sentences;
    while end_index < array_end.len() {
        let mut mid_count = 0;
        while mid_index < array_mid.len() {
            if array_mid[mid_index] < array_end[end_index] {
                mid_count += 1;
            }
            mid_index += 1;
        }
        if random_unit() * (gain as f64) < 0.8 + mid_count as f64 / 2.5 {
            result.push(array_end[end_index] + offset);
            end_index = (end_index + min_sentences).max(end_index);
        }
        end_index += 1;
    }
    result
}

fn find_new_lines(text: &str, dict: &[String]) -> String {
    let original: Vec<char> = text.chars().collect();
    let mut chars = original.clone();
    let mut quote_indexes = Vec::new();
    let mut new_lines = Vec::new();
    let mut mods = vec![0_i8; original.len()];
    let mut wait_close = false;

    for index in 0..original.len() {
        if !matches(original[index], MARK_QUOTATION) {
            continue;
        }
        let size = quote_indexes.len();
        if size > 0 {
            let previous_quote = quote_indexes[size - 1];
            if index - previous_quote == 2 {
                let separator = original[index - 1];
                let remove = if wait_close {
                    matches(separator, ",，、/")
                } else {
                    matches(separator, ",，、/和与或")
                };
                if remove {
                    chars[index] = '“';
                    chars[index - 2] = '”';
                    quote_indexes.remove(size - 1);
                    mods[size - 1] = 1;
                    mods[size] = -1;
                    continue;
                }
            }
        }
        quote_indexes.push(index);

        if index > 1 {
            let before = original[index - 1];
            if matches(before, MARK_QUOTATION_BEFORE) {
                if quote_indexes.len() > 1 {
                    let last_quote = quote_indexes[quote_indexes.len() - 2];
                    let mut position = 0;
                    let mut before_previous = '\0';
                    if matches(before, ",，") && quote_indexes.len() > 2 {
                        position = quote_indexes[quote_indexes.len() - 3];
                        if position > 0 {
                            before_previous = original[position - 1];
                        }
                    }
                    if matches(before_previous, MARK_SENTENCES_END_P) {
                        new_lines.push(position - 1);
                    } else if before_previous != '的' {
                        let last_end = seek_last(
                            &original,
                            MARK_SENTENCES_END,
                            index as isize,
                            last_quote as isize,
                        );
                        new_lines.push(if last_end > 0 {
                            last_end as usize
                        } else {
                            last_quote
                        });
                    }
                }
                wait_close = true;
                mods[size] = 1;
                if size > 0 {
                    mods[size - 1] = -1;
                    if size > 1 {
                        mods[size - 2] = 1;
                    }
                }
            } else if wait_close {
                wait_close = false;
                new_lines.push(index);
            }
        }
    }

    let quote_count = quote_indexes.len();
    let mut opened = false;
    if quote_count > 0 {
        for index in 0..quote_count {
            if mods[index] > 0 {
                opened = true;
            } else if mods[index] < 0 {
                if !opened && index > 0 {
                    mods[index] = 3;
                }
                opened = false;
            } else {
                opened = !opened;
                mods[index] = if opened { 2 } else { -2 };
            }
        }
        if opened {
            if quote_indexes[quote_count - 1] + 3 > chars.len() {
                if quote_count > 1 {
                    mods[quote_count - 2] = 4;
                }
                mods[quote_count - 1] = -4;
            } else if chars.len() >= 2 && !matches(chars[chars.len() - 2], MARK_SENTENCES_SAY) {
                chars.push('”');
            }
        }

        let mut previous_mod = -1;
        let mut index = 0;
        if quote_indexes[0] == 0 {
            index = 1;
            previous_mod = 0;
        }
        while index < quote_count {
            let before_quote = quote_indexes[index] - 1;
            let current_mod = mods[index];
            if previous_mod < 0
                && current_mod > 0
                && matches(chars[before_quote], MARK_SENTENCES_END)
            {
                new_lines.push(before_quote);
            }
            previous_mod = current_mod;
            index += 1;
        }
    }

    new_lines.retain(|&index| {
        if matches(chars[index], "\"'”“") {
            let start = seek_last(
                &original,
                "\"'”“",
                index as isize - 1,
                index as isize - WORD_MAX_LENGTH as isize,
            );
            if start > 0 {
                let word: String = original[start as usize + 1..index].iter().collect();
                if dict.contains(&word) || matches(original[start as usize], "的地得") {
                    return false;
                }
            }
        }
        true
    });
    new_lines.sort_unstable();
    new_lines.dedup();

    let mut progress = 0;
    let mut line_index = 0;
    let mut next_line = new_lines.first().copied().unwrap_or(usize::MAX);
    let mut gain = 3;
    let mut minimum = 0;
    let mut trigger = 2;
    for &quote in &quote_indexes {
        if quote > 0 {
            gain = 4;
            minimum = 2;
            trigger = 4;
        } else {
            gain = 3;
            minimum = 0;
            trigger = 2;
        }
        while line_index < new_lines.len() {
            if next_line >= quote {
                break;
            }
            next_line = new_lines[line_index];
            if progress < next_line {
                new_lines.extend(force_split(
                    &chars[progress..next_line],
                    progress,
                    minimum,
                    gain,
                    trigger,
                ));
                progress = next_line + 1;
            }
            line_index += 1;
        }
        if progress < quote {
            new_lines.extend(force_split(
                &chars[progress..=quote],
                progress,
                minimum,
                gain,
                trigger,
            ));
            progress = quote + 1;
        }
    }
    while line_index < new_lines.len() {
        next_line = new_lines[line_index];
        if progress < next_line {
            new_lines.extend(force_split(
                &chars[progress..next_line],
                progress,
                minimum,
                gain,
                trigger,
            ));
            progress = next_line + 1;
        }
        line_index += 1;
    }
    if progress < chars.len() {
        new_lines.extend(force_split(
            &chars[progress..],
            progress,
            minimum,
            gain,
            trigger,
        ));
    }

    let mut insert_quote = vec![false; quote_count];
    opened = false;
    for index in 0..quote_count {
        let position = quote_indexes[index];
        if mods[index] > 0 {
            chars[position] = '“';
            if opened {
                insert_quote[index] = true;
            }
            opened = true;
        } else if mods[index] < 0 {
            chars[position] = '”';
            opened = false;
        } else {
            opened = !opened;
            chars[position] = if opened { '“' } else { '”' };
        }
    }
    new_lines.sort_unstable();
    new_lines.dedup();

    let mut result = String::new();
    let mut line_cursor = 0;
    let mut copy_from = 0;
    let mut next_line = new_lines.first().copied().unwrap_or(usize::MAX);
    for (index, &quote) in quote_indexes.iter().enumerate() {
        while line_cursor < new_lines.len() {
            if next_line >= quote {
                break;
            }
            next_line = new_lines[line_cursor];
            if copy_from <= next_line {
                result.extend(chars[copy_from..=next_line].iter());
            }
            result.push('\n');
            copy_from = next_line + 1;
            line_cursor += 1;
        }
        if copy_from < quote {
            result.extend(chars[copy_from..=quote].iter());
            copy_from = quote + 1;
        }
        if insert_quote[index] && result.chars().count() > 2 {
            if result.ends_with('\n') {
                result.push('“');
            } else if let Some(last) = result.pop() {
                result.push('”');
                result.push('\n');
                result.push(last);
            }
        }
    }
    while line_cursor < new_lines.len() {
        next_line = new_lines[line_cursor];
        if copy_from <= next_line {
            result.extend(chars[copy_from..=next_line].iter());
            result.push('\n');
            copy_from = next_line + 1;
        }
        line_cursor += 1;
    }
    if copy_from < chars.len() {
        result.extend(chars[copy_from..].iter());
    }
    result
}

fn make_dict(text: &str) -> Vec<String> {
    let chars: Vec<char> = text.chars().collect();
    let mut cache = Vec::new();
    let mut dict = Vec::new();
    for start in 0..chars.len() {
        if !matches(chars[start], "\"'“”") {
            continue;
        }
        let limit = (start + WORD_MAX_LENGTH + 2).min(chars.len());
        for end in start + 1..limit {
            if chars[end] == '\n' || is_unicode_punctuation(chars[end]) {
                if matches(chars[end], "\"'“”") && end > start + 1 {
                    let word: String = chars[start + 1..end].iter().collect();
                    if cache.contains(&word) {
                        if !dict.contains(&word) {
                            dict.push(word);
                        }
                    } else {
                        cache.push(word);
                    }
                }
                break;
            }
        }
    }
    dict
}

fn is_unicode_punctuation(ch: char) -> bool {
    matches!(
        ch as u32,
        0x21..=0x2f
            | 0x3a..=0x40
            | 0x5b..=0x60
            | 0x7b..=0x7e
            | 0x2000..=0x206f
            | 0x2e00..=0x2eff
            | 0x3000..=0x303f
            | 0xfe10..=0xfe6f
            | 0xff01..=0xff65
    )
}

fn seek_indexes(chars: &[char], key: &str, from: usize, to: usize, in_order: bool) -> Vec<usize> {
    if chars.len().saturating_sub(from) < 1 {
        return Vec::new();
    }
    let mut index = from;
    let end = if to > 0 {
        chars.len().min(to)
    } else {
        chars.len()
    };
    let mut result = Vec::new();
    while index < end {
        let ch = if in_order {
            chars[index]
        } else {
            chars[chars.len() - index - 1]
        };
        if matches(ch, key) {
            if result.last().is_some_and(|last| index - *last == 1) {
                *result.last_mut().unwrap() = index;
            } else {
                result.push(index);
            }
        }
        index += 1;
    }
    result
}

fn seek_last(chars: &[char], key: &str, from: isize, to: isize) -> isize {
    if chars.len() as isize - from < 1 {
        return -1;
    }
    let mut index = chars.len() as isize - 1;
    if from < index && index > 0 {
        index = from;
    }
    let end = if to > 0 { to } else { 0 };
    while index > end {
        if matches(chars[index as usize], key) {
            return index;
        }
        index -= 1;
    }
    -1
}

fn seek_index(chars: &[char], key: &str, from: usize, to: usize, in_order: bool) -> isize {
    if chars.len().saturating_sub(from) < 1 {
        return -1;
    }
    let mut index = from;
    let end = if to > 0 {
        chars.len().min(to)
    } else {
        chars.len()
    };
    while index < end {
        let ch = if in_order {
            chars[index]
        } else {
            chars[chars.len() - index - 1]
        };
        if matches(ch, key) {
            return index as isize;
        }
        index += 1;
    }
    -1
}

fn matches(ch: char, rule: &str) -> bool {
    rule.contains(ch)
}

fn random_unit() -> f64 {
    static STATE: AtomicU64 = AtomicU64::new(0);
    let mut current = STATE.load(Ordering::Relaxed);
    if current == 0 {
        current = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|duration| duration.as_nanos() as u64)
            .unwrap_or(0x9e37_79b9_7f4a_7c15)
            | 1;
    }
    loop {
        let mut next = current;
        next ^= next << 13;
        next ^= next >> 7;
        next ^= next << 17;
        match STATE.compare_exchange_weak(current, next, Ordering::Relaxed, Ordering::Relaxed) {
            Ok(_) => return ((next >> 11) as f64) / ((1_u64 << 53) as f64),
            Err(actual) => current = actual,
        }
    }
}

fn remove_duplicate_title(content: &str, chapter_title: &str, book_name: &str) -> String {
    let title = chapter_title.trim();
    if title.is_empty() || content.is_empty() {
        return content.to_string();
    }
    let escaped = title
        .split_whitespace()
        .filter(|part| !part.is_empty())
        .map(regex::escape)
        .collect::<Vec<_>>()
        .join(r"\s*");
    let book = book_name.trim();
    let prefix = if book.is_empty() {
        punctuation_class().to_string()
    } else {
        format!("(?:{}|{})", punctuation_class(), regex::escape(book))
    };
    let pattern = format!(r"^(?:{})*{}\s*", prefix, escaped);
    Regex::new(&pattern)
        .ok()
        .map(|re| re.replace(content, "").to_string())
        .unwrap_or_else(|| content.to_string())
}

fn compile_multiline(pattern: &str) -> Option<Regex> {
    RegexBuilder::new(pattern).multi_line(true).build().ok()
}

fn punctuation_class() -> &'static str {
    r"[\s\x00-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E\u{2000}-\u{206F}\u{2E00}-\u{2E7F}\u{3000}-\u{303F}\u{FE10}-\u{FE6F}\u{FF01}-\u{FF65}]"
}

fn trim_lines(text: &str) -> String {
    text.split('\n')
        .map(trim_paragraph)
        .collect::<Vec<_>>()
        .join("\n")
}

fn trim_paragraph(line: &str) -> String {
    let chars: Vec<char> = line.chars().collect();
    let mut start = 0;
    let mut end = chars.len();
    while start < end && is_original_trim_char(chars[start]) {
        start += 1;
    }
    while end > start && is_original_trim_char(chars[end - 1]) {
        end -= 1;
    }
    chars[start..end].iter().collect()
}

fn is_original_trim_char(ch: char) -> bool {
    (ch as u32) <= 0x20 || ch == '\u{3000}'
}

#[cfg(test)]
mod tests {
    use super::*;

    fn rule(pattern: &str, replacement: &str, is_regex: bool) -> ReplaceRuleInput {
        ReplaceRuleInput {
            pattern: pattern.to_string(),
            replacement: replacement.to_string(),
            is_enabled: true,
            is_regex,
        }
    }

    #[test]
    fn replace_rules_match_dart_order_and_disabled_semantics() {
        let rules = vec![
            rule("广告词", "", false),
            ReplaceRuleInput {
                pattern: "正文".to_string(),
                replacement: "失败".to_string(),
                is_enabled: false,
                is_regex: false,
            },
            rule(r"\n{3,}", "\n\n", true),
        ];
        let out = apply_replace_rules("正文广告词\n\n\n末尾", &rules);
        assert_eq!(out, "正文\n\n末尾");
    }

    #[test]
    fn source_rules_run_after_global_rules() {
        let rules = vec![rule("PLACEHOLDER", "追踪参数=42", false)];
        let source_rules = SourceRulesInput {
            content_replace: r"追踪参数=\d+".to_string(),
            content_replace_to: "追踪参数=N".to_string(),
        };

        assert_eq!(
            process("PLACEHOLDER", &rules, Some(&source_rules)),
            "追踪参数=N"
        );
    }

    #[test]
    fn reading_pipeline_matches_current_dart_fixture_path() {
        let input = ReadingProcessInput {
            raw: "\r\n【混排书】。。。第 42 章   Mixed Signals 2\r\n  广告词  \r\n  PLACEHOLDER  \r\n中文与English混排，数字123和URL https://example.com/read?id=42&lang=zh 追踪参数=42  \r\n[newpage]\r\n  末段中文 English 456 https://example.com/end  ".to_string(),
            chapter_title: "第 42 章 Mixed Signals 2".to_string(),
            book_name: "混排书".to_string(),
            include_title: true,
            use_replace: true,
            paragraph_indent: "  ".to_string(),
            re_segment: false,
            rules: vec![
                rule("^广告词$", "净化后", true),
                rule("PLACEHOLDER", "已替换", false),
            ],
            source_rules: Some(SourceRulesInput {
                content_replace: r"追踪参数=\d+".to_string(),
                content_replace_to: "追踪参数=N".to_string(),
            }),
        };

        let out = process_for_reading(input).unwrap();
        assert_eq!(
            out,
            "第 42 章 Mixed Signals 2\n  净化后\n  已替换\n  中文与English混排，数字123和URL https://example.com/read?id=42&lang=zh 追踪参数=N\n  [newpage]\n  末段中文 English 456 https://example.com/end"
        );
    }

    #[test]
    fn resegment_expands_captured_punctuation_like_dart_content_help() {
        assert_eq!(re_segment("他说。", ""), "他说。\n");
    }

    #[test]
    fn resegment_deduplicates_chapter_name() {
        assert_eq!(re_segment("第一章\n他说。", "第一章"), "他说。\n");
    }

    #[test]
    fn resegment_keeps_dialogue_newlines_stable() {
        assert_eq!(
            re_segment("他说：“你好。”她答：“再见。”", ""),
            "他说：“你好。”\n她答：“再见。”\n"
        );
    }

    #[test]
    fn reading_pipeline_uses_resegment_path() {
        let result = process_for_reading(ReadingProcessInput {
            raw: "他说。".to_string(),
            chapter_title: String::new(),
            book_name: String::new(),
            include_title: false,
            use_replace: false,
            paragraph_indent: String::new(),
            re_segment: true,
            rules: vec![],
            source_rules: None,
        });

        assert_eq!(result.unwrap(), "他说。");
    }
}
