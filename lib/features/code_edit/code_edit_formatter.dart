import 'dart:convert';

/// 代码格式化 — 对齐 Jingshiro [CodeEditViewModel.formatCode] 分支。
///
/// Android 用 WebView + js-beautify(indent_size:4)；此处 best-effort：
/// JSON → 缩进；`<js>` / `@js:` / `@webjs:` 段与纯 JS → 轻量 beautify。
abstract final class CodeEditFormatter {
  static const indentUnit = '    '; // 4 spaces，对齐 js_beautify indent_size

  static String format(String text, {String? languageName}) {
    final lang = languageName ?? '';
    if (lang.contains('markdown')) {
      throw const FormatSkipException('markdown不需要格式化');
    }
    if (lang.contains('html') || _looksLikeHtml(text)) {
      return _formatLooseHtml(text);
    }

    // 整段 JSON
    final trimmed = text.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        return const JsonEncoder.withIndent('    ').convert(decoded);
      } catch (_) {
        // fall through to JS / segment format
      }
    }

    return _formatWithJsSegments(text);
  }

  static bool _looksLikeHtml(String text) {
    final t = text.trim();
    return RegExp(
          r'^(?:\[[\s\d.]])?<(?:html|!DOCTYPE)',
          caseSensitive: false,
        ).hasMatch(t) &&
        t.endsWith('>');
  }

  /// 对齐 ViewModel：拆 `<js>` / `@js:` / `@webjs:` 再 beautify。
  static String _formatWithJsSegments(String text) {
    var result = '';
    var start = 0;

    final indexS = text.indexOf('<js>');
    if (indexS >= 0) {
      if (indexS > 0) {
        result += text.substring(start, indexS).trim();
      }
      final indexE = text.indexOf('</js>', indexS);
      if (indexE < 0) {
        return beautifyJs(text);
      }
      final jsCode = text.substring(indexS + 4, indexE);
      result += '<js>\n';
      result += beautifyJs(jsCode);
      result += '\n</js>';
      start = indexE + 5;
    }

    final rest = text.substring(start);
    final indexS2 = rest.indexOf('@js:');
    if (indexS2 >= 0) {
      if (indexS2 > 0) {
        result += rest.substring(0, indexS2).trim();
      }
      result += '@js:\n';
      result += beautifyJs(rest.substring(indexS2 + 4));
      return result;
    }
    final indexS3 = rest.indexOf('@webjs:');
    if (indexS3 >= 0) {
      if (indexS3 > 0) {
        result += rest.substring(0, indexS3).trim();
      }
      result += '@webjs:\n';
      result += beautifyJs(rest.substring(indexS3 + 7));
      return result;
    }

    if (start == 0) {
      return beautifyJs(text);
    }
    if (rest.isNotEmpty) {
      result += rest.trim();
    }
    return result;
  }

  /// 轻量 JS beautify：花括号/方括号缩进、逗号后换行、字符串/注释保护。
  static String beautifyJs(String code) {
    final src = code.trim();
    if (src.isEmpty) return src;

    // 已是合法 JSON 对象/数组时走标准缩进
    if ((src.startsWith('{') && src.endsWith('}')) ||
        (src.startsWith('[') && src.endsWith(']'))) {
      try {
        return const JsonEncoder.withIndent(
          indentUnit,
        ).convert(jsonDecode(src));
      } catch (_) {}
    }

    final buf = StringBuffer();
    var depth = 0;
    var i = 0;
    var lineStart = true;

    void newline() {
      buf.writeln();
      lineStart = true;
    }

    void indent() {
      if (lineStart) {
        buf.write(indentUnit * depth);
        lineStart = false;
      }
    }

    while (i < src.length) {
      final ch = src[i];

      // comments
      if (ch == '/' && i + 1 < src.length && src[i + 1] == '/') {
        indent();
        final end = src.indexOf('\n', i);
        final stop = end < 0 ? src.length : end;
        buf.write(src.substring(i, stop).trimRight());
        i = stop;
        if (i < src.length) {
          newline();
          i++;
        }
        continue;
      }
      if (ch == '/' && i + 1 < src.length && src[i + 1] == '*') {
        indent();
        final end = src.indexOf('*/', i + 2);
        final stop = end < 0 ? src.length : end + 2;
        buf.write(src.substring(i, stop));
        i = stop;
        continue;
      }
      // strings
      if (ch == '"' || ch == "'" || ch == '`') {
        indent();
        final quote = ch;
        var j = i + 1;
        while (j < src.length) {
          if (src[j] == '\\') {
            j += 2;
            continue;
          }
          if (src[j] == quote) {
            j++;
            break;
          }
          j++;
        }
        buf.write(src.substring(i, j));
        i = j;
        lineStart = false;
        continue;
      }

      if (ch == ' ' || ch == '\t' || ch == '\r') {
        i++;
        continue;
      }
      if (ch == '\n') {
        if (!lineStart) newline();
        i++;
        continue;
      }

      if (ch == '}' || ch == ']' || ch == ')') {
        depth = depth > 0 ? depth - 1 : 0;
        if (!lineStart) newline();
        indent();
        buf.write(ch);
        lineStart = false;
        i++;
        if (i < src.length && src[i] == ',') {
          buf.write(',');
          i++;
          newline();
        } else if (i < src.length &&
            (src[i] == '}' || src[i] == ']' || src[i] == ')')) {
          newline();
        }
        continue;
      }

      if (ch == '{' || ch == '[' || ch == '(') {
        indent();
        buf.write(ch);
        depth++;
        newline();
        i++;
        continue;
      }

      if (ch == ',') {
        buf.write(',');
        newline();
        i++;
        continue;
      }

      if (ch == ';') {
        buf.write(';');
        newline();
        i++;
        continue;
      }

      indent();
      buf.write(ch);
      lineStart = false;
      i++;
    }

    var out = buf.toString();
    // 折叠多余空行（max_preserve_newlines: 5 → 这里压到 2）
    out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return out.trim();
  }

  static String _formatLooseHtml(String html) {
    // 无 Jsoup：按标签粗略换行缩进
    final compact = html
        .replaceAll(RegExp(r'>\s*<'), '>\n<')
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final buf = StringBuffer();
    var depth = 0;
    for (final line in compact) {
      final closing = RegExp(r'^</\w').hasMatch(line);
      final selfClose =
          line.endsWith('/>') ||
          RegExp(
            r'^<(br|hr|img|meta|link|input)\b',
            caseSensitive: false,
          ).hasMatch(line);
      if (closing) depth = depth > 0 ? depth - 1 : 0;
      buf.writeln('${indentUnit * depth}$line');
      if (!closing &&
          !selfClose &&
          line.startsWith('<') &&
          !line.startsWith('<!')) {
        depth++;
      }
    }
    return buf.toString().trimRight();
  }
}

class FormatSkipException implements Exception {
  const FormatSkipException(this.message);
  final String message;
  @override
  String toString() => message;
}
