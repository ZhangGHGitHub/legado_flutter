import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/lifecycle/app_lifecycle_coordinator.dart';
import 'package:legado_flutter/application/reader/reader_font_port.dart';
import 'package:legado_flutter/application/web_api/web_api_prefs_port.dart';
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
          Provider<WebApiPrefsPort>.value(value: const _FakeWebApiPrefs()),
        ],
        child: const MaterialApp(home: MyPage()),
      ),
    );
    await tester.pump();

    for (final title in items) {
      expect(find.text(title), findsOneWidget);
    }
  });
}

class _FakeWebApiPrefs implements WebApiPrefsPort {
  const _FakeWebApiPrefs();

  @override
  Future<WebApiConfig> load() async => const WebApiConfig();

  @override
  Future<void> save(WebApiConfig config) async {}
}

class _FakeReaderFontPort implements ReaderFontPort {
  const _FakeReaderFontPort();

  @override
  String platformSansFamily() => 'TestSans';

  @override
  List<String> cjkFallbackFamilies() => const ['TestCjk', 'sans-serif'];
}
