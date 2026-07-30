import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/platform/clipboard_port.dart';
import 'package:legado_flutter/domain/ports/reading_record_port.dart';
import 'package:legado_flutter/domain/reading_stats.dart';
import 'package:legado_flutter/features/my/read_record_page.dart';
import 'package:provider/provider.dart';

class _FakeClipboard implements ClipboardPort {
  String? copiedText;

  @override
  Future<void> copyText(String text) async => copiedText = text;

  @override
  Future<String?> pasteText() async => copiedText;
}

class _FakeReadingRecordPort implements ReadingRecordPort {
  String? exportedFormat;

  @override
  bool isAvailable = true;

  @override
  ReadingStats? getStats(String range) {
    expect(range, 'month');
    return const ReadingStats(
      totalChars: 25000,
      totalDurationSeconds: 3660,
      todayChars: 1500,
      todayDurationSeconds: 120,
      weekChars: 500,
      daily: [],
    );
  }

  @override
  String? exportRecords(String format) {
    exportedFormat = format;
    return 'exported-$format';
  }

  @override
  String? exportDetailedReadRecords() => null;

  @override
  bool recordReading({
    required String bookId,
    required String bookName,
    required int chars,
    required int durationSeconds,
  }) => true;

  @override
  bool recordDetailedReadSession({
    required String bookName,
    required DateTime startTime,
    required DateTime endTime,
    required int readIteration,
  }) => true;
}

void main() {
  testWidgets(
    'ReadRecordPage reads stats and exports through ReadingRecordPort',
    (tester) async {
      final port = _FakeReadingRecordPort();
      final clipboard = _FakeClipboard();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ClipboardPort>.value(value: clipboard),
            Provider<ReadingRecordPort>.value(value: port),
          ],
          child: const MaterialApp(home: ReadRecordPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2.5 万字'), findsOneWidget);
      expect(find.text('1.5 千字'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.download_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('导出 JSON'));
      await tester.pump();

      expect(port.exportedFormat, 'json');
      expect(clipboard.copiedText, 'exported-json');
    },
  );
}
