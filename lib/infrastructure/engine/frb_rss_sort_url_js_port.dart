import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/rss_sort_url_js_port.dart';
import '../../models/rss_source.dart';
import '../../src/rust/api.dart' as rust_api;

class FrbRssSortUrlJsPort implements RssSortUrlJsPort {
  @override
  bool get isAvailable => LegadoEngineBridge.isAvailable;

  @override
  String evaluate({required RssSource source, required String script}) {
    if (!isAvailable) {
      throw StateError('Rust 引擎不可用，无法执行 sortUrl JS');
    }
    return rust_api.evalJs(
      script: script,
      jsLib: source.jsLib,
      baseUrl: source.sourceUrl,
    );
  }
}
