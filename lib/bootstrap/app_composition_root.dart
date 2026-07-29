import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../application/app_bootstrap.dart';
import '../application/rss/public_text_rss_source_import_port.dart';
import '../bridge/legado_db_bridge.dart';
import '../bridge/legado_engine_bridge.dart';
import '../config/app_config.dart';
import '../config/engine_config.dart';
import '../database/dao/book_dao.dart';
import '../database/dao/replace_rule_dao.dart';
import '../database/dao/source_dao.dart';
import '../domain/ports/backup_local_file_port.dart';
import '../domain/ports/application_binary_http_request_port.dart';
import '../domain/ports/application_http_request_port.dart';
import '../domain/ports/book_source_debug_port.dart';
import '../domain/ports/book_source_validation_port.dart';
import '../domain/ports/dict_rule_query_port.dart';
import '../domain/ports/legacy_room_import_use_case.dart';
import '../domain/ports/public_text_fetch_port.dart';
import '../domain/ports/rss_source_import_port.dart';
import '../domain/ports/webdav_repository.dart';
import '../infrastructure/cache/file_chapter_content_cache.dart';
import '../infrastructure/content/content_processor_adapter.dart';
import '../infrastructure/database/frb_backup_port.dart';
import '../infrastructure/database/frb_database_status_port.dart';
import '../infrastructure/database/frb_legacy_room_import_port.dart';
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
import '../infrastructure/engine/frb_network_engine_port.dart';
import '../infrastructure/engine/frb_note_port.dart';
import '../infrastructure/engine/frb_reading_record_port.dart';
import '../infrastructure/engine/frb_rss_port.dart';
import '../infrastructure/engine/frb_rss_sort_url_js_port.dart';
import '../infrastructure/engine/frb_source_login_cookie_port.dart';
import '../infrastructure/file_system/backup_local_file_adapter.dart';
import '../infrastructure/network/frb_public_text_fetch_port.dart';
import '../infrastructure/network/frb_application_binary_http_request_port.dart';
import '../infrastructure/network/frb_application_http_request_port.dart';
import '../infrastructure/preferences/shared_preferences_book_group_prefs.dart';
import '../infrastructure/preferences/shared_preferences_book_progress_sync_store.dart';
import '../infrastructure/preferences/shared_preferences_code_edit_prefs_store.dart';
import '../infrastructure/web_api/frb_web_api_port.dart';
import '../infrastructure/webdav/frb_webdav_repository.dart';
import '../providers/replace_provider.dart';
import '../providers/rss_provider.dart';
import '../providers/source_provider.dart';
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
import '../services/engine_status_service.dart';
import '../services/legacy_room_import_service_factory.dart';
import '../services/local_book_service.dart';
import '../services/network_prefs.dart';
import '../services/note_service.dart';
import '../services/reading_record_service.dart';
import '../services/rss_service.dart';
import '../services/rss_sort_urls.dart';
import '../services/source_login_service.dart';
import '../services/source_login_cookie_service.dart';
import '../services/tts_service.dart';
import '../services/web_api_service.dart';
import '../services/webdav_prefs.dart';

abstract final class AppCompositionRoot {
  static Future<void> run() async {
    final composition = await _compose();
    runApp(composition.app);
  }

  static Future<({Widget app})> _compose() async {
    const contentCache = FileChapterContentCache();
    const networkEnginePort = FrbNetworkEnginePort();
    const sourceLoginCookiePort = FrbSourceLoginCookiePort();
    const webdavRepository = FrbWebDavRepository();
    const publicTextPort = FrbPublicTextFetchPort();
    const binaryHttpPort = FrbApplicationBinaryHttpRequestPort();
    final bookRepository = BookDao();
    final progressStore = await SharedPreferencesBookProgressSyncStore.load();

    await _configureStaticServices(networkEnginePort, sourceLoginCookiePort);
    TtsService.configureBinaryHttpPort(binaryHttpPort);

    final bookSourceService = BookSourceService(
      searchPort: FrbBookSourceSearchPort(),
      bookInfoPort: FrbBookSourceBookInfoPort(),
      contentPort: FrbBookSourceContentPort(),
      explorePort: FrbBookSourceExplorePort(),
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

    final bootstrap = await AppBootstrap(
      initializePlatform: () async {
        await EngineConfig.load();
        await AppConfig.instance.load();
        await LegadoEngineBridge.tryInit();
        if (LegadoEngineBridge.isAvailable) {
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
      contentProcessor: ContentProcessorAdapter(),
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
    ).initialize();

    return (
      app: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: bootstrap.themeController),
          ChangeNotifierProvider.value(value: AppConfig.instance),
          ChangeNotifierProvider.value(value: bootstrap.bookProvider),
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
              repository: SourceDao(),
              validationPort: context.read<BookSourceValidationPort>(),
              sourceService: bookSourceService,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                ReplaceProvider(repository: ReplaceRuleDao())..loadRules(),
          ),
          ChangeNotifierProvider(
            create: (context) => RssProvider(
              sourceImportPort: context.read<RssSourceImportPort>(),
            )..loadSources(),
          ),
        ],
        child: const LegadoApp(),
      ),
    );
  }

  static Future<void> _configureStaticServices(
    FrbNetworkEnginePort networkEnginePort,
    FrbSourceLoginCookiePort sourceLoginCookiePort,
  ) async {
    BookmarkService.configureBookmarkPort(FrbBookmarkPort());
    BookplateService.configureBookplatePort(FrbBookplatePort());
    DatabaseStatusService.configurePort(const FrbDatabaseStatusPort());
    EngineStatusService.configurePort(const FrbEngineStatusPort());
    NetworkPrefs.configureEnginePort(networkEnginePort);
    NoteService.configureNotePort(FrbNotePort());
    ReadingRecordService.configureRecordPort(FrbReadingRecordPort());
    RssService.configureRssPort(FrbRssPort());
    RssSortUrls.configureJsPort(FrbRssSortUrlJsPort());
    SourceLoginService.configureJsPort(const FrbJsEvalPort());
    SourceLoginCookieService.configurePort(sourceLoginCookiePort);
    WebApiService.configureWebApiPort(FrbWebApiPort());
    BookGroupStore.configurePrefsPort(
      await SharedPreferencesBookGroupPrefs.load(),
    );
    CodeEditPrefs.configureStore(
      await SharedPreferencesCodeEditPrefsStore.load(),
    );
  }
}
