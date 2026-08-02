import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/lifecycle/app_lifecycle_coordinator.dart';
import 'package:legado_flutter/application/mine/my_page_port.dart';
import 'package:legado_flutter/application/reader/reader_font_port.dart';
import '../helpers/fake_reader_font_port.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_flutter/features/my/my_page.dart';
import 'package:legado_flutter/theme/app_theme.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets('MyPage shows settings list items including donate', (
    WidgetTester tester,
  ) async {
    final themeController = ThemeModeController();
    await themeController.load();

    const items = [
      '书源管理',
      'TXT 目录规则',
      '替换净化',
      '字典规则',
      '主题模式',
      '备份与恢复',
      '主题设置',
      '其它设置',
      '书签与想法',
      '文件管理',
      '阅读 Skill',
      'AI 助手',
      '捐赠',
      '关于',
      '退出',
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeController),
          ChangeNotifierProvider(create: (_) => AppLifecycleCoordinator()),
          Provider<ReaderFontPort>.value(value: const _FakeReaderFontPort()),
          Provider<MyPagePort>.value(value: const _FakeMyPagePort()),
        ],
        child: const MaterialApp(home: MyPage()),
      ),
    );
    await tester.pump();

    for (final title in items) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets(
    'MyPage reflects Web service state from the local Riverpod scope',
    (WidgetTester tester) async {
      final themeController = ThemeModeController();
      await themeController.load();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeController),
            ChangeNotifierProvider(create: (_) => AppLifecycleCoordinator()),
            Provider<ReaderFontPort>.value(value: const _FakeReaderFontPort()),
            Provider<MyPagePort>.value(
              value: const _FakeMyPagePort(
                loadStatus: MyPageWebServiceStatus(
                  enabled: true,
                  running: true,
                  baseUrl: 'http://127.0.0.1:1122',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: MyPage()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('已开启'), findsOneWidget);
    },
  );
}

class _FakeMyPagePort implements MyPagePort {
  const _FakeMyPagePort({
    this.loadStatus = const MyPageWebServiceStatus(
      enabled: false,
      running: false,
    ),
  });

  final MyPageWebServiceStatus loadStatus;

  @override
  bool get isEngineAvailable => true;

  @override
  bool get isDatabaseReady => true;

  @override
  String get engineVersion => 'test';

  @override
  Future<MyPageWebServiceStatus> loadWebService() async => loadStatus;

  @override
  Future<MyPageWebServiceStatus> toggleWebService() async =>
      const MyPageWebServiceStatus(enabled: true, running: true, baseUrl: '');

  @override
  Future<String> backupLocally() async => 'backup.zip';
}

class _FakeReaderFontPort extends FakeReaderFontPort {
  const _FakeReaderFontPort();

  @override
  String platformSansFamily() => 'TestSans';

  @override
  List<String> cjkFallbackFamilies() => const ['TestCjk', 'sans-serif'];
}
