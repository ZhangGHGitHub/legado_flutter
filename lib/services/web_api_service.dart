import '../bridge/legado_db_bridge.dart';
import '../bridge/legado_engine_bridge.dart';
import '../src/rust/api.dart' as rust_api;
import 'web_api_prefs.dart';

/// Web API 服务管理
abstract final class WebApiService {
  static rust_api.WebApiStatus? currentStatus() {
    if (!LegadoEngineBridge.isAvailable) return null;
    try {
      return rust_api.webApiStatus();
    } catch (_) {
      return null;
    }
  }

  static Future<rust_api.WebApiStatus?> start({
    int? port,
    String? token,
  }) async {
    if (!LegadoEngineBridge.isAvailable || !LegadoDbBridge.isReady) {
      return null;
    }
    final config = await WebApiPrefs.load();
    final p = port ?? config.port;
    final t = token ?? config.token;
    return rust_api.startWebApi(port: p, token: t);
  }

  static Future<void> stop() async {
    if (!LegadoEngineBridge.isAvailable) return;
    await rust_api.stopWebApi();
  }

  static Future<rust_api.WebApiStatus?> setEnabled(bool enabled) async {
    final config = await WebApiPrefs.load();
    if (!enabled) {
      await stop();
      await WebApiPrefs.save(config.copyWith(enabled: false));
      return currentStatus();
    }

    final status = await start(port: config.port, token: config.token);
    if (status != null) {
      await WebApiPrefs.save(
        config.copyWith(
          enabled: true,
          port: status.port,
          token: status.token,
        ),
      );
    }
    return status;
  }

  static Future<void> restoreIfEnabled() async {
    final config = await WebApiPrefs.load();
    if (config.enabled) {
      await start(port: config.port, token: config.token);
    }
  }

  static String apiUrl(rust_api.WebApiStatus status, String path) {
    final base = status.baseUrl;
    final sep = path.startsWith('/') ? '' : '/';
    return '$base$sep$path';
  }
}
