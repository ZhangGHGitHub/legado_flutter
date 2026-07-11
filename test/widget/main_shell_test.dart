import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/pages/main/main_shell.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/replace_provider.dart';
import 'package:legado_flutter/providers/rss_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:legado_flutter/theme/app_theme.dart';

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
          ChangeNotifierProvider.value(value: themeController),
          ChangeNotifierProvider(create: (_) => BookProvider()),
          ChangeNotifierProvider(create: (_) => SourceProvider()),
          ChangeNotifierProvider(create: (_) => RssProvider()),
          ChangeNotifierProvider(create: (_) => ReplaceProvider()),
        ],
        child: const MaterialApp(home: MainShell()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final bar = find.byType(NavigationBar);
    expect(bar, findsOneWidget);
    for (final label in ['书架', '发现', '订阅', '我的']) {
      expect(
        find.descendant(of: bar, matching: find.text(label)),
        findsOneWidget,
      );
    }
  });
}
