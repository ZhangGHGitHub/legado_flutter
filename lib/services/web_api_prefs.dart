import 'package:shared_preferences/shared_preferences.dart';

import '../application/web_api/web_api_prefs_port.dart';

export '../application/web_api/web_api_prefs_port.dart' show WebApiConfig;

abstract final class WebApiPrefs {
  static const enabledKey = 'web_api_enabled';
  static const portKey = 'web_api_port';
  static const tokenKey = 'web_api_token';
  static const defaultPort = WebApiPrefsPort.defaultPort;

  static Future<WebApiConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return WebApiConfig(
      enabled: prefs.getBool(enabledKey) ?? false,
      port: prefs.getInt(portKey) ?? defaultPort,
      token: prefs.getString(tokenKey) ?? '',
    );
  }

  static Future<void> save(WebApiConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, config.enabled);
    await prefs.setInt(portKey, config.port);
    await prefs.setString(tokenKey, config.token);
  }
}
