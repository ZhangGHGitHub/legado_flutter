import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/crash/crash_report.dart';
import 'package:legado_flutter/features/main/crash_recovery_prompt.dart';

void main() {
  testWidgets('opens the persisted crash log from the one-shot prompt', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCrashRecoveryPrompt(context, _report()),
            child: const Text('show'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('检测到应用上次运行发生崩溃，是否打开崩溃日志以便报告问题？'), findsOneWidget);

    await tester.tap(find.text('打开日志'));
    await tester.pumpAndSettle();
    expect(find.text('崩溃日志'), findsOneWidget);
    expect(find.textContaining('startupStage=书架加载'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('崩溃日志'), findsNothing);
  });

  testWidgets('dismisses the prompt without opening the log', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCrashRecoveryPrompt(context, _report()),
            child: const Text('show'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('暂不'));
    await tester.pumpAndSettle();
    expect(find.text('崩溃日志'), findsNothing);
  });
}

CrashReport _report() => CrashReport(
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
