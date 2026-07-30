import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../application/app_bootstrap.dart';
import '../application/crash/crash_log_service.dart';
import '../application/diagnostics/app_diagnostics_monitor.dart';
import '../application/diagnostics/app_log_port.dart';
import '../application/donate/donate_clipboard_port.dart';
import '../application/file_system/app_paths_port.dart';
import '../application/platform/clipboard_port.dart';
import '../application/preferences/code_edit_prefs_port.dart';
import '../application/preferences/click_action_prefs_port.dart';
import '../application/preferences/dict_rule_prefs_port.dart';
import '../application/lifecycle/app_lifecycle_coordinator.dart';
import '../application/preferences/shared_preferences_runtime.dart';
import '../application/preferences/bookshelf_display_prefs_port.dart';
import '../application/preferences/download_choice_prefs_port.dart';
import '../application/preferences/search_content_prefs_port.dart';
import '../application/preferences/source_variable_port.dart';
import '../application/preferences/txt_toc_rule_prefs_port.dart';
import '../application/reader/simulated_reading_prefs_port.dart';
import '../application/reader/read_style_prefs_port.dart';
import '../application/reader/read_style_zip_port.dart';
import '../application/reader/reader_image_cache_port.dart';
import '../application/reader/reader_font_port.dart';
import '../application/search/search_history_port.dart';
import '../application/sources/source_debug_formatter_port.dart';
import '../application/rss/public_text_rss_source_import_port.dart';
import '../application/rss/rss_read_state_port.dart';
import '../application/source_market/source_market_port.dart';
import '../application/startup/startup_task_runner.dart';
import '../application/web_api/repository_web_api_data_port.dart';
import '../application/web_api/web_api_prefs_port.dart';
import '../bridge/legado_db_bridge.dart';
import '../bridge/legado_engine_bridge.dart';
import '../config/app_config.dart';
import '../config/engine_config.dart';
import '../database/dao/book_dao.dart';
import '../database/dao/replace_rule_dao.dart';
import '../database/dao/source_dao.dart';
import '../domain/diagnostics/diagnostic_record.dart';
import '../domain/ports/backup_local_file_port.dart';
import '../domain/ports/application_binary_http_request_port.dart';
import '../domain/ports/application_http_request_port.dart';
import '../domain/ports/book_source_debug_port.dart';
import '../domain/ports/book_source_explore_port.dart';
import '../domain/ports/book_source_search_port.dart';
import '../domain/ports/book_source_validation_port.dart';
import '../domain/ports/dict_rule_query_port.dart';
import '../domain/ports/legacy_room_import_use_case.dart';
import '../domain/ports/public_text_fetch_port.dart';
import '../domain/ports/rss_source_import_port.dart';
import '../domain/ports/note_port.dart';
import '../domain/ports/reading_record_port.dart';
import '../domain/ports/webdav_repository.dart';
import '../infrastructure/cache/file_chapter_content_cache.dart';
import '../infrastructure/content/frb_content_processing_port.dart';
import '../infrastructure/database/frb_backup_port.dart';
import '../infrastructure/database/frb_database_status_port.dart';
import '../infrastructure/database/frb_legacy_room_import_port.dart';
import '../infrastructure/diagnostics/app_log_port_adapter.dart';
import '../infrastructure/engine/frb_book_source_book_info_port.dart';
import '../infrastructure/engine/frb_book_source_content_port.dart';
import '../infrastructure/engine/frb_book_source_debug_port.dart';
import '../infrastructure/engine/frb_book_source_explore_port.dart';
import '../infrastructure/engine/frb_book_source_search_port.dart';
import '../infrastructure/engine/frb_book_source_toc_port.dart';
import '../infrastructure/engine/frb_book_source_validation_port.dart';
import '../infrastructure/engine/frb_dict_rule_query_port.dart';
import '../infrastructure/engine/frb_bookmark_port.dart';
import '../infrastructure/engine/frb_bookplate_port.dart';
import '../infrastructure/engine/frb_engine_status_port.dart';
import '../infrastructure/engine/frb_js_eval_port.dart';
import '../infrastructure/engine/frb_local_book_parser_port.dart';
import '../infrastructure/engine/frb_remote_archive_parser_port.dart';
import '../infrastructure/engine/frb_network_engine_port.dart';
import '../infrastructure/engine/frb_note_port.dart';
import '../infrastructure/engine/frb_reading_record_port.dart';
import '../infrastructure/engine/frb_rss_port.dart';
import '../infrastructure/engine/frb_rss_sort_url_js_port.dart';
import '../infrastructure/engine/frb_source_login_cookie_port.dart';
import '../infrastructure/engine/frb_source_verification_browser_host.dart';
import '../infrastructure/file_system/backup_local_file_adapter.dart';
import '../infrastructure/network/frb_public_text_fetch_port.dart';
import '../infrastructure/network/frb_application_binary_http_request_port.dart';
import '../infrastructure/network/frb_application_http_request_port.dart';
import '../infrastructure/platform/flutter_frame_diagnostics_observer.dart';
import '../infrastructure/platform/flutter_lifecycle_observer.dart';
import '../infrastructure/platform/method_channel_source_login_web_cookie_port.dart';
import '../infrastructure/platform/platform_crash_metadata_loader.dart';
import '../infrastructure/platform/platform_donate_clipboard.dart';
import '../infrastructure/platform/platform_clipboard.dart';
import '../infrastructure/file_system/app_paths_port_adapter.dart';
import '../infrastructure/reader/read_style_zip_port_adapter.dart';
import '../infrastructure/source_market/builtin_source_market_port.dart';
import '../infrastructure/preferences/shared_preferences_code_edit_prefs.dart';
import '../infrastructure/preferences/shared_preferences_click_action_prefs_adapter.dart';
import '../infrastructure/preferences/shared_preferences_book_group_prefs.dart';
import '../infrastructure/preferences/shared_preferences_bookshelf_display_prefs.dart';
import '../infrastructure/preferences/shared_preferences_book_progress_sync_store.dart';
import '../infrastructure/preferences/shared_preferences_code_edit_prefs_store.dart';
import '../infrastructure/preferences/shared_preferences_dict_rule_prefs_adapter.dart';
import '../infrastructure/preferences/shared_preferences_download_choice_prefs.dart';
import '../infrastructure/preferences/shared_preferences_search_content_prefs_adapter.dart';
import '../infrastructure/preferences/shared_preferences_source_variable_adapter.dart';
import '../infrastructure/preferences/shared_preferences_txt_toc_rule_prefs_adapter.dart';
import '../infrastructure/preferences/shared_preferences_simulated_reading_prefs.dart';
import '../infrastructure/preferences/shared_preferences_read_style_prefs_adapter.dart';
import '../infrastructure/preferences/shared_preferences_web_api_prefs_adapter.dart';
import '../infrastructure/reader/reader_font_port_adapter.dart';
import '../infrastructure/reader/reader_image_cache_port_adapter.dart';
import '../infrastructure/sources/source_debug_formatter_adapter.dart';
import '../infrastructure/preferences/shared_preferences_search_history_adapter.dart';
import '../infrastructure/preferences/shared_preferences_rss_read_state_adapter.dart';
import '../infrastructure/web_api/dart_io_web_api_port.dart';
import '../infrastructure/webdav/frb_webdav_repository.dart';
import '../providers/replace_provider.dart';
import '../providers/rss_provider.dart';
import '../providers/source_provider.dart';
import '../features/common/navigator_source_verification_browser_port.dart';
import '../services/app_log.dart';
import '../services/backup_service.dart';
import '../services/book_group_store.dart';
import '../services/book_progress_sync.dart';
import '../services/book_source_service.dart';
import '../services/bookmark_service.dart';
import '../services/bookmark_sync_service.dart';
import '../services/bookplate_service.dart';
import '../services/cache_service.dart';
import '../services/code_edit_prefs.dart';
import '../services/database_status_service.dart';
import '../services/diagnostics_prefs.dart';
import '../services/engine_status_service.dart';
import '../services/legacy_room_import_service_factory.dart';
import '../services/local_book_service.dart';
import '../services/network_prefs.dart';
import '../services/note_service.dart';
import '../services/reading_record_service.dart';
import '../services/remote_archive_import_service.dart';
import '../services/rss_service.dart';
import '../services/rss_sort_urls.dart';
import '../services/source_login_service.dart';
import '../services/source_login_cookie_service.dart';
import '../services/tts_service.dart';
import '../services/web_api_service.dart';
import '../services/webdav_prefs.dart';

