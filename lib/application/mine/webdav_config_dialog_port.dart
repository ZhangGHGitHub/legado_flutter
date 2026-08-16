import '../bookshelf/webdav_prefs_port.dart';

export '../bookshelf/webdav_prefs_port.dart' show WebDavConfig, WebDavPrefsPort;

/// WebDAV 配置对话框所需的应用边界。
///
/// 读取契约复用远程书籍使用的 [WebDavPrefsPort]；保存和连接初始化由
/// 配置适配器负责，页面不直接依赖偏好存储或 WebDAV service。
abstract interface class WebDavConfigDialogPort implements WebDavPrefsPort {
  Future<void> save(WebDavConfig config);

  Future<void> initialize(WebDavConfig config);
}
