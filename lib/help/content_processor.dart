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
    bool includeTitle = true,
    bool useReplace = true,
    String paragraphIndent = '',
    bool reSegment = true,
    BookSourceRules? sourceRules,
  }) {
    var content = raw;
    if (raw != 'null') {
      content = _removeDuplicateTitle(content, chapterTitle);
      if (reSegment && chapterTitle.isNotEmpty && content.isNotEmpty) {
        content = ContentHelp.reSegment(content, chapterTitle);
      }
      if (useReplace) {
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

  static String _removeDuplicateTitle(String content, String chapterTitle) {
    final title = chapterTitle.trim();
    if (title.isEmpty || content.isEmpty) return content;
    final escaped = RegExp.escape(title).replaceAll(RegExp(r'\s+'), r'\s*');
    final prefix = r'''^[\s.,!?;:，。！？；：、…"'“”‘’（）《》〈〉【】「」『』]*''';
    return content.replaceFirst(RegExp('$prefix$escaped' r'\s*'), '');
  }

  static String _trimParagraph(String line) => line
      .replaceFirst(RegExp(r'^[\s　]+'), '')
      .replaceFirst(RegExp(r'[\s　]+$'), '');
}

/// 书源级正文替换（Legado ruleContent.replaceRegex）
class BookSourceRules {
  final String contentReplace;
  final String contentReplaceTo;

  const BookSourceRules({this.contentReplace = '', this.contentReplaceTo = ''});
}
