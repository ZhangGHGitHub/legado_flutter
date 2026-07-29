/// 书源校验结果在领域边界上的纯 Dart 快照。
class BookSourceValidationSnapshot {
  final bool searchOk;
  final bool discoveryOk;
  final bool tocOk;
  final bool contentOk;
  final int searchTimeMs;
  final List<String> errors;

  const BookSourceValidationSnapshot({
    required this.searchOk,
    required this.discoveryOk,
    required this.tocOk,
    required this.contentOk,
    required this.searchTimeMs,
    this.errors = const [],
  });

  bool get allOk => searchOk && discoveryOk && tocOk && contentOk;

  bool get pipelineOk => tocOk && contentOk;
}

/// 业务调用方沿用的历史结果名称。
typedef SourceValidationResult = BookSourceValidationSnapshot;
