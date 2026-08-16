import '../../services/webdav_prefs.dart' show WebDavConfig;

export '../../services/webdav_prefs.dart' show WebDavConfig;

/// 远程书籍页面读取 WebDAV 配置所需的应用端口。
abstract interface class WebDavPrefsPort {
  Future<WebDavConfig> load();
}
