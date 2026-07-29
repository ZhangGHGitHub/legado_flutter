import 'package:uuid/uuid.dart';

import 'package:flutter/foundation.dart';

import '../domain/ports/web_api_port.dart';
import '../domain/web_api_status.dart';
import 'web_api_prefs.dart';

/// Web API 服务管理
abstract final class WebApiService {
  static final _uuid = Uuid();
  static WebApiPort? _webApiPort;

  static void configureWebApiPort(WebApiPort port) {
    _webApiPort = port;
  }

  @visibleForTesting
  static void resetWebApiPort() {
    _webApiPort = null;
  }

  static bool get isAvailable => _webApiPort?.isAvailable ?? false;

  static WebApiStatus? currentStatus() {
    return _webApiPort?.currentStatus();
  }

  static Future<WebApiStatus?> start({int? port, String? token}) async {
    final webApiPort = _webApiPort;
    if (webApiPort == null || !webApiPort.isAvailable) return null;
    final config = await WebApiPrefs.load();
    final p = port ?? config.port;
    final configuredToken = (token ?? config.token).trim();
    final t = configuredToken.isEmpty ? _uuid.v4() : configuredToken;
    return webApiPort.start(port: p, token: t);
  }

  static Future<void> stop() async {
    await _webApiPort?.stop();
  }

  static Future<WebApiStatus?> setEnabled(bool enabled) async {
    final config = await WebApiPrefs.load();
    if (!enabled) {
      await stop();
      await WebApiPrefs.save(config.copyWith(enabled: false));
      return currentStatus();
    }

    final status = await start(port: config.port, token: config.token);
    if (status != null) {
      await WebApiPrefs.save(
        config.copyWith(enabled: true, port: status.port, token: status.token),
      );
    }
    return status;
  }

  static Future<void> restoreIfEnabled() async {
    final config = await WebApiPrefs.load();
    if (config.enabled) {
      final status = await start(port: config.port, token: config.token);
      if (status != null &&
          (config.port != status.port || config.token != status.token)) {
        await WebApiPrefs.save(
          config.copyWith(port: status.port, token: status.token),
        );
      }
    }
  }

  static String apiUrl(WebApiStatus status, String path) {
    final base = status.baseUrl;
    final sep = path.startsWith('/') ? '' : '/';
    return '$base$sep$path';
  }
}
