import 'package:shared_preferences/shared_preferences.dart';

/// WebDAV 配置（仅本地存储，F3 UI 先行）
class WebDavConfig {
  final String url;
  final String account;
  final String password;
  final String dir;
  final String device;

  const WebDavConfig({
    this.url = '',
    this.account = '',
    this.password = '',
    this.dir = '/legado',
    this.device = 'Legado Flutter',
  });

  bool get isConfigured => url.trim().isNotEmpty;
}

abstract final class WebDavPrefs {
  static const _urlKey = 'webdav_url';
  static const _accountKey = 'webdav_account';
  static const _passwordKey = 'webdav_password';
  static const _dirKey = 'webdav_dir';
  static const _deviceKey = 'webdav_device';
  static const webServiceKey = 'web_service_on';

  static Future<WebDavConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return WebDavConfig(
      url: prefs.getString(_urlKey) ?? '',
      account: prefs.getString(_accountKey) ?? '',
      password: prefs.getString(_passwordKey) ?? '',
      dir: prefs.getString(_dirKey) ?? '/legado',
      device: prefs.getString(_deviceKey) ?? 'Legado Flutter',
    );
  }

  static Future<void> save(WebDavConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, config.url);
    await prefs.setString(_accountKey, config.account);
    await prefs.setString(_passwordKey, config.password);
    await prefs.setString(_dirKey, config.dir);
    await prefs.setString(_deviceKey, config.device);
  }

  static Future<bool> loadWebServiceOn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(webServiceKey) ?? false;
  }

  static Future<void> saveWebServiceOn(bool on) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(webServiceKey, on);
  }
}
