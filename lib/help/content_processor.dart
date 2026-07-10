import '../models/replace_rule.dart';
import '../services/replace_service.dart';

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
}

/// 书源级正文替换（Legado ruleContent.replaceRegex）
class BookSourceRules {
  final String contentReplace;
  final String contentReplaceTo;

  const BookSourceRules({
    this.contentReplace = '',
    this.contentReplaceTo = '',
  });
}
