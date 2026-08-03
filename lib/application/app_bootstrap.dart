import 'dart:async';

import 'package:flutter/foundation.dart';

import 'book/batch_book_progress_sync_port.dart';
import 'book/local_book_import_port.dart';
import 'book/book_provider_source_port.dart';
import 'book/book_record_controller.dart';
import 'book/book_progress_controller.dart';
import 'bookshelf/bookshelf_book_group_controller.dart';
import 'bookshelf/bookshelf_change_port.dart';
import 'bookshelf/bookshelf_chapter_meta_controller.dart';
import 'bookshelf/bookshelf_book_lifecycle_controller.dart';
import 'database/legacy_room_import_service.dart';
import 'startup/startup_task_runner.dart';
import '../domain/ports/chapter_content_cache_port.dart';
import '../domain/ports/content_processing_port.dart';
import '../domain/ports/webdav_repository.dart';
import '../domain/repositories/book_repository.dart';
import '../model/read_book.dart';
import '../providers/book_provider.dart';
import '../services/book_source_service.dart';
import '../services/backup_service.dart';
import '../services/bookmark_sync_service.dart';
import '../services/cache_service.dart';
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
    required this.startupTasks,
  });

  final BookProvider bookProvider;
  final BookSourceService bookSourceService;
  final ThemeModeController themeController;
  final LegacyRoomImportService legacyRoomImportService;
  final BackupService backupService;
  final BatchBookProgressSyncPort bookProgressSync;
  final BookmarkSyncService bookmarkSyncService;
  final CacheService cacheService;
  final WebDavRepository webdavRepository;
  final StartupTaskRunner startupTasks;
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
    required BookProviderSourcePort bookProviderSourcePort,
    required LocalBookImportPort localBookImportPort,
    required LegacyRoomImportService legacyRoomImportService,
    required BackupService backupService,
    required BatchBookProgressSyncPort bookProgressSync,
    required BookmarkSyncService bookmarkSyncService,
    required CacheService cacheService,
    required WebDavRepository webdavRepository,
    BookshelfChangePort? bookshelfChangePort,
    void Function(String stage)? reportStartupStage,
    void Function(StartupTaskReport report)? reportStartupTask,
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
       _bookProviderSourcePort = bookProviderSourcePort,
       _localBookImportPort = localBookImportPort,
       _legacyRoomImportService = legacyRoomImportService,
       _backupService = backupService,
       _bookProgressSync = bookProgressSync,
       _bookmarkSyncService = bookmarkSyncService,
       _cacheService = cacheService,
       _webdavRepository = webdavRepository,
       _bookshelfChangePort =
           bookshelfChangePort ?? const NoopBookshelfChangePort(),
       _reportStartupStage = reportStartupStage,
       _reportStartupTask = reportStartupTask;

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
  final BookProviderSourcePort _bookProviderSourcePort;
  final LocalBookImportPort _localBookImportPort;
  final LegacyRoomImportService _legacyRoomImportService;
  final BackupService _backupService;
  final BatchBookProgressSyncPort _bookProgressSync;
  final BookmarkSyncService _bookmarkSyncService;
  final CacheService _cacheService;
  final WebDavRepository _webdavRepository;
  final BookshelfChangePort _bookshelfChangePort;
  final void Function(String stage)? _reportStartupStage;
  final void Function(StartupTaskReport report)? _reportStartupTask;

  Future<AppBootstrapResult> initialize() async {
    _reportStartupStage?.call('平台、配置与引擎初始化');
    await _initializePlatform();
    _reportStartupStage?.call('阅读会话依赖组装');
    ReadBook.instance.configureDependencies(
      sourceService: _bookProviderSourcePort,
      repository: _bookRepository,
      contentProcessor: _contentProcessor,
      contentCache: _contentCache,
    );
    final bookProvider = BookProvider(
      repository: _bookRepository,
      sourceService: _bookProviderSourcePort,
      localBookPort: _localBookImportPort,
      bookRecordController: BookRecordController(repository: _bookRepository),
      bookProgressController: BookProgressController(
        repository: _bookRepository,
      ),
      bookshelfGroupController: BookshelfBookGroupController(
        repository: _bookRepository,
      ),
      bookshelfChapterMetaController: BookshelfChapterMetaController(
        repository: _bookRepository,
      ),
      bookshelfChangePort: _bookshelfChangePort,
      bookshelfBookLifecycleController: BookshelfBookLifecycleController(
        repository: _bookRepository,
        contentCache: _contentCache,
      ),
      contentCache: _contentCache,
    );
    _reportStartupStage?.call('主题配置加载');
    final themeController = ThemeModeController();
    await themeController.load();
    _reportStartupStage?.call('应用状态组装完成');
    final startupTasks = StartupTaskRunner(
      onReport: (report) {
        _reportStartupTask?.call(report);
        _reportStartupStage?.call('启动任务:${report.id}:${report.status.name}');
      },
    );
    final result = AppBootstrapResult(
      bookProvider: bookProvider,
      bookSourceService: _bookSourceService,
      themeController: themeController,
      legacyRoomImportService: _legacyRoomImportService,
      backupService: _backupService,
      bookProgressSync: _bookProgressSync,
      bookmarkSyncService: _bookmarkSyncService,
      cacheService: _cacheService,
      webdavRepository: _webdavRepository,
      startupTasks: startupTasks,
    );
    _startStartupTasks(startupTasks, bookProvider);
    return result;
  }

  void _startStartupTasks(StartupTaskRunner runner, BookProvider bookProvider) {
    final engineAvailable = _isEngineAvailable();
    if (engineAvailable) {
      unawaited(runner.run('network.restore', _restoreNetwork));
      unawaited(runner.run('web_api.restore', _restoreWebApi));
      unawaited(
        runner.run('webdav.initialize', () async {
          final webdav = await _loadWebDavConfig();
          if (!webdav.isReady) throw const StartupTaskSkipped();
          await WebDavSetupService.initialize(
            webdav,
            repository: _webdavRepository,
          );
        }),
      );
    } else {
      unawaited(runner.skip('network.restore'));
      unawaited(runner.skip('web_api.restore'));
      unawaited(runner.skip('webdav.initialize'));
    }

    final books = runner.run('bookshelf.load', () async {
      await bookProvider.loadBooks(runMaintenance: false);
      final error = bookProvider.loadError;
      if (error != null) throw StateError(error);
    });
    unawaited(
      runner.run('bookshelf.maintenance', () async {
        final report = await books;
        if (report.status != StartupTaskStatus.succeeded) {
          throw StateError('书架加载任务未完成');
        }
        await bookProvider.runStartupMaintenance();
      }),
    );

    if (engineAvailable && _isBookProgressSyncEnabled()) {
      unawaited(
        runner.run('book_progress.sync', () async {
          final report = await books;
          if (report.status != StartupTaskStatus.succeeded) {
            throw StateError('书架加载任务未完成');
          }
          await bookProvider.downloadAllBookProgress(sync: _bookProgressSync);
        }),
      );
    } else {
      unawaited(runner.skip('book_progress.sync'));
    }
  }
}
