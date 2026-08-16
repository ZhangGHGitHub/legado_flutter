import 'package:flutter/material.dart';

import 'code_edit_theme.dart';

/// 轻量 JSON/JS 词法着色 — 颜色对齐 Jingshiro Monokai TextMate token。
class HighlightEditingController extends TextEditingController {
  HighlightEditingController({super.text, required CodeEditPalette palette})
    : _palette = palette;

  CodeEditPalette _palette;

  CodeEditPalette get palette => _palette;

  set palette(CodeEditPalette value) {
    if (_palette == value) return;
    _palette = value;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = (style ?? const TextStyle()).copyWith(
      color: _palette.foreground,
      fontFamily: 'monospace',
    );
    return TextSpan(
      style: base,
      children: highlightJsJson(text, _palette, base),
    );
  }
}

List<InlineSpan> highlightJsJson(
  String source,
  CodeEditPalette p,
  TextStyle base,
) {
  if (source.isEmpty) return const [];

  final spans = <InlineSpan>[];
  final keywords = _jsKeywords;
  var i = 0;

  TextStyle sty(Color c, {bool italic = false}) => base.copyWith(
    color: c,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  );

  void emit(String s, TextStyle style) {
    if (s.isEmpty) return;
    spans.add(TextSpan(text: s, style: style));
  }

  while (i < source.length) {
    final ch = source[i];

    // line comment
    if (ch == '/' && i + 1 < source.length && source[i + 1] == '/') {
      final end = source.indexOf('\n', i);
      final stop = end < 0 ? source.length : end;
      emit(source.substring(i, stop), sty(p.comment, italic: true));
      i = stop;
      continue;
    }
    // block comment
    if (ch == '/' && i + 1 < source.length && source[i + 1] == '*') {
      final end = source.indexOf('*/', i + 2);
      final stop = end < 0 ? source.length : end + 2;
      emit(source.substring(i, stop), sty(p.comment, italic: true));
      i = stop;
      continue;
    }
    // string
    if (ch == '"' || ch == "'" || ch == '`') {
      final quote = ch;
      var j = i + 1;
      while (j < source.length) {
        if (source[j] == '\\') {
          j += 2;
          continue;
        }
        if (source[j] == quote) {
          j++;
          break;
        }
        j++;
      }
      final lit = source.substring(i, j);
      // JSON key heuristic: "key":
      var k = j;
      while (k < source.length &&
          (source[k] == ' ' || source[k] == '\t' || source[k] == '\n')) {
        k++;
      }
      final isKey = quote == '"' && k < source.length && source[k] == ':';
      emit(lit, sty(isKey ? p.keyName : p.string));
      i = j;
      continue;
    }
    // number
    if (_isDigit(ch) ||
        (ch == '.' && i + 1 < source.length && _isDigit(source[i + 1])) ||
        (ch == '-' && i + 1 < source.length && _isDigit(source[i + 1]))) {
      var j = i + 1;
      while (j < source.length &&
          (_isDigit(source[j]) ||
              source[j] == '.' ||
              source[j] == 'e' ||
              source[j] == 'E' ||
              source[j] == '+' ||
              source[j] == '-')) {
        j++;
      }
      emit(source.substring(i, j), sty(p.number));
      i = j;
      continue;
    }
    // identifier / keyword
    if (_isIdentStart(ch)) {
      var j = i + 1;
      while (j < source.length && _isIdentPart(source[j])) {
        j++;
      }
      final word = source.substring(i, j);
      if (keywords.contains(word)) {
        emit(word, sty(p.keyword));
      } else if (word == 'true' || word == 'false' || word == 'null') {
        emit(word, sty(p.number));
      } else if (j < source.length && source[j] == '(') {
        emit(word, sty(p.function));
      } else if (_typeWords.contains(word)) {
        emit(word, sty(p.storageType));
      } else {
        emit(word, sty(p.foreground));
      }
      i = j;
      continue;
    }
    // punctuation / other
    emit(ch, sty(p.punctuation));
    i++;
  }
  return spans;
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

bool _isIdentStart(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 65 && u <= 90) ||
      (u >= 97 && u <= 122) ||
      u == 95 ||
      u == 36 ||
      u > 127;
}

bool _isIdentPart(String c) => _isIdentStart(c) || _isDigit(c);

const _jsKeywords = {
  'let',
  'const',
  'var',
  'function',
  'return',
  'if',
  'else',
  'for',
  'while',
  'do',
  'switch',
  'case',
  'break',
  'continue',
  'try',
  'catch',
  'finally',
  'throw',
  'new',
  'typeof',
  'instanceof',
  'in',
  'of',
  'this',
  'class',
  'extends',
  'super',
  'import',
  'export',
  'from',
  'default',
  'async',
  'await',
  'yield',
  'void',
  'delete',
  'with',
  'debugger',
};

const _typeWords = {
  'String',
  'Number',
  'Boolean',
  'Object',
  'Array',
  'Map',
  'Set',
  'Promise',
  'Date',
  'RegExp',
  'JSON',
  'Math',
};
