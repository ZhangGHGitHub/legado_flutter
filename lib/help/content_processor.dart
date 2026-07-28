import '../models/replace_rule.dart';
import '../services/replace_service.dart';
import 'content_help.dart';

/// 正文净化处理器 — 对齐 Legado `ContentProcessor`
class ContentProcessor {
  ContentProcessor._();

  static final ContentProcessor instance = ContentProcessor._();

  final ReplaceService _replaceService = ReplaceService();

  ReplaceService get replaceService => _replaceService;

  void loadRules(List<ReplaceRule> rules) {
    _replaceService.loadRules(rules);
  }

  /// 对正文应用全部启用的替换规则
  String getContent(String raw) => _replaceService.apply(raw);

  /// 批量净化（预留书源级规则扩展）
  String process(String raw, {BookSourceRules? sourceRules}) {
    var result = getContent(raw);
    if (sourceRules != null && sourceRules.contentReplace.isNotEmpty) {
      try {
        result = result.replaceAll(
          RegExp(sourceRules.contentReplace, multiLine: true),
          sourceRules.contentReplaceTo,
        );
      } catch (_) {}
    }
    return result;
  }

  /// Apply the reading-time pipeline used by the original app's
  /// `ContentProcessor.getContent`.
  String processForReading(
    String raw, {
    String chapterTitle = '',
    String bookName = '',
    bool includeTitle = true,
    bool useReplace = true,
    String paragraphIndent = '',
    bool reSegment = true,
    BookSourceRules? sourceRules,
  }) {
    var content = raw;
    if (raw != 'null') {
      content = _removeDuplicateTitle(
        content,
        chapterTitle,
        bookName: bookName,
      );
      if (reSegment && content.isNotEmpty) {
        content = ContentHelp.reSegment(content, chapterTitle);
      }
      if (useReplace) {
        // Legado trims each line before applying content replacement rules.
        content = _trimLines(content);
        content = process(content, sourceRules: sourceRules);
      }
    }

    if (includeTitle && chapterTitle.trim().isNotEmpty) {
      content = '${chapterTitle.trim()}\n$content';
    }

    final paragraphs = content
        .split('\n')
        .map(_trimParagraph)
        .where((line) => line.isNotEmpty)
        .toList();
    final output = <String>[];
    for (var i = 0; i < paragraphs.length; i++) {
      if (i == 0 && includeTitle) {
        output.add(paragraphs[i]);
      } else {
        output.add('$paragraphIndent${paragraphs[i]}');
      }
    }
    return output.join('\n');
  }

  static String _removeDuplicateTitle(
    String content,
    String chapterTitle, {
    String bookName = '',
  }) {
    final title = chapterTitle.trim();
    if (title.isEmpty || content.isEmpty) return content;
    final escaped = title
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(RegExp.escape)
        .join(r'\s*');
    // Kotlin uses (\s|\p{P}|bookName)* before the title. Spell out the
    // punctuation ranges because Dart Unicode property support varies.
    const punctuation =
        r'[\s\u0000-\u002F\u003A-\u0040\u005B-\u0060\u007B-\u007E'
        r'\u2000-\u206F\u2E00-\u2E7F\u3000-\u303F\uFE10-\uFE6F\uFF01-\uFF65]';
    final book = bookName.trim().isEmpty ? '' : RegExp.escape(bookName.trim());
    final prefix = book.isEmpty ? punctuation : '(?:$punctuation|$book)';
    return content.replaceFirst(RegExp('^(?:$prefix)*$escaped\\s*'), '');
  }

  static String _trimParagraph(String line) {
    final runes = line.runes.toList();
    var start = 0;
    var end = runes.length;
    while (start < end && _isOriginalTrimChar(runes[start])) {
      start++;
    }
    while (end > start && _isOriginalTrimChar(runes[end - 1])) {
      end--;
    }
    return String.fromCharCodes(runes.sublist(start, end));
  }

  static bool _isOriginalTrimChar(int rune) => rune <= 0x20 || rune == 0x3000;

  static String _trimLines(String text) =>
      text.split('\n').map(_trimParagraph).join('\n');
}

/// 书源级正文替换（Legado ruleContent.replaceRegex）
class BookSourceRules {
  final String contentReplace;
  final String contentReplaceTo;

  const BookSourceRules({this.contentReplace = '', this.contentReplaceTo = ''});
}
