import 'package:flutter/services.dart';

import '../code_edit/keyboard_tool_bar.dart';

/// 规则自动补全 — 对齐 Jingshiro [RuleComplete] 常用片段提示。
abstract final class RuleComplete {
  /// 从光标前文本提取待补全 token（`@css:` / `class.` 等）。
  static String currentToken(String text, int cursor) {
    if (cursor <= 0 || cursor > text.length) return '';
    final before = text.substring(0, cursor);
    final m = RegExp(r'[@#$./\\a-zA-Z0-9_<%>|&*{}\[\]!:+-]+$').firstMatch(before);
    return m?.group(0) ?? '';
  }

  /// 按 token 前缀过滤键盘辅助项（最多 [limit] 条）。
  static List<KeyboardAssistItem> suggestions(
    String token, {
    int limit = 8,
    List<KeyboardAssistItem> items = KeyboardToolBar.defaultAssists,
  }) {
    if (token.isEmpty) return const [];
    final lower = token.toLowerCase();
    final out = <KeyboardAssistItem>[];
    for (final item in items) {
      if (item.key.toLowerCase().startsWith(lower) ||
          item.value.toLowerCase().startsWith(lower)) {
        if (item.key.toLowerCase() == lower) continue;
        out.add(item);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  /// 用 [snippet] 替换当前选区；成对标记时将光标放在中间。
  static TextEditingValue applySnippet(
    TextEditingValue value,
    String snippet,
  ) {
    final text = value.text;
    final sel = value.selection;
    final start = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
    final end = sel.isValid ? sel.end.clamp(0, text.length) : text.length;
    final before = text.substring(0, start);
    final after = text.substring(end);
    final newText = '$before$snippet$after';

    var cursor = before.length + snippet.length;
    if (snippet == '<js></js>') {
      cursor = before.length + '<js>'.length;
    } else if (snippet == '{{}}') {
      cursor = before.length + '{{'.length;
    }

    // 若正在补全 token，替换整个 token
    final token = currentToken(text, start);
    if (token.isNotEmpty &&
        snippet.toLowerCase().startsWith(token.toLowerCase())) {
      final tokenStart = start - token.length;
      final replaced = text.replaceRange(tokenStart, end, snippet);
      var c = tokenStart + snippet.length;
      if (snippet == '<js></js>') {
        c = tokenStart + '<js>'.length;
      } else if (snippet == '{{}}') {
        c = tokenStart + '{{'.length;
      }
      return TextEditingValue(
        text: replaced,
        selection: TextSelection.collapsed(offset: c.clamp(0, replaced.length)),
      );
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor.clamp(0, newText.length)),
    );
  }
}
