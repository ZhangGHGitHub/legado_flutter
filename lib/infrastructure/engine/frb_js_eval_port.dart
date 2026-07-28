import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/js_eval_port.dart';
import '../../src/rust/api.dart' as rust_api;

/// Rust/FRB 裸 JS 执行适配器。
class FrbJsEvalPort implements JsEvalPort {
  const FrbJsEvalPort();

  @override
  bool get isAvailable => LegadoEngineBridge.isAvailable;

  @override
  String eval({
    required String script,
    required String jsLib,
    required String baseUrl,
  }) {
    if (!isAvailable) {
      throw StateError('Rust 引擎不可用，无法执行登录 JS');
    }
    return rust_api.evalJs(script: script, jsLib: jsLib, baseUrl: baseUrl);
  }
}
