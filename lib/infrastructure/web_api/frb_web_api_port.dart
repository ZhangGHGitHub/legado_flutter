import '../../bridge/legado_db_bridge.dart';
import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/web_api_port.dart';
import '../../domain/web_api_status.dart';
import '../../src/rust/api.dart' as rust_api;

/// FRB adapter for the local Web API lifecycle.
class FrbWebApiPort implements WebApiPort {
  @override
  bool get isAvailable =>
      LegadoEngineBridge.isAvailable && LegadoDbBridge.isReady;

  @override
  WebApiStatus? currentStatus() {
    if (!LegadoEngineBridge.isAvailable) return null;
    try {
      return _fromGenerated(rust_api.webApiStatus());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WebApiStatus?> start({
    required int port,
    required String token,
  }) async {
    if (!isAvailable) return null;
    return _fromGenerated(await rust_api.startWebApi(port: port, token: token));
  }

  @override
  Future<void> stop() {
    if (!LegadoEngineBridge.isAvailable) return Future<void>.value();
    return rust_api.stopWebApi();
  }

  static WebApiStatus _fromGenerated(rust_api.WebApiStatus status) {
    return WebApiStatus(
      running: status.running,
      port: status.port,
      token: status.token,
      baseUrl: status.baseUrl,
    );
  }
}
