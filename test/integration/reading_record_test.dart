import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/services/reading_record_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('阅读记录 Rust 集成', () {
    late bool rustReady;

    setUpAll(() async {
      await LegadoEngineBridge.tryInit();
      rustReady = LegadoEngineBridge.isAvailable;
      if (rustReady) {
        final tempDir = await Directory.systemTemp.createTemp('legado_rr_');
        await LegadoDbBridge.init(
          dbPathOverride: p.join(tempDir.path, 'legado.db'),
        );
      }
    });

    test('record + stats + export', () {
      if (!rustReady) return;

      ReadingRecordService.recordReading(
        bookId: 'test_book',
        bookName: '测试书',
        chars: 1200,
        durationSeconds: 300,
      );
      ReadingRecordService.recordReading(
        bookId: 'test_book',
        bookName: '测试书',
        chars: 800,
        durationSeconds: 120,
      );

      final stats = ReadingRecordService.getStats('month');
      expect(stats, isNotNull);
      expect(stats!.todayChars, greaterThanOrEqualTo(2000));
      expect(stats.daily, isNotEmpty);

      final csv = ReadingRecordService.exportRecords('csv');
      expect(csv, isNotNull);
      expect(csv!, contains('test_book'));
      expect(csv, contains('2000'));

      final json = ReadingRecordService.exportRecords('json');
      expect(json, isNotNull);
      expect(json!, contains('"bookName"'));
    });
  });
}
