import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/database/dao/replace_rule_dao.dart';
import 'package:legado_flutter/database/dao/source_dao.dart';
import 'package:legado_flutter/application/lifecycle/app_lifecycle_coordinator.dart';
import 'package:legado_flutter/application/main/main_shell_startup_port.dart';
import 'package:legado_flutter/application/main/privacy_consent_port.dart';
import 'package:legado_flutter/application/mine/my_page_port.dart';
import 'package:legado_flutter/application/bookshelf/book_group_store_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_local_book_port.dart';
import 'package:legado_flutter/application/preferences/bookshelf_display_prefs_port.dart';
import 'package:legado_flutter/application/reader/reader_font_port.dart';
import '../helpers/fake_reader_font_port.dart';
import 'package:legado_flutter/application/web_api/web_api_prefs_port.dart';
import 'package:legado_flutter/application/startup/startup_task_runner.dart';
import 'package:legado_flutter/domain/crash/crash_report.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/book_group.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/infrastructure/content/content_processor_adapter.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_validation_port.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/config/app_config.dart';
import 'package:legado_flutter/features/main/main_shell.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/replace_provider.dart';
import 'package:legado_flutter/providers/rss_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:legado_flutter/services/book_source_service.dart';
import 'package:legado_flutter/theme/app_theme.dart';
import 'package:legado_flutter/widgets/legado_bottom_nav.dart';
import '../helpers/book_source_service_test_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'legado_privacy_accepted': true});

  var rustReady = false;

  setUpAll(() async {
    await LegadoEngineBridge.tryInit();
    if (LegadoEngineBridge.isAvailable) {
      final tempDir = await Directory.systemTemp.createTemp('legado_widget_');
      await LegadoDbBridge.init(
        dbPathOverride: p.join(tempDir.path, 'legado.db'),
      );
      rustReady = true;
    }
  });

  setUp(() async {
    SharedPreferencesRuntime.resetForTest();
    AppConfig.resetForTest();
    await AppConfig.instance.load();
  });

  tearDown(() {
    AppConfig.resetForTest();
    SharedPreferencesRuntime.resetForTest();
  });

  testWidgets('MainShell shows four bottom tabs', (WidgetTester tester) async {
    if (!rustReady) {
      // 无 Rust DLL 时跳过（CI/无引擎环境）
      return;
    }

    final themeController = ThemeModeController();
    await themeController.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PublicTextFetchPort>.value(
            value: const _EmptyPublicTextFetchPort(),
          ),
          Provider<PrivacyConsentPort>.value(
            value: const _FakePrivacyConsentPort(accepted: true),
          ),
          Provider<BookshelfDisplayPrefsPort>.value(
            value: _FakeBookshelfDisplayPrefsPort(),
          ),
          Provider<ReaderFontPort>.value(value: const _FakeReaderFontPort()),
          Provider<WebApiPrefsPort>.value(value: const _FakeWebApiPrefsPort()),
          Provider<MyPagePort>.value(value: const _FakeMyPagePort()),
          Provider<BookGroupStorePort>.value(
            value: const _FakeBookGroupStorePort(),
          ),
          Provider<BookshelfLocalBookPort>.value(
            value: const _FakeBookshelfLocalBookPort(),
          ),
          Provider<StartupTaskRunner>(create: (_) => StartupTaskRunner()),
          ChangeNotifierProvider(create: (_) => AppLifecycleCoordinator()),
          Provider<BookSourceService>(
            create: (_) => createTestBookSourceService(),
          ),
          ChangeNotifierProvider.value(value: themeController),
          ChangeNotifierProvider.value(value: AppConfig.instance),
          ChangeNotifierProvider(
            create: (_) => BookProvider(
              repository: BookDao(),
              contentCache: const FileChapterContentCache(),
              sourceService: createTestBookSourceService(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => SourceProvider(
              repository: SourceDao(),
              validationPort: FrbBookSourceValidationPort(),
              sourceService: createTestBookSourceService(),
            ),
          ),
          ChangeNotifierProvider(create: (_) => RssProvider()),
          ChangeNotifierProvider(
            create: (_) => ReplaceProvider(
              repository: ReplaceRuleDao(),
              contentProcessor: ContentProcessorAdapter(),
            ),
          ),
        ],
        child: const MaterialApp(
          home: MainShell(startupPort: _FakeMainShellStartupPort()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final bar = find.byType(LegadoBottomNav);
    expect(bar, findsOneWidget);
    for (final label in ['书架', '发现', '订阅', '我的']) {
      expect(
        find.descendant(of: bar, matching: find.text(label)),
        findsOneWidget,
      );
    }
  });

  testWidgets('MainShell hides explore/RSS when disabled', (
    WidgetTester tester,
  ) async {
    if (!rustReady) return;

    final themeController = ThemeModeController();
    await themeController.load();
    await AppConfig.instance.setShowDiscovery(false);
    await AppConfig.instance.setShowRSS(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PublicTextFetchPort>.value(
            value: const _EmptyPublicTextFetchPort(),
          ),
          Provider<PrivacyConsentPort>.value(
            value: const _FakePrivacyConsentPort(accepted: true),
          ),
          Provider<BookshelfDisplayPrefsPort>.value(
            value: _FakeBookshelfDisplayPrefsPort(),
          ),
          Provider<ReaderFontPort>.value(value: const _FakeReaderFontPort()),
          Provider<WebApiPrefsPort>.value(value: const _FakeWebApiPrefsPort()),
          Provider<MyPagePort>.value(value: const _FakeMyPagePort()),
          Provider<BookGroupStorePort>.value(
            value: const _FakeBookGroupStorePort(),
          ),
          Provider<BookshelfLocalBookPort>.value(
            value: const _FakeBookshelfLocalBookPort(),
          ),
          Provider<StartupTaskRunner>(create: (_) => StartupTaskRunner()),
          ChangeNotifierProvider(create: (_) => AppLifecycleCoordinator()),
          Provider<BookSourceService>(
            create: (_) => createTestBookSourceService(),
          ),
          ChangeNotifierProvider.value(value: themeController),
          ChangeNotifierProvider.value(value: AppConfig.instance),
          ChangeNotifierProvider(
            create: (_) => BookProvider(
              repository: BookDao(),
              contentCache: const FileChapterContentCache(),
              sourceService: createTestBookSourceService(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => SourceProvider(
              repository: SourceDao(),
              validationPort: FrbBookSourceValidationPort(),
              sourceService: createTestBookSourceService(),
            ),
          ),
          ChangeNotifierProvider(create: (_) => RssProvider()),
          ChangeNotifierProvider(
            create: (_) => ReplaceProvider(
              repository: ReplaceRuleDao(),
              contentProcessor: ContentProcessorAdapter(),
            ),
          ),
        ],
        child: const MaterialApp(
          home: MainShell(startupPort: _FakeMainShellStartupPort()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final bar = find.byType(LegadoBottomNav);
    expect(find.descendant(of: bar, matching: find.text('书架')), findsOneWidget);
    expect(find.descendant(of: bar, matching: find.text('我的')), findsOneWidget);
    expect(find.descendant(of: bar, matching: find.text('发现')), findsNothing);
    expect(find.descendant(of: bar, matching: find.text('订阅')), findsNothing);
  });

  testWidgets(
    'MainShell shows crash recovery after privacy and consumes marker once',
    (WidgetTester tester) async {
      if (!rustReady) return;
      SharedPreferencesRuntime.resetForTest();
      SharedPreferences.setMockInitialValues({
        'legado_privacy_accepted': false,
      });
      final themeController = ThemeModeController();
      await themeController.load();
      var presented = 0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<PublicTextFetchPort>.value(
              value: const _EmptyPublicTextFetchPort(),
            ),
            Provider<PrivacyConsentPort>.value(
              value: const _FakePrivacyConsentPort(accepted: false),
            ),
            Provider<BookshelfDisplayPrefsPort>.value(
              value: _FakeBookshelfDisplayPrefsPort(),
            ),
            Provider<ReaderFontPort>.value(value: const _FakeReaderFontPort()),
            Provider<WebApiPrefsPort>.value(
              value: const _FakeWebApiPrefsPort(),
            ),
            Provider<MyPagePort>.value(value: const _FakeMyPagePort()),
            Provider<BookGroupStorePort>.value(
              value: const _FakeBookGroupStorePort(),
            ),
            Provider<BookshelfLocalBookPort>.value(
              value: const _FakeBookshelfLocalBookPort(),
            ),
            Provider<StartupTaskRunner>(create: (_) => StartupTaskRunner()),
            ChangeNotifierProvider(create: (_) => AppLifecycleCoordinator()),
            Provider<BookSourceService>(
              create: (_) => createTestBookSourceService(),
            ),
            ChangeNotifierProvider.value(value: themeController),
            ChangeNotifierProvider.value(value: AppConfig.instance),
            ChangeNotifierProvider(
              create: (_) => BookProvider(
                repository: BookDao(),
                contentCache: const FileChapterContentCache(),
                sourceService: createTestBookSourceService(),
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => SourceProvider(
                repository: SourceDao(),
                validationPort: FrbBookSourceValidationPort(),
                sourceService: createTestBookSourceService(),
              ),
            ),
            ChangeNotifierProvider(create: (_) => RssProvider()),
            ChangeNotifierProvider(
              create: (_) => ReplaceProvider(
                repository: ReplaceRuleDao(),
                contentProcessor: ContentProcessorAdapter(),
              ),
            ),
          ],
          child: MaterialApp(
            home: MainShell(
              pendingCrashReport: _crashReport(),
              onCrashReportPresented: () async => presented += 1,
              startupPort: const _FakeMainShellStartupPort(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('隐私政策与用户协议'), findsOneWidget);
      expect(find.textContaining('检测到应用上次运行发生崩溃'), findsNothing);

      await tester.tap(find.text('同意并继续'));
      await tester.pumpAndSettle();
      expect(presented, 1);
      expect(find.textContaining('检测到应用上次运行发生崩溃'), findsOneWidget);

      await tester.tap(find.text('暂不'));
      await tester.pumpAndSettle();
      expect(find.textContaining('检测到应用上次运行发生崩溃'), findsNothing);
      expect(presented, 1);
    },
  );
}

CrashReport _crashReport() => CrashReport(
  occurredAt: DateTime(2026, 7, 29, 12),
  origin: CrashOrigin.unhandledZone,
  startupStage: '书架加载',
  error: 'boom',
  stackTrace: 'stack',
  metadata: const CrashRuntimeMetadata(
    platform: 'windows',
    platformVersion: 'test',
    appVersion: '1.0.0+1',
    engineVersion: '0.5.6',
  ),
);

class _EmptyPublicTextFetchPort implements PublicTextFetchPort {
  const _EmptyPublicTextFetchPort();

  @override
  Future<String> fetch(String url, {String userAgent = ''}) async => '[]';
}

class _FakeMyPagePort implements MyPagePort {
  const _FakeMyPagePort();

  @override
  bool get isEngineAvailable => true;

  @override
  bool get isDatabaseReady => true;

  @override
  String get engineVersion => 'test';

  @override
  Future<MyPageWebServiceStatus> loadWebService() async =>
      const MyPageWebServiceStatus(enabled: false, running: false);

  @override
  Future<MyPageWebServiceStatus> toggleWebService() async =>
      const MyPageWebServiceStatus(enabled: true, running: true);

  @override
  Future<String> backupLocally() async => 'backup.zip';
}

class _FakeBookGroupStorePort implements BookGroupStorePort {
  const _FakeBookGroupStorePort();

  @override
  List<BookGroup> get cached => const [];

  @override
  Future<void> syncNamesFromBooks(Iterable<String> names) async {}
}

class _FakeBookshelfLocalBookPort implements BookshelfLocalBookPort {
  const _FakeBookshelfLocalBookPort();

  @override
  Future<Book?> importLocalBook() async => null;
}

class _FakeMainShellStartupPort implements MainShellStartupPort {
  const _FakeMainShellStartupPort();

  @override
  Future<MainShellBookshelfLayout> loadBookshelfLayout() async =>
      const MainShellBookshelfLayout();

  @override
  MainShellStartupTasks startStartupTasks({required StartupTaskRunner runner}) {
    final report = StartupTaskReport(
      id: 'test',
      status: StartupTaskStatus.succeeded,
      attempt: 1,
      startedAt: DateTime(2026),
      finishedAt: DateTime(2026),
    );
    return MainShellStartupTasks(
      rssSources: Future.value(report),
      replaceRules: Future.value(report),
      sources: Future.value(report),
      ruleSubscriptions: Future.value(const []),
    );
  }
}

class _FakePrivacyConsentPort implements PrivacyConsentPort {
  const _FakePrivacyConsentPort({required this.accepted});

  final bool accepted;

  @override
  Future<bool> isAccepted() async => accepted;

  @override
  Future<bool> saveAccepted() async => true;
}

class _FakeBookshelfDisplayPrefsPort implements BookshelfDisplayPrefsPort {
  @override
  Future<BookshelfDisplayPrefs> load() async => const BookshelfDisplayPrefs();

  @override
  Future<bool> saveGrouped(bool value) async => true;

  @override
  Future<bool> savePinned(Iterable<String> ids) async => true;
}

class _FakeReaderFontPort extends FakeReaderFontPort {
  const _FakeReaderFontPort();

  @override
  String platformSansFamily() => 'TestSans';

  @override
  List<String> cjkFallbackFamilies() => const ['TestCjk', 'sans-serif'];
}

class _FakeWebApiPrefsPort implements WebApiPrefsPort {
  const _FakeWebApiPrefsPort();

  @override
  Future<WebApiConfig> load() async => const WebApiConfig();

  @override
  Future<void> save(WebApiConfig config) async {}
}