abstract final class AppCompositionRoot {
  static Future<void> run({required CrashLogService crashLog}) async {
    final composition = await _compose(crashLog);
    crashLog.updateStartupStage('首屏挂载');
    runApp(composition.app);
    crashLog.updateStartupStage('首屏运行');
    unawaited(AppLog.i('首屏运行', category: 'startup'));
  }

  static Future<({Widget app})> _compose(CrashLogService crashLog) async {
    void reportStartupStage(String stage) {
      crashLog.updateStartupStage(stage);
      unawaited(AppLog.i(stage, category: 'startup'));
    }

    reportStartupStage('SharedPreferences 初始化');
    await SharedPreferencesRuntime.getOrNull();
    reportStartupStage('读取上次崩溃记录');
    final pendingCrashReport = await crashLog.pendingReport();
    reportStartupStage('基础设施组装');
    final navigatorKey = GlobalKey<NavigatorState>();
    final lifecycleCoordinator = AppLifecycleCoordinator();
    final diagnosticsMonitor = AppDiagnosticsMonitor(
      config: AppDiagnosticsConfig(
        enabled: await DiagnosticsPrefs.isMonitoringEnabled(),
      ),
      sink: (event) => AppLog.put(event.toLogLine(), level: event.level),
    );
    const contentCache = FileChapterContentCache();
    const networkEnginePort = FrbNetworkEnginePort();
    const sourceLoginCookiePort = FrbSourceLoginCookiePort();
    const webdavRepository = FrbWebDavRepository();
    const publicTextPort = FrbPublicTextFetchPort();
    const binaryHttpPort = FrbApplicationBinaryHttpRequestPort();
    final bookRepository = BookDao();
    final sourceRepository = SourceDao();
    final readingRecordPort = FrbReadingRecordPort();
    final webApiPort = DartIoWebApiPort(
      dataPort: RepositoryWebApiDataPort(
        bookRepository: bookRepository,
        sourceRepository: sourceRepository,
        readingRecordPort: readingRecordPort,
        isDatabaseReady: () => LegadoDbBridge.isReady,
      ),
    );
    final progressStore = await SharedPreferencesBookProgressSyncStore.load();
    final bookshelfDisplayPrefs =
        await SharedPreferencesBookshelfDisplayPrefs.create();
    final rssReadStatePort = await SharedPreferencesRssReadStateAdapter.load();
    final downloadChoicePrefs =
        await SharedPreferencesDownloadChoicePrefs.loadFromRuntime();
    final searchContentPrefs =
        await SharedPreferencesSearchContentPrefsAdapter.create();
    final sourceVariablePort =
        await SharedPreferencesSourceVariableAdapter.create();
    final codeEditPrefs =
        await SharedPreferencesCodeEditPrefs.loadFromRuntime();

    await _configureStaticServices(
      networkEnginePort,
      sourceLoginCookiePort,
      readingRecordPort,
    );
    WebApiService.configureWebApiPort(webApiPort);
    TtsService.configureBinaryHttpPort(binaryHttpPort);

    final bookSourceSearchPort = FrbBookSourceSearchPort();
    final bookSourceExplorePort = FrbBookSourceExplorePort();
    final bookSourceService = BookSourceService(
      searchPort: bookSourceSearchPort,
      bookInfoPort: FrbBookSourceBookInfoPort(),
      contentPort: FrbBookSourceContentPort(),
      explorePort: bookSourceExplorePort,
      tocPort: FrbBookSourceTocPort(),
      publicTextPort: publicTextPort,
    );
    final backupService = BackupService(
      webdav: webdavRepository,
      backup: FrbBackupPort(),
    );
    final bookProgressSync = BookProgressSync(
      webdav: webdavRepository,
      store: progressStore,
    );
    final bookmarkSyncService = BookmarkSyncService(webdav: webdavRepository);
    final cacheService = CacheService(
      contentCache: contentCache,
      enginePort: networkEnginePort,
    );

    final contentProcessor = FrbContentProcessingPort();
    final remoteArchiveImportService = RemoteArchiveImportService(
      parser: const FrbRemoteArchiveParserPort(),
    );
    final bootstrap = await AppBootstrap(
      initializePlatform: () async {
        reportStartupStage('应用配置加载');
        await EngineConfig.load();
        await AppConfig.instance.load();
        reportStartupStage('Rust 引擎初始化');
        await LegadoEngineBridge.tryInit();
        if (LegadoEngineBridge.isAvailable) {
          reportStartupStage('Rust 数据库初始化');
          await LegadoDbBridge.init();
        }
      },
      isEngineAvailable: () => LegadoEngineBridge.isAvailable,
      isBookProgressSyncEnabled: () => AppConfig.instance.syncBookProgress,
      restoreNetwork: NetworkPrefs.restoreToEngine,
      restoreWebApi: WebApiService.restoreIfEnabled,
      loadWebDavConfig: WebDavPrefs.load,
      bookRepository: bookRepository,
      contentCache: contentCache,
      contentProcessor: contentProcessor,
      bookSourceService: bookSourceService,
      localBookService: LocalBookService(
        repository: bookRepository,
        parser: const FrbLocalBookParserPort(),
      ),
      legacyRoomImportService: LegacyRoomImportServices.create(
        FrbLegacyRoomImportPort(),
      ),
      backupService: backupService,
      bookProgressSync: bookProgressSync,
      bookmarkSyncService: bookmarkSyncService,
      cacheService: cacheService,
      webdavRepository: webdavRepository,
      reportStartupStage: reportStartupStage,
      reportStartupTask: (report) {
        final suffix = report.error == null ? '' : ': ${report.error}';
        reportStartupStage('启动任务 ${report.id} ${report.status.name}$suffix');
        unawaited(diagnosticsMonitor.recordStartupTask(report));
      },
    ).initialize();

    final runtime = await const PlatformCrashMetadataLoader().call();
    AppLog.configureRuntime(
      DiagnosticRuntimeInfo(
        platform: runtime.platform,
        platformVersion: runtime.platformVersion,
        appVersion: runtime.appVersion,
        engineVersion: runtime.engineVersion,
      ),
    );

    if (LegadoEngineBridge.isAvailable) {
      FrbSourceVerificationBrowserHost(
        browserPort: NavigatorSourceVerificationBrowserPort(
          navigatorKey: navigatorKey,
          captureCookie: ({required sourceKey, required cookie}) =>
              SourceLoginCookieService.capture(
                sourceUrl: sourceKey,
                cookie: cookie,
              ),
        ),
      ).start();
    }

    return (
      app: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: bootstrap.themeController),
          ChangeNotifierProvider.value(value: lifecycleCoordinator),
          ChangeNotifierProvider.value(value: AppConfig.instance),
          ChangeNotifierProvider.value(value: bootstrap.bookProvider),
          Provider<AppDiagnosticsMonitor>.value(value: diagnosticsMonitor),
          Provider<AppLogPort>(create: (_) => const AppLogPortAdapter()),
          Provider<DonateClipboardPort>.value(
            value: const PlatformDonateClipboard(),
          ),
          Provider<AppPathsPort>.value(value: const AppPathsPortAdapter()),
          Provider<ClipboardPort>.value(value: const PlatformClipboard()),
          Provider<CodeEditPrefsPort>.value(value: codeEditPrefs),
          Provider<ClickActionPrefsPort>.value(
            value: const SharedPreferencesClickActionPrefsAdapter(),
          ),
          Provider<DictRulePrefsPort>.value(
            value: const SharedPreferencesDictRulePrefsAdapter(),
          ),
          Provider<BookshelfDisplayPrefsPort>.value(
            value: bookshelfDisplayPrefs,
          ),
          Provider<RssReadStatePort>.value(value: rssReadStatePort),
          Provider<DownloadChoicePrefsPort>.value(value: downloadChoicePrefs),
          Provider<SearchContentPrefsPort>.value(value: searchContentPrefs),
          Provider<SourceVariablePort>.value(value: sourceVariablePort),
          Provider<TxtTocRulePrefsPort>.value(
            value: const SharedPreferencesTxtTocRulePrefsAdapter(),
          ),
          Provider<SimulatedReadingPrefsPort>.value(
            value: const SharedPreferencesSimulatedReadingPrefs(),
          ),
          Provider<ReadStylePrefsPort>.value(
            value: const SharedPreferencesReadStylePrefsAdapter(),
          ),
          Provider<ReaderFontPort>.value(value: const ReaderFontPortAdapter()),
          Provider<ReadStyleZipPort>.value(
            value: ReadStyleZipPortAdapter(binaryHttpPort),
          ),
          Provider<ReaderImageCachePort>.value(
            value: ReaderImageCachePortAdapter(binaryHttpPort),
          ),
          Provider<WebApiPrefsPort>.value(
            value: const SharedPreferencesWebApiPrefsAdapter(),
          ),
          Provider<SourceDebugFormatterPort>.value(
            value: const SourceDebugFormatterAdapter(),
          ),
          Provider<SourceMarketPort>.value(
            value: const BuiltinSourceMarketPort(),
          ),
          Provider<NotePort>.value(value: FrbNotePort()),
          Provider<ReadingRecordPort>.value(value: readingRecordPort),
          Provider<BookSourceSearchPort>.value(value: bookSourceSearchPort),
          Provider<BookSourceExplorePort>.value(value: bookSourceExplorePort),
          Provider<SearchHistoryPort>.value(
            value: const SharedPreferencesSearchHistoryAdapter(),
          ),
          Provider<BookSourceService>.value(value: bookSourceService),
          Provider<PublicTextFetchPort>.value(value: publicTextPort),
          Provider<ApplicationHttpRequestPort>(
            create: (_) => const FrbApplicationHttpRequestPort(),
          ),
          Provider<ApplicationBinaryHttpRequestPort>(
            create: (_) => binaryHttpPort,
          ),
          Provider<BookSourceDebugPort>(
            create: (_) => FrbBookSourceDebugPort(),
          ),
          Provider<BookSourceValidationPort>(
            create: (_) => FrbBookSourceValidationPort(),
          ),
          Provider<DictRuleQueryPort>(
            create: (_) => const FrbDictRuleQueryPort(),
          ),
          Provider<WebDavRepository>.value(value: webdavRepository),
          Provider<BackupService>.value(value: backupService),
          Provider<BookProgressSync>.value(value: bookProgressSync),
          Provider<BookmarkSyncService>.value(value: bookmarkSyncService),
          Provider<CacheService>.value(value: cacheService),
          Provider<StartupTaskRunner>.value(value: bootstrap.startupTasks),
          Provider<FlutterLifecycleObserver>(
            lazy: false,
            create: (_) =>
                FlutterLifecycleObserver(lifecycleCoordinator)..start(),
            dispose: (_, observer) => observer.stop(),
          ),
          Provider<FlutterFrameDiagnosticsObserver>(
            lazy: false,
            create: (_) =>
                FlutterFrameDiagnosticsObserver(diagnosticsMonitor)..start(),
            dispose: (_, observer) => observer.stop(),
          ),
          Provider<RemoteArchiveImportService>.value(
            value: remoteArchiveImportService,
          ),
          Provider<BackupLocalFilePort>(
            create: (_) => FileSystemBackupLocalFileAdapter(backupService),
          ),
          Provider<LegacyRoomImportUseCase>.value(
            value: bootstrap.legacyRoomImportService,
          ),
          Provider<RssSourceImportPort>(
            create: (_) => PublicTextRssSourceImportPort(publicTextPort),
          ),
          ChangeNotifierProvider(
            create: (context) => SourceProvider(
              repository: sourceRepository,
              validationPort: context.read<BookSourceValidationPort>(),
              sourceService: bookSourceService,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => ReplaceProvider(
              repository: ReplaceRuleDao(),
              contentProcessor: contentProcessor,
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => RssProvider(
              sourceImportPort: context.read<RssSourceImportPort>(),
            ),
          ),
        ],
        child: LegadoApp(
          navigatorKey: navigatorKey,
          pendingCrashReport: pendingCrashReport,
          onCrashReportPresented: () async {
            await crashLog.acknowledgePending();
          },
        ),
      ),
    );
  }

  static Future<void> _configureStaticServices(
    FrbNetworkEnginePort networkEnginePort,
    FrbSourceLoginCookiePort sourceLoginCookiePort,
    FrbReadingRecordPort readingRecordPort,
  ) async {
    const appLogPort = AppLogPortAdapter();
    BookmarkService.configureBookmarkPort(FrbBookmarkPort());
    BookmarkService.configureAppLogPort(appLogPort);
    BookplateService.configureBookplatePort(FrbBookplatePort());
    DatabaseStatusService.configurePort(const FrbDatabaseStatusPort());
    EngineStatusService.configurePort(const FrbEngineStatusPort());
    NetworkPrefs.configureEnginePort(networkEnginePort);
    NoteService.configureNotePort(FrbNotePort());
    NoteService.configureAppLogPort(appLogPort);
    ReadingRecordService.configureRecordPort(readingRecordPort);
    RssService.configureRssPort(FrbRssPort());
    RssSortUrls.configureJsPort(FrbRssSortUrlJsPort());
    SourceLoginService.configureJsPort(const FrbJsEvalPort());
    SourceLoginCookieService.configurePort(sourceLoginCookiePort);
    SourceLoginCookieService.configureWebCookiePort(
      const MethodChannelSourceLoginWebCookiePort(),
    );
    BookGroupStore.configurePrefsPort(
      await SharedPreferencesBookGroupPrefs.load(),
    );
    CodeEditPrefs.configureStore(
      await SharedPreferencesCodeEditPrefsStore.load(),
    );
  }
}
