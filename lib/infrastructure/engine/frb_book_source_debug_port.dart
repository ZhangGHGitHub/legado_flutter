import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/book_source_debug_port.dart';
import '../../models/book_source.dart';
import '../../src/rust/api.dart' as rust_api;

/// Rust/FRB 书源调试适配器。
class FrbBookSourceDebugPort implements BookSourceDebugPort {
  @override
  bool get isAvailable => LegadoEngineBridge.isAvailable;

  @override
  Future<BookSourceDebugSnapshot> debugSearch(
    BookSource source,
    String keyword,
  ) async {
    _ensureAvailable();
    return _mapResult(await LegadoEngineBridge.debugSearch(source, keyword));
  }

  @override
  Future<BookSourceDebugSnapshot> debugToc(
    BookSource source,
    String bookUrl,
  ) async {
    _ensureAvailable();
    return _mapResult(await LegadoEngineBridge.debugToc(source, bookUrl));
  }

  @override
  Future<String> httpFetch(
    String url, {
    String method = 'GET',
    String? referer,
    String charset = 'UTF-8',
    BookSource? source,
  }) {
    _ensureAvailable();
    return LegadoEngineBridge.httpFetch(
      url,
      method: method,
      referer: referer,
      charset: charset,
      source: source,
    );
  }

  void _ensureAvailable() {
    if (!isAvailable) {
      throw StateError('Rust 引擎未加载，请编译 legado_engine 后重试');
    }
  }
}

BookSourceDebugSnapshot _mapResult(rust_api.DebugResult result) {
  return BookSourceDebugSnapshot(
    requestUrl: result.requestUrl,
    requestMethod: result.requestMethod,
    responseStatus: result.responseStatus,
    responseCharset: result.responseCharset,
    responseSize: result.responseSize.toInt(),
    responseBodyPreview: result.responseBodyPreview,
    ruleSteps: [
      for (final step in result.ruleSteps)
        BookSourceDebugStep(
          step: step.step,
          rule: step.rule,
          result: step.result,
          ok: step.ok,
        ),
    ],
    results: [
      for (final item in result.results)
        BookSourceDebugItem(
          name: item.name,
          author: item.author,
          coverUrl: item.coverUrl,
          bookUrl: item.bookUrl,
          kind: item.kind,
          note: item.note,
        ),
    ],
  );
}
