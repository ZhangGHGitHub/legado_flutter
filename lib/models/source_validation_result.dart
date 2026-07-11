import '../src/rust/api.dart' as rust_api;

/// 书源校验结果（Rust SourceValidation 的 Dart 封装）
class SourceValidationResult {
  final bool searchOk;
  final bool discoveryOk;
  final bool tocOk;
  final bool contentOk;
  final int searchTimeMs;
  final List<String> errors;

  const SourceValidationResult({
    required this.searchOk,
    required this.discoveryOk,
    required this.tocOk,
    required this.contentOk,
    required this.searchTimeMs,
    this.errors = const [],
  });

  factory SourceValidationResult.fromRust(rust_api.SourceValidation v) {
    return SourceValidationResult(
      searchOk: v.searchOk,
      discoveryOk: v.discoveryOk,
      tocOk: v.tocOk,
      contentOk: v.contentOk,
      searchTimeMs: v.searchTimeMs.toInt(),
      errors: List<String>.from(v.errors),
    );
  }

  bool get allOk => searchOk && discoveryOk && tocOk && contentOk;

  bool get pipelineOk => tocOk && contentOk;
}

/// 校验用默认搜索词（内置书源用已知关键词）
String defaultValidationKeyword(String sourceName, String sourceUrl) {
  final hay = '${sourceName.toLowerCase()} ${sourceUrl.toLowerCase()}';
  if (hay.contains('7565') || hay.contains('笔书')) return '斗破';
  if (hay.contains('7497') || hay.contains('番茄')) return '斗罗';
  return '测试';
}
