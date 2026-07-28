import '../../models/book_source.dart';

/// 书源调试结果中的规则步骤。
class BookSourceDebugStep {
  final String step;
  final String rule;
  final String result;
  final bool ok;

  const BookSourceDebugStep({
    required this.step,
    required this.rule,
    required this.result,
    required this.ok,
  });
}

/// 书源调试结果中的匹配项。
class BookSourceDebugItem {
  final String name;
  final String author;
  final String coverUrl;
  final String bookUrl;
  final String kind;
  final String note;

  const BookSourceDebugItem({
    required this.name,
    required this.author,
    required this.coverUrl,
    required this.bookUrl,
    required this.kind,
    required this.note,
  });
}

/// 书源调试结果的纯 Dart 快照。
///
/// 调试页和格式化器只依赖这个快照，不感知 FRB 生成类型。
class BookSourceDebugSnapshot {
  final String requestUrl;
  final String requestMethod;
  final String responseStatus;
  final String responseCharset;
  final int responseSize;
  final String responseBodyPreview;
  final List<BookSourceDebugStep> ruleSteps;
  final List<BookSourceDebugItem> results;

  const BookSourceDebugSnapshot({
    required this.requestUrl,
    required this.requestMethod,
    required this.responseStatus,
    required this.responseCharset,
    required this.responseSize,
    required this.responseBodyPreview,
    required this.ruleSteps,
    required this.results,
  });
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
