import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/config/backup_config_page.dart';

void main() {
  testWidgets('BackupConfigPage shows backup actions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BackupConfigPage())),
    );
    await tester.pump();

    expect(find.text('一键本地备份'), findsOneWidget);
    expect(find.text('从文件恢复'), findsOneWidget);
    expect(find.text('上传到 WebDAV'), findsOneWidget);
    expect(find.text('从 WebDAV 恢复'), findsOneWidget);
    expect(find.text('WebDAV 备份'), findsOneWidget);
    expect(find.byTooltip('刷新 WebDAV 备份'), findsOneWidget);
  });
}
