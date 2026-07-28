import '../domain/ports/webdav_repository.dart';
import '../infrastructure/webdav/default_webdav_repository.dart';
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
    WebDavRepository repository = defaultWebDavRepository,
    WebDavCheckInvoker? check,
    WebDavEnsureDirInvoker? ensureDir,
  }) async {
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }

    final args = (
      url: config.url,
      username: config.account,
      password: config.password,
    );
    final checkInvoker = check ?? repository.check;
    final ensureDirInvoker = ensureDir ?? repository.ensureDir;
    await checkInvoker(
      url: args.url,
      username: args.username,
      password: args.password,
      path: config.rootDir,
    );
    await ensureDirInvoker(
      url: args.url,
      username: args.username,
      password: args.password,
      path: config.rootDir,
    );
    for (final directory in _directories) {
      await ensureDirInvoker(
        url: args.url,
        username: args.username,
        password: args.password,
        path: WebDavConfig.joinPath(config.rootDir, directory),
      );
    }
  }
}
