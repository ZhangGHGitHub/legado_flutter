import '../../models/book_source.dart';

/// Rust 书源校验结果在领域边界上的纯 Dart 快照。
///
/// 不暴露 FRB 生成的 SourceValidation 类型，避免 SourceProvider 依赖
/// infrastructure 的绑定细节。
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

/// 书源校验用例所需的引擎端口。
abstract interface class BookSourceValidationPort {
  bool get isAvailable;

  Future<BookSourceValidationSnapshot> validateSource(
    BookSource source, {
    required String keyword,
  });
}
