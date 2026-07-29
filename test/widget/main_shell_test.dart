import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/database/dao/replace_rule_dao.dart';
import 'package:legado_flutter/database/dao/source_dao.dart';
import 'package:legado_flutter/application/startup/startup_task_runner.dart';
import 'package:legado_flutter/domain/crash/crash_report.dart';
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
          Provider<StartupTaskRunner>(create: (_) => StartupTaskRunner()),
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
        child: const MaterialApp(home: MainShell()),
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
          Provider<StartupTaskRunner>(create: (_) => StartupTaskRunner()),
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
        child: const MaterialApp(home: MainShell()),
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
            Provider<StartupTaskRunner>(create: (_) => StartupTaskRunner()),
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
