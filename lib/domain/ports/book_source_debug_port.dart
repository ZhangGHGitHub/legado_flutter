import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:legado_flutter/domain/source/book_source.dart';

part 'book_source_debug_port.freezed.dart';

/// 书源调试结果中的规则步骤。
@freezed
class BookSourceDebugStep with _$BookSourceDebugStep {
  const factory BookSourceDebugStep({
    required String step,
    required String rule,
    required String result,
    required bool ok,
  }) = _BookSourceDebugStep;
}

/// 书源调试结果中的匹配项。
@freezed
class BookSourceDebugItem with _$BookSourceDebugItem {
  const factory BookSourceDebugItem({
    required String name,
    required String author,
    required String coverUrl,
    required String bookUrl,
    required String kind,
    required String note,
  }) = _BookSourceDebugItem;
}

/// 书源调试结果的纯 Dart 快照。
///
/// 调试页和格式化器只依赖这个快照，不感知 FRB 生成类型。
@freezed
class BookSourceDebugSnapshot with _$BookSourceDebugSnapshot {
  const factory BookSourceDebugSnapshot({
    required String requestUrl,
    required String requestMethod,
    required String responseStatus,
    required String responseCharset,
    required int responseSize,
    required String responseBodyPreview,
    required List<BookSourceDebugStep> ruleSteps,
    required List<BookSourceDebugItem> results,
  }) = _BookSourceDebugSnapshot;
}

/// 书源调试用例所需的引擎端口。
abstract interface class BookSourceDebugPort {
  bool get isAvailable;

  Future<BookSourceDebugSnapshot> debugSearch(
    BookSource source,
    String keyword,
  );

  Future<BookSourceDebugSnapshot> debugToc(BookSource source, String bookUrl);

  Future<String> httpFetch(
    String url, {
    String method,
    String? referer,
    String charset,
    BookSource? source,
  });
}
