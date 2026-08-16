import '../domain/ports/webdav_repository.dart';
import 'webdav_prefs.dart';

/// 对齐原版 AppWebDav.upConfig 的凭证检查和目录初始化顺序。
abstract final class WebDavSetupService {
  static const _directories = <String>['bookProgress', 'books', 'background'];

  static Future<void> initialize(
    WebDavConfig config, {
    required WebDavRepository repository,
  }) async {
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }

    final args = (
      url: config.url,
      username: config.account,
      password: config.password,
    );
    await repository.check(
      url: args.url,
      username: args.username,
      password: args.password,
      path: config.rootDir,
    );
    await repository.ensureDir(
      url: args.url,
      username: args.username,
      password: args.password,
      path: config.rootDir,
    );
    for (final directory in _directories) {
      await repository.ensureDir(
        url: args.url,
        username: args.username,
        password: args.password,
        path: WebDavConfig.joinPath(config.rootDir, directory),
      );
    }
  }
}
