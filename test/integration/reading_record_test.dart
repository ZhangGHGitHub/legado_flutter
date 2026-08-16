import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/infrastructure/engine/frb_reading_record_port.dart';
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
        ReadingRecordService.configureRecordPort(FrbReadingRecordPort());
      }
    });

    tearDownAll(ReadingRecordService.resetRecordPort);

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
      ReadingRecordService.recordReading(
        bookId: 'test_book',
        bookName: '测试书',
        chars: 0,
        durationSeconds: 60,
      );

      final stats = ReadingRecordService.getStats('month');
      expect(stats, isNotNull);
      expect(stats!.todayChars, greaterThanOrEqualTo(2000));
      expect(stats.todayDurationSeconds, greaterThanOrEqualTo(480));
      expect(stats.daily, isNotEmpty);

      final csv = ReadingRecordService.exportRecords('csv');
      expect(csv, isNotNull);
      expect(csv!, contains('test_book'));
      expect(csv, contains('2000'));

      final json = ReadingRecordService.exportRecords('json');
      expect(json, isNotNull);
      expect(json!, contains('"bookName"'));

      final start = DateTime.now().subtract(const Duration(minutes: 10));
      expect(
        ReadingRecordService.recordDetailedReadSession(
          bookName: '测试书',
          startTime: start,
          endTime: start.add(const Duration(minutes: 2, seconds: 1)),
          readIteration: 1,
        ),
        isTrue,
      );
      final detailed = ReadingRecordService.exportDetailedReadRecords();
      expect(detailed, isNotNull);
      final groups = jsonDecode(detailed!) as List<dynamic>;
      expect(groups.single['bookName'], '测试书');
      expect((groups.single['sessions'] as List<dynamic>), hasLength(1));
    });
  });
}
