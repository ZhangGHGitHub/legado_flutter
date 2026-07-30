import '../../application/web_api/web_api_prefs_port.dart';
import '../../services/web_api_prefs.dart' as service;

/// 保留既有 Web API SharedPreferences 键名的 adapter。
final class SharedPreferencesWebApiPrefsAdapter implements WebApiPrefsPort {
  const SharedPreferencesWebApiPrefsAdapter();

  @override
  Future<WebApiConfig> load() => service.WebApiPrefs.load();

  @override
  Future<void> save(WebApiConfig config) => service.WebApiPrefs.save(config);
}
