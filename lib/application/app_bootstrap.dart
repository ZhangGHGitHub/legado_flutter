import 'package:flutter/foundation.dart';

import 'database/legacy_room_import_service.dart';
import '../bridge/legado_db_bridge.dart';
import '../bridge/legado_engine_bridge.dart';
import '../config/app_config.dart';
import '../config/engine_config.dart';
import '../database/dao/book_dao.dart';
import '../infrastructure/cache/file_chapter_content_cache.dart';
import '../infrastructure/database/frb_legacy_room_import_port.dart';
import '../providers/book_provider.dart';
import '../services/network_prefs.dart';
import '../services/web_api_service.dart';
import '../services/webdav_prefs.dart';
import '../services/webdav_setup_service.dart';
import '../theme/app_theme.dart';

/// Mirrors the original startup WebDAV initialization without making the
/// first UI depend on a remote server being available.
Future<bool> initializeStartupWebDav({
  required WebDavConfig config,
  required Future<void> Function() initialize,
}) async {
  if (!config.isReady) return false;
  try {
    await initialize();
    return true;
  } catch (e) {
    debugPrint('启动 WebDAV 目录初始化失败: $e');
    return false;
  }
}

/// Loads the shelf before applying the optional startup WebDAV progress pull.
/// Sync failures must not prevent the application from reaching its first UI.
Future<int> loadStartupBookProgress({
  required Future<void> Function() loadBooks,
  required bool enabled,
  required Future<int> Function() downloadAllBookProgress,
}) async {
  await loadBooks();
  if (!enabled) return 0;
  try {
    return await downloadAllBookProgress();
  } catch (e) {
    debugPrint('启动同步阅读进度失败: $e');
    return 0;
  }
}

/// 应用启动阶段的依赖和初始状态。
class AppBootstrapResult {
  const AppBootstrapResult({
    required this.bookProvider,
    required this.themeController,
    required this.legacyRoomImportService,
  });

  final BookProvider bookProvider;
  final ThemeModeController themeController;
  final LegacyRoomImportService legacyRoomImportService;
}

/// 启动用例：集中编排 Rust、数据库、网络配置和首屏数据加载。
class AppBootstrap {
  const AppBootstrap();

  Future<AppBootstrapResult> initialize() async {
    await EngineConfig.load();
    await AppConfig.instance.load();
    await LegadoEngineBridge.tryInit();
    if (LegadoEngineBridge.isAvailable) {
      await LegadoDbBridge.init();
      await NetworkPrefs.restoreToEngine();
      await WebApiService.restoreIfEnabled();
      final webdav = await WebDavPrefs.load();
      await initializeStartupWebDav(
        config: webdav,
        initialize: () => WebDavSetupService.initialize(webdav),
      );
    }

    final bookProvider = BookProvider(
      repository: BookDao(),
      contentCache: const FileChapterContentCache(),
    );
    await loadStartupBookProgress(
      loadBooks: bookProvider.loadBooks,
      enabled:
          LegadoEngineBridge.isAvailable && AppConfig.instance.syncBookProgress,
      downloadAllBookProgress: bookProvider.downloadAllBookProgress,
    );

    final themeController = ThemeModeController();
    await themeController.load();
    return AppBootstrapResult(
      bookProvider: bookProvider,
      themeController: themeController,
      legacyRoomImportService: LegacyRoomImportService(
        FrbLegacyRoomImportPort(),
      ),
    );
  }
}
