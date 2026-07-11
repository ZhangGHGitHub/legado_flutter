import 'package:shared_preferences/shared_preferences.dart';

/// Web API 本地配置
class WebApiConfig {
  final bool enabled;
  final int port;
  final String token;

  const WebApiConfig({
    this.enabled = false,
    this.port = 1122,
    this.token = '',
  });

  WebApiConfig copyWith({bool? enabled, int? port, String? token}) {
    return WebApiConfig(
      enabled: enabled ?? this.enabled,
      port: port ?? this.port,
      token: token ?? this.token,
    );
  }
}

abstract final class WebApiPrefs {
  static const enabledKey = 'web_api_enabled';
  static const portKey = 'web_api_port';
  static const tokenKey = 'web_api_token';
  static const defaultPort = 1122;

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
