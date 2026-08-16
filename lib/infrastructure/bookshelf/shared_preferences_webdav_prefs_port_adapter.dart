import '../../application/bookshelf/webdav_prefs_port.dart';
import '../../services/webdav_prefs.dart' as service;

/// 保留 WebDAV 偏好键名、默认值和 SharedPreferences 初始化语义的适配器。
final class SharedPreferencesWebDavPrefsPortAdapter implements WebDavPrefsPort {
  const SharedPreferencesWebDavPrefsPortAdapter();

  @override
  Future<WebDavConfig> load() => service.WebDavPrefs.load();
}
