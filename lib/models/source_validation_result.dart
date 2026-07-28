import '../domain/ports/book_source_validation_port.dart';

/// Compatibility name for callers that still import the historical model path.
typedef SourceValidationResult = BookSourceValidationSnapshot;

/// 校验用默认搜索词（内置书源用已知关键词）。
String defaultValidationKeyword(String sourceName, String sourceUrl) {
  final hay = '${sourceName.toLowerCase()} ${sourceUrl.toLowerCase()}';
  if (hay.contains('7565') || hay.contains('笔书')) return '斗破';
  if (hay.contains('7497') || hay.contains('番茄')) return '斗罗';
  return '测试';
}
