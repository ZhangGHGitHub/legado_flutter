import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/features/settings/other_settings_card.dart';
import 'package:legado_flutter/services/app_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    tempRoot = Directory.systemTemp.createTempSync('legado_other_settings_');
    SharedPreferences.setMockInitialValues({
      AppDataPrefs.dataDirKey: tempRoot.path,
    });
    await SharedPreferences.getInstance();
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  testWidgets('OtherSettingsCard shows network cache and data sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: OtherSettingsCard())),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      if (find.text('网络代理').evaluate().isNotEmpty) break;
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }

    expect(find.text('网络代理'), findsOneWidget);
    expect(find.text('启用代理'), findsOneWidget);
    expect(find.text('保存网络设置'), findsOneWidget);
    expect(find.text('数据目录'), findsOneWidget);
    expect(find.text('保存数据目录'), findsOneWidget);
    expect(find.text('缓存管理'), findsOneWidget);
    expect(find.text('清书籍缓存'), findsOneWidget);
    expect(find.text('清 Cookie/JS'), findsOneWidget);
    expect(find.text('清本地备份'), findsOneWidget);
    expect(find.text('一键清理'), findsOneWidget);
  });
}
