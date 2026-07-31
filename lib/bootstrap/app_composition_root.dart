import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../application/app_bootstrap.dart';
import '../application/ai/ai_config_http_port.dart';
import '../application/ai/ai_config_prefs_port.dart';
import '../application/book/batch_book_progress_sync_port.dart';
import '../application/book/local_book_import_port.dart';
import '../application/annotation/bookmark_editor_port.dart';
import '../application/annotation/bookplate_overlay_port.dart';
import '../application/annotation/note_editor_port.dart';
import '../application/bookmark/bookmark_page_port.dart';
import '../application/bookshelf/book_group_management_port.dart';
import '../application/bookshelf/book_group_store_port.dart';
import '../application/bookshelf/bookshelf_arrange_port.dart';
import '../application/bookshelf/bookshelf_config_dialog_port.dart';
import '../application/bookshelf/bookshelf_display_port.dart';
import '../application/bookshelf/bookshelf_list_port.dart';
import '../application/bookshelf/bookshelf_local_book_port.dart';
import '../application/mine/my_page_port.dart';
import '../application/mine/webdav_config_dialog_port.dart';
import '../application/main/main_shell_startup_port.dart';
import '../application/obsidian/obsidian_export_port.dart';
import '../application/bookshelf/remote_archive_import_port.dart';
import '../application/bookshelf/remote_book_sort_port.dart';
import '../application/cache/book_cache_export_port.dart';
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
import '../application/preferences/bookshelf_config_prefs_port.dart';
import '../application/preferences/download_choice_prefs_port.dart';
import '../application/preferences/search_content_prefs_port.dart';
import '../application/preferences/source_variable_port.dart';
import '../application/preferences/txt_toc_rule_prefs_port.dart';
import '../application/source_rules/check_source_prefs_port.dart';
import '../application/source_rules/dict_lookup_port.dart';
import '../application/source_rules/replace_preview_port.dart';
import '../application/reader/simulated_reading_prefs_port.dart';
import '../application/reader/read_style_prefs_port.dart';
import '../application/reader/read_book_config_prefs_port.dart';
import '../application/reader/reader_session_prefs_port.dart';
import '../application/reader/reader_selection_port.dart';
import '../application/reader/reader_content_refetch_port.dart';
import '../application/reader/reader_bookmark_readiness_port.dart';
import '../application/reader/reader_progress_sync_port.dart';
import '../application/reader/read_style_zip_port.dart';
import '../application/reader/reader_image_cache_port.dart';
import '../application/reader/reader_font_port.dart';
import '../application/reader/book_reader_prefs_port.dart';
import '../application/reader/tts_port.dart';
import '../application/reader/manga_prefs_port.dart';
import '../application/replace/replace_preset_port.dart';
import '../application/qr/qr_code_port.dart';
import '../application/search/search_history_port.dart';
import '../application/source_login/source_login_cookie_clear_port.dart';
import '../application/source_login/source_login_page_port.dart';
import '../application/main/privacy_consent_port.dart';
import '../application/sources/source_debug_formatter_port.dart';
import '../application/rss/public_text_rss_source_import_port.dart';
import '../application/rss/rss_read_state_port.dart';
import '../application/rss/rss_sort_urls_port.dart';
import '../application/rss/rss_login_port.dart';
import '../application/rss/rss_source_edit_port.dart';
import '../application/rss/rss_source_transfer_port.dart';
import '../application/rss/rss_source_store_port.dart';
import '../application/source_subscription/rule_sub_prefs_port.dart';
import '../application/source_subscription/rule_sub_import_port.dart';
import '../application/source_validation/source_validation_store_port.dart';
import '../application/rss/rss_star_prefs_port.dart';
import '../application/source_market/source_market_port.dart';
import '../application/source_management/source_group_catalog_port.dart';
import '../application/source_management/source_management_book_source_port.dart';
import '../application/source_management/source_management_prefs_port.dart';
import '../application/startup/startup_task_runner.dart';
import '../application/theme/theme_import_port.dart';
import '../application/web_api/repository_web_api_data_port.dart';
import '../application/web_api/web_api_prefs_port.dart';
import '../application/settings/web_api_settings_port.dart';
import '../application/settings/other_settings_port.dart';
import '../application/settings/backup_config_status_port.dart';
import '../application/settings/backup_config_operations_port.dart';
import '../application/settings/cache_management_port.dart';
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
import '../domain/ports/rss_port.dart';
import '../domain/ports/webdav_repository.dart';
import '../infrastructure/cache/file_chapter_content_cache.dart';
import '../infrastructure/ai/ai_config_http_port_adapter.dart';
import '../infrastructure/ai/shared_preferences_ai_config_prefs_adapter.dart';
import '../infrastructure/annotation/bookmark_editor_port_adapter.dart';
import '../infrastructure/annotation/bookplate_overlay_port_adapter.dart';
import '../infrastructure/annotation/note_editor_port_adapter.dart';
import '../infrastructure/bookmark/bookmark_page_port_adapter.dart';
import '../infrastructure/book/batch_book_progress_sync_port_adapter.dart';
import '../infrastructure/book/book_provider_source_port_adapter.dart';
import '../infrastructure/book/local_book_import_port_adapter.dart';
import '../infrastructure/bookshelf/book_group_management_port_adapter.dart';
import '../infrastructure/bookshelf/book_group_store_port_adapter.dart';
import '../infrastructure/bookshelf/bookshelf_arrange_port_adapter.dart';
import '../infrastructure/bookshelf/bookshelf_config_dialog_port_adapter.dart';
import '../infrastructure/bookshelf/bookshelf_display_port_adapter.dart';
import '../infrastructure/bookshelf/bookshelf_list_port_adapter.dart';
import '../infrastructure/bookshelf/bookshelf_local_book_port_adapter.dart';
import '../infrastructure/bookshelf/remote_archive_import_port_adapter.dart';
import '../infrastructure/bookshelf/remote_book_sort_port_adapter.dart';
import '../infrastructure/bookshelf/shared_preferences_webdav_prefs_port_adapter.dart';
import '../infrastructure/cache/book_cache_export_port_adapter.dart';
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
import '../infrastructure/main/main_shell_startup_port_adapter.dart';
import '../infrastructure/mine/my_page_port_adapter.dart';
import '../infrastructure/mine/webdav_config_dialog_port_adapter.dart';
import '../infrastructure/obsidian/obsidian_export_port_adapter.dart';
import '../infrastructure/file_system/app_paths_port_adapter.dart';
import '../infrastructure/reader/read_style_zip_port_adapter.dart';
import '../infrastructure/source_market/builtin_source_market_port.dart';
import '../infrastructure/source_management/source_group_catalog_port_adapter.dart';
import '../infrastructure/source_management/source_management_book_source_port_adapter.dart';
import '../infrastructure/source_management/source_management_prefs_port_adapter.dart';
import '../infrastructure/preferences/shared_preferences_code_edit_prefs.dart';
import '../infrastructure/preferences/shared_preferences_click_action_prefs_adapter.dart';
import '../infrastructure/preferences/shared_preferences_book_group_prefs.dart';
import '../infrastructure/preferences/shared_preferences_bookshelf_display_prefs.dart';
import '../infrastructure/preferences/shared_preferences_bookshelf_config_prefs_adapter.dart';
import '../infrastructure/preferences/shared_preferences_book_progress_sync_store.dart';
import '../infrastructure/preferences/shared_preferences_code_edit_prefs_store.dart';
import '../infrastructure/preferences/shared_preferences_dict_rule_prefs_adapter.dart';
import '../infrastructure/preferences/shared_preferences_download_choice_prefs.dart';
import '../infrastructure/preferences/shared_preferences_search_content_prefs_adapter.dart';
import '../infrastructure/preferences/shared_preferences_source_variable_adapter.dart';
import '../infrastructure/preferences/shared_preferences_txt_toc_rule_prefs_adapter.dart';
import '../infrastructure/preferences/shared_preferences_simulated_reading_prefs.dart';
import '../infrastructure/preferences/shared_preferences_read_style_prefs_adapter.dart';
import '../infrastructure/reader/read_book_config_prefs_port_adapter.dart';
import '../infrastructure/reader/reader_session_prefs_port_adapter.dart';
import '../infrastructure/reader/reader_selection_port_adapter.dart';
import '../infrastructure/reader/reader_content_refetch_port_adapter.dart';
import '../infrastructure/reader/reader_bookmark_readiness_port_adapter.dart';
import '../infrastructure/reader/reader_progress_sync_port_adapter.dart';
import '../infrastructure/preferences/shared_preferences_web_api_prefs_adapter.dart';
import '../infrastructure/reader/reader_font_port_adapter.dart';
import '../infrastructure/reader/book_reader_prefs_port_adapter.dart';
import '../infrastructure/reader/tts_port_adapter.dart';
import '../infrastructure/reader/manga_prefs_port_adapter.dart';
import '../infrastructure/reader/reader_image_cache_port_adapter.dart';
import '../infrastructure/replace/replace_preset_port_adapter.dart';
import '../infrastructure/sources/source_debug_formatter_adapter.dart';
import '../infrastructure/source_login/source_login_cookie_clear_port_adapter.dart';
import '../infrastructure/main/privacy_consent_port_adapter.dart';
import '../infrastructure/source_login/source_login_page_port_adapter.dart';
import '../infrastructure/source_rules/check_source_prefs_port_adapter.dart';
import '../infrastructure/source_rules/dict_lookup_port_adapter.dart';
import '../infrastructure/source_rules/replace_preview_port_adapter.dart';
import '../infrastructure/preferences/shared_preferences_search_history_adapter.dart';
import '../infrastructure/preferences/shared_preferences_rss_read_state_adapter.dart';
import '../infrastructure/qr/qr_code_port_adapter.dart';
import '../infrastructure/rss/rss_star_prefs_port_adapter.dart';
import '../infrastructure/rss/rss_sort_urls_port_adapter.dart';
import '../infrastructure/rss/rss_login_port_adapter.dart';
import '../infrastructure/rss/rss_provider_source_edit_adapter.dart';
import '../infrastructure/rss/rss_source_transfer_port_adapter.dart';
import '../infrastructure/rss/shared_preferences_rss_source_store_adapter.dart';
import '../infrastructure/source_subscription/shared_preferences_rule_sub_prefs_adapter.dart';
import '../infrastructure/source_subscription/rule_sub_import_port_adapter.dart';
import '../infrastructure/source_validation/source_validation_store_port_adapter.dart';
import '../infrastructure/theme/theme_import_port_adapter.dart';
import '../infrastructure/web_api/dart_io_web_api_port.dart';
import '../infrastructure/settings/web_api_settings_port_adapter.dart';
import '../infrastructure/settings/other_settings_port_adapter.dart';
import '../infrastructure/settings/backup_config_status_port_adapter.dart';
import '../infrastructure/settings/backup_config_operations_port_adapter.dart';
import '../infrastructure/settings/cache_management_port_adapter.dart';
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
    final privacyConsentPort =
        await SharedPreferencesPrivacyConsentPortAdapter.create();
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
    final rssPort = FrbRssPort();
    final aiConfigHttpPort = AiConfigHttpPortAdapter(
      const FrbApplicationHttpRequestPort(),
    );
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
      rssPort,
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
    final batchBookProgressSync = BatchBookProgressSyncPortAdapter(
      progressSync: bookProgressSync,
    );
    final localBookImportPort = LocalBookImportPortAdapter(
      LocalBookService(
        repository: bookRepository,
        parser: const FrbLocalBookParserPort(),
      ),
    );
    final bookProviderSourcePort = BookProviderSourcePortAdapter(
      sourceService: bookSourceService,
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
      bookProviderSourcePort: bookProviderSourcePort,
      localBookImportPort: localBookImportPort,
      legacyRoomImportService: LegacyRoomImportServices.create(
        FrbLegacyRoomImportPort(),
      ),
      backupService: backupService,
      bookProgressSync: batchBookProgressSync,
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
          Provider<BookshelfLocalBookPort>.value(
            value: BookshelfLocalBookPortAdapter(
              () => bootstrap.bookProvider.importLocalBook(),
            ),
          ),
          Provider<AppDiagnosticsMonitor>.value(value: diagnosticsMonitor),
          Provider<AppLogPort>(create: (_) => const AppLogPortAdapter()),
          Provider<AiConfigPrefsPort>.value(
            value: const SharedPreferencesAiConfigPrefsAdapter(),
          ),
          Provider<PrivacyConsentPort>.value(value: privacyConsentPort),
          Provider<AiConfigHttpPort>.value(value: aiConfigHttpPort),
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
          Provider<CheckSourcePrefsPort>.value(
            value: const CheckSourcePrefsPortAdapter(),
          ),
          Provider<BookshelfDisplayPrefsPort>.value(
            value: bookshelfDisplayPrefs,
          ),
          Provider<BookshelfConfigPrefsPort>.value(
            value: const SharedPreferencesBookshelfConfigPrefsAdapter(),
          ),
          Provider<BookshelfConfigDialogPort>.value(
            value: const SharedPreferencesBookshelfConfigDialogPortAdapter(),
          ),
          Provider<BookshelfDisplayPort>.value(
            value: const SharedPreferencesBookshelfDisplayPortAdapter(),
          ),
          Provider<BookshelfListPort>.value(
            value: const BookshelfListPortAdapter(),
          ),
          Provider<RemoteBookSortPort>.value(
            value: const RemoteBookSortPortAdapter(),
          ),
          Provider<WebDavPrefsPort>.value(
            value: const SharedPreferencesWebDavPrefsPortAdapter(),
          ),
          Provider<RssReadStatePort>.value(value: rssReadStatePort),
          Provider<RssStarPrefsPort>.value(
            value: const RssStarPrefsPortAdapter(),
          ),
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
          Provider<ReadBookConfigPrefsPort>.value(
            value: const ReadBookConfigPrefsPortAdapter(),
          ),
          Provider<ReaderSessionPrefsPort>.value(
            value: const ReaderSessionPrefsPortAdapter(),
          ),
          Provider<ReaderSelectionPort>.value(
            value: const ReaderSelectionPortAdapter(),
          ),
          Provider<ReaderBookmarkReadinessPort>.value(
            value: const ReaderBookmarkReadinessPortAdapter(),
          ),
          Provider<ReaderFontPort>.value(value: const ReaderFontPortAdapter()),
          Provider<BookReaderPrefsPort>.value(
            value: const BookReaderPrefsPortAdapter(),
          ),
          Provider<TtsPort>.value(value: TtsPortAdapter(TtsService.instance)),
          Provider<BookCacheExportPort>.value(
            value: BookCacheExportPortAdapter(contentCache),
          ),
          Provider<ReadStyleZipPort>.value(
            value: ReadStyleZipPortAdapter(binaryHttpPort),
          ),
          Provider<ReaderImageCachePort>.value(
            value: ReaderImageCachePortAdapter(binaryHttpPort),
          ),
          Provider<WebApiPrefsPort>.value(
            value: const SharedPreferencesWebApiPrefsAdapter(),
          ),
          Provider<WebApiSettingsPort>.value(
            value: WebApiSettingsPortAdapter(),
          ),
          Provider<OtherSettingsPort>.value(
            value: const OtherSettingsPortAdapter(),
          ),
          Provider<BackupConfigStatusPort>.value(
            value: const BackupConfigStatusPortAdapter(),
          ),
          Provider<BackupConfigOperationsPort>.value(
            value: BackupConfigOperationsPortAdapter(backupService),
          ),
          Provider<CacheManagementPort>.value(
            value: CacheManagementPortAdapter(cacheService),
          ),
          Provider<SourceDebugFormatterPort>.value(
            value: const SourceDebugFormatterAdapter(),
          ),
          Provider<SourceLoginCookieClearPort>.value(
            value: const SourceLoginCookieClearPortAdapter(),
          ),
          Provider<SourceLoginPagePort>.value(
            value: const SourceLoginPagePortAdapter(),
          ),
          Provider<SourceMarketPort>.value(
            value: const BuiltinSourceMarketPort(),
          ),
          Provider<SourceManagementPrefsPort>.value(
            value: const SourceManagementPrefsPortAdapter(),
          ),
          Provider<SourceGroupCatalogPort>.value(
            value: const SourceGroupCatalogPortAdapter(),
          ),
          Provider<SourceManagementBookSourcePort>.value(
            value: SourceManagementBookSourcePortAdapter(
              sourceService: bookSourceService,
            ),
          ),
          Provider<SourceValidationStorePort>.value(
            value: const SourceValidationStorePortAdapter(),
          ),
          Provider<NotePort>.value(value: FrbNotePort()),
          Provider<BookmarkEditorPort>.value(
            value: const BookmarkEditorPortAdapter(),
          ),
          Provider<BookplateOverlayPort>.value(
            value: const BookplateOverlayPortAdapter(),
          ),
          Provider<NoteEditorPort>.value(value: const NoteEditorPortAdapter()),
          Provider<BookmarkPagePort>.value(
            value: BookmarkPagePortAdapter(syncService: bookmarkSyncService),
          ),
          Provider<BookshelfArrangePort>.value(
            value: const SharedPreferencesBookshelfArrangePortAdapter(),
          ),
          Provider<BookGroupStorePort>.value(
            value: const BookGroupStorePortAdapter(),
          ),
          Provider<BookGroupManagementPort>.value(
            value: const BookGroupManagementPortAdapter(),
          ),
          Provider<MangaPrefsPort>.value(value: const MangaPrefsPortAdapter()),
          Provider<ReadingRecordPort>.value(value: readingRecordPort),
          Provider<RssPort>.value(value: rssPort),
          Provider<RssSortUrlsPort>.value(
            value: const RssSortUrlsPortAdapter(),
          ),
          Provider<RssLoginPort>.value(value: const RssLoginPortAdapter()),
          Provider<RssSourceTransferPort>.value(
            value: const RssSourceTransferPortAdapter(),
          ),
          Provider<RuleSubPrefsPort>.value(
            value: const SharedPreferencesRuleSubPrefsAdapter(),
          ),
          Provider<QrCodePort>.value(value: const QrCodePortAdapter()),
          Provider<ThemeImportPort>.value(
            value: ThemeImportPortAdapter(publicTextPort),
          ),
          Provider<ReplacePresetPort>.value(
            value: const ReplacePresetPortAdapter(),
          ),
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
          Provider<ObsidianExportPort>(
            create: (context) => ObsidianExportPortAdapter(
              notePort: context.read<NotePort>(),
              httpPort: context.read<ApplicationHttpRequestPort>(),
            ),
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
          Provider<DictLookupPort>(
            create: (context) => DictLookupPortAdapter(
              prefs: context.read<DictRulePrefsPort>(),
              queryPort: context.read<DictRuleQueryPort>(),
            ),
          ),
          Provider<ReplacePreviewPort>.value(
            value: const ReplacePreviewPortAdapter(),
          ),
          Provider<WebDavRepository>.value(value: webdavRepository),
          Provider<WebDavConfigDialogPort>.value(
            value: WebDavConfigDialogPortAdapter(repository: webdavRepository),
          ),
          Provider<BackupService>.value(value: backupService),
          Provider<MyPagePort>.value(
            value: MyPagePortAdapter(backupService: backupService),
          ),
          Provider<BookProgressSync>.value(value: bookProgressSync),
          Provider<BatchBookProgressSyncPort>.value(
            value: batchBookProgressSync,
          ),
          Provider<LocalBookImportPort>.value(value: localBookImportPort),
          Provider<ReaderProgressSyncPort>.value(
            value: ReaderProgressSyncPortAdapter(
              progressSync: bookProgressSync,
            ),
          ),
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
          Provider<RemoteArchiveImportPort>.value(
            value: RemoteArchiveImportPortAdapter(remoteArchiveImportService),
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
          Provider<RssSourceStorePort>.value(
            value: const SharedPreferencesRssSourceStoreAdapter(),
          ),
          ChangeNotifierProvider(
            create: (context) => SourceProvider(
              repository: sourceRepository,
              validationPort: context.read<BookSourceValidationPort>(),
              sourceService: context.read<SourceManagementBookSourcePort>(),
              loginPort: context.read<SourceLoginPagePort>(),
              checkSourcePrefsPort: context.read<CheckSourcePrefsPort>(),
              sourceGroupPort: context.read<SourceGroupCatalogPort>(),
              validationStorePort: context.read<SourceValidationStorePort>(),
              builtInSourcesLoader: BookSourceService.loadBuiltInSources,
            ),
          ),
          Provider<ReaderContentRefetchPort>(
            create: (context) => ReaderContentRefetchPortAdapter(
              contentSource: context.read<BookSourceService>(),
              resolveSource: context.read<SourceProvider>().findSourceForBook,
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => ReplaceProvider(
              repository: ReplaceRuleDao(),
              contentProcessor: contentProcessor,
              presetPort: context.read<ReplacePresetPort>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => RssProvider(
              sourceImportPort: context.read<RssSourceImportPort>(),
              sourceStore: context.read<RssSourceStorePort>(),
            ),
          ),
          Provider<RssSourceEditPort>(
            create: (context) =>
                RssProviderSourceEditAdapter(context.read<RssProvider>()),
          ),
          Provider<RuleSubImportPort>(
            create: (context) => RuleSubImportPortAdapter(
              sourceService: context.read<BookSourceService>(),
              sourceProvider: context.read<SourceProvider>(),
              rssProvider: context.read<RssProvider>(),
              replaceProvider: context.read<ReplaceProvider>(),
              fetchPort: context.read<PublicTextFetchPort>(),
            ),
          ),
          Provider<MainShellStartupPort>(
            create: (context) => MainShellStartupPortAdapter(
              sourceService: context.read<BookSourceService>(),
              sourceProvider: context.read<SourceProvider>(),
              rssProvider: context.read<RssProvider>(),
              replaceProvider: context.read<ReplaceProvider>(),
              fetchPort: context.read<PublicTextFetchPort>(),
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
    FrbRssPort rssPort,
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
    RssService.configureRssPort(rssPort);
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
