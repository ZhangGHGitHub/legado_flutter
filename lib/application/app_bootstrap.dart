import 'package:flutter/foundation.dart';

import 'database/legacy_room_import_service.dart';
import '../domain/ports/chapter_content_cache_port.dart';
import '../domain/ports/content_processing_port.dart';
import '../domain/ports/webdav_repository.dart';
import '../domain/repositories/book_repository.dart';
import '../model/read_book.dart';
import '../providers/book_provider.dart';
import '../services/book_source_service.dart';
import '../services/backup_service.dart';
import '../services/book_progress_sync.dart';
import '../services/bookmark_sync_service.dart';
import '../services/cache_service.dart';
import '../services/local_book_service.dart';
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
    required this.bookSourceService,
    required this.themeController,
    required this.legacyRoomImportService,
    required this.backupService,
    required this.bookProgressSync,
    required this.bookmarkSyncService,
    required this.cacheService,
    required this.webdavRepository,
  });

  final BookProvider bookProvider;
  final BookSourceService bookSourceService;
  final ThemeModeController themeController;
  final LegacyRoomImportService legacyRoomImportService;
  final BackupService backupService;
  final BookProgressSync bookProgressSync;
  final BookmarkSyncService bookmarkSyncService;
  final CacheService cacheService;
  final WebDavRepository webdavRepository;
}

/// 启动用例：集中编排 Rust、数据库、网络配置和首屏数据加载。
class AppBootstrap {
  const AppBootstrap({
    required Future<void> Function() initializePlatform,
    required bool Function() isEngineAvailable,
    required bool Function() isBookProgressSyncEnabled,
    required Future<void> Function() restoreNetwork,
    required Future<void> Function() restoreWebApi,
    required Future<WebDavConfig> Function() loadWebDavConfig,
    required BookRepository bookRepository,
    required ChapterContentCachePort contentCache,
    required ContentProcessingPort contentProcessor,
    required BookSourceService bookSourceService,
    required LocalBookService localBookService,
    required LegacyRoomImportService legacyRoomImportService,
    required BackupService backupService,
    required BookProgressSync bookProgressSync,
    required BookmarkSyncService bookmarkSyncService,
    required CacheService cacheService,
    required WebDavRepository webdavRepository,
    void Function(String stage)? reportStartupStage,
  }) : _initializePlatform = initializePlatform,
       _isEngineAvailable = isEngineAvailable,
       _isBookProgressSyncEnabled = isBookProgressSyncEnabled,
       _restoreNetwork = restoreNetwork,
       _restoreWebApi = restoreWebApi,
       _loadWebDavConfig = loadWebDavConfig,
       _bookRepository = bookRepository,
       _contentCache = contentCache,
       _contentProcessor = contentProcessor,
       _bookSourceService = bookSourceService,
       _localBookService = localBookService,
       _legacyRoomImportService = legacyRoomImportService,
       _backupService = backupService,
       _bookProgressSync = bookProgressSync,
       _bookmarkSyncService = bookmarkSyncService,
       _cacheService = cacheService,
       _webdavRepository = webdavRepository,
       _reportStartupStage = reportStartupStage;

  final Future<void> Function() _initializePlatform;
  final bool Function() _isEngineAvailable;
  final bool Function() _isBookProgressSyncEnabled;
  final Future<void> Function() _restoreNetwork;
  final Future<void> Function() _restoreWebApi;
  final Future<WebDavConfig> Function() _loadWebDavConfig;
  final BookRepository _bookRepository;
  final ChapterContentCachePort _contentCache;
  final ContentProcessingPort _contentProcessor;
  final BookSourceService _bookSourceService;
  final LocalBookService _localBookService;
  final LegacyRoomImportService _legacyRoomImportService;
  final BackupService _backupService;
  final BookProgressSync _bookProgressSync;
  final BookmarkSyncService _bookmarkSyncService;
  final CacheService _cacheService;
  final WebDavRepository _webdavRepository;
  final void Function(String stage)? _reportStartupStage;

  Future<AppBootstrapResult> initialize() async {
    _reportStartupStage?.call('平台、配置与引擎初始化');
    await _initializePlatform();
    if (_isEngineAvailable()) {
      _reportStartupStage?.call('网络与本地服务恢复');
      await _restoreNetwork();
      await _restoreWebApi();
      _reportStartupStage?.call('WebDAV 配置恢复');
      final webdav = await _loadWebDavConfig();
      await initializeStartupWebDav(
        config: webdav,
        initialize: () => WebDavSetupService.initialize(
          webdav,
          repository: _webdavRepository,
        ),
      );
    }

    _reportStartupStage?.call('阅读会话依赖组装');
    ReadBook.instance.configureDependencies(
      sourceService: _bookSourceService,
      repository: _bookRepository,
      contentProcessor: _contentProcessor,
      contentCache: _contentCache,
    );
    final bookProvider = BookProvider(
      repository: _bookRepository,
      sourceService: _bookSourceService,
      localService: _localBookService,
      contentCache: _contentCache,
    );
    _reportStartupStage?.call('书架与阅读进度加载');
    await loadStartupBookProgress(
      loadBooks: bookProvider.loadBooks,
      enabled: _isEngineAvailable() && _isBookProgressSyncEnabled(),
      downloadAllBookProgress: () =>
          bookProvider.downloadAllBookProgress(sync: _bookProgressSync),
    );

    _reportStartupStage?.call('主题配置加载');
    final themeController = ThemeModeController();
    await themeController.load();
    _reportStartupStage?.call('应用状态组装完成');
    return AppBootstrapResult(
      bookProvider: bookProvider,
      bookSourceService: _bookSourceService,
      themeController: themeController,
      legacyRoomImportService: _legacyRoomImportService,
      backupService: _backupService,
      bookProgressSync: _bookProgressSync,
      bookmarkSyncService: _bookmarkSyncService,
      cacheService: _cacheService,
      webdavRepository: _webdavRepository,
    );
  }
}
