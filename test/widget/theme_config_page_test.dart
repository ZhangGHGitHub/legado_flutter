import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/application/theme/theme_import_port.dart';
import 'package:legado_flutter/features/settings/theme_config_page.dart';
import 'package:legado_flutter/infrastructure/theme/theme_import_port_adapter.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import 'package:legado_flutter/infrastructure/platform/platform_clipboard.dart';
import 'package:legado_flutter/theme/app_theme.dart';
import 'package:legado_flutter/theme/color_presets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeClipboard implements ClipboardPort {
  String? pastedText;
  final copiedTexts = <String>[];

  @override
  Future<void> copyText(String text) async {
    copiedTexts.add(text);
  }

  @override
  Future<String?> pasteText() async => pastedText;
}

class _FakePublicTextFetchPort implements PublicTextFetchPort {
  @override
  Future<String> fetch(String url, {String userAgent = ''}) async => '{}';
}

void main() {
  SharedPreferences.setMockInitialValues({});

  Future<void> pumpPage(
    WidgetTester tester,
    ThemeModeController ctrl, {
    ClipboardPort? clipboard,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: ctrl,
        child: MaterialApp(
          theme: AppTheme.light(preset: ctrl.preset),
          home: Provider<ThemeImportPort>.value(
            value: ThemeImportPortAdapter(_FakePublicTextFetchPort()),
            child: Provider<ClipboardPort>.value(
              value: clipboard ?? const PlatformClipboard(),
              child: const Scaffold(body: ThemeConfigPage()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  testWidgets('ThemeConfigPage lists all MD3 presets', (tester) async {
    final ctrl = ThemeModeController();
    await ctrl.load();
    await pumpPage(tester, ctrl);

    for (final info in LegadoColorPresets.all) {
      expect(find.text(info.label), findsOneWidget);
    }
    expect(find.text('应用配色方案'), findsOneWidget);

    await scrollTo(tester, find.text('阅读主题预设'));
    expect(find.text('阅读主题预设'), findsOneWidget);
  });

  testWidgets('tapping preset updates selection', (tester) async {
    final ctrl = ThemeModeController();
    await ctrl.load();
    await pumpPage(tester, ctrl);

    expect(ctrl.preset, LegadoColorPreset.light);

    await tester.tap(find.text('纸质'));
    await tester.pump();
    expect(ctrl.preset, LegadoColorPreset.paper);

    await tester.tap(find.text('夜间'));
    await tester.pump();
    expect(ctrl.preset, LegadoColorPreset.night);
  });

  testWidgets('export button shows snackbar', (tester) async {
    final ctrl = ThemeModeController();
    await ctrl.load();
    await pumpPage(tester, ctrl);

    await scrollTo(tester, find.text('导出'));
    await tester.ensureVisible(find.text('导出'));
    await tester.tap(find.text('导出'));
    await tester.pump();
    expect(find.text('主题配置已复制到剪贴板'), findsOneWidget);
  });

  testWidgets('export uses the shared clipboard port', (tester) async {
    final ctrl = ThemeModeController();
    await ctrl.load();
    final clipboard = _FakeClipboard();
    await pumpPage(tester, ctrl, clipboard: clipboard);

    await scrollTo(tester, find.text('导出'));
    await tester.tap(find.text('导出'));
    await tester.pump();

    expect(clipboard.copiedTexts, hasLength(1));
    expect(clipboard.copiedTexts.single, contains('"version": "1"'));
  });

  testWidgets('import paste uses the shared clipboard port', (tester) async {
    final ctrl = ThemeModeController();
    await ctrl.load();
    final clipboard = _FakeClipboard()
      ..pastedText = '{"version":"1","mode":"dark","preset":"night"}';
    await pumpPage(tester, ctrl, clipboard: clipboard);

    await scrollTo(tester, find.text('导入'));
    await tester.tap(find.text('导入'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从剪贴板粘贴'));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(clipboard.pastedText!), findsOneWidget);
  });

  testWidgets('shows color editor and import buttons', (tester) async {
    final ctrl = ThemeModeController();
    await ctrl.load();
    await pumpPage(tester, ctrl);

    await scrollTo(tester, find.text('自定义色板（12 色）'));
    expect(find.text('自定义色板（12 色）'), findsOneWidget);

    await scrollTo(tester, find.text('导入'));
    expect(find.text('导入'), findsOneWidget);
    expect(find.text('主题市场'), findsOneWidget);

    await scrollTo(tester, find.text('主色（顶栏）'));
    expect(find.text('主色（顶栏）'), findsOneWidget);
  });

  testWidgets('import dialog applies theme from JSON', (tester) async {
    final ctrl = ThemeModeController();
    await ctrl.load();
    await pumpPage(tester, ctrl);

    await scrollTo(tester, find.text('导入'));
    await tester.ensureVisible(find.text('导入'));
    await tester.tap(find.text('导入'));
    await tester.pumpAndSettle();

    const json = '''
{"version":"1","mode":"dark","preset":"night","colors":{"primary":"#FF5722"}}
''';
    await tester.enterText(find.byType(TextField).first, json);
    await tester.tap(find.text('应用'));
    await tester.pumpAndSettle();

    expect(ctrl.mode, LegadoThemeMode.dark);
    expect(ctrl.preset, LegadoColorPreset.night);
    expect(ctrl.customColors['primary'], const Color(0xFFFF5722));
    expect(find.text('主题已导入'), findsOneWidget);
  });
}
