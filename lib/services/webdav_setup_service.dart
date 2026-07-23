import '../src/rust/api/webdav.dart' as webdav_api;
import 'webdav_prefs.dart';

typedef WebDavCheckInvoker =
    Future<void> Function({
      required String url,
      required String username,
      required String password,
      required String path,
    });

typedef WebDavEnsureDirInvoker =
    Future<void> Function({
      required String url,
      required String username,
      required String password,
      required String path,
    });

/// 对齐原版 AppWebDav.upConfig 的凭证检查和目录初始化顺序。
abstract final class WebDavSetupService {
  static const _directories = <String>['bookProgress', 'books', 'background'];

  static Future<void> initialize(
    WebDavConfig config, {
    WebDavCheckInvoker check = webdav_api.webdavCheck,
    WebDavEnsureDirInvoker ensureDir = webdav_api.webdavEnsureDir,
  }) async {
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }

    final args = (
      url: config.url,
      username: config.account,
      password: config.password,
    );
    await check(
      url: args.url,
      username: args.username,
      password: args.password,
      path: config.rootDir,
    );
    await ensureDir(
      url: args.url,
      username: args.username,
      password: args.password,
      path: config.rootDir,
    );
    for (final directory in _directories) {
      await ensureDir(
        url: args.url,
        username: args.username,
        password: args.password,
        path: WebDavConfig.joinPath(config.rootDir, directory),
      );
    }
  }
}
