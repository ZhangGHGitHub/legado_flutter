import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/reading_record_port.dart';
import 'package:legado_flutter/domain/reading_stats.dart';
import 'package:legado_flutter/services/reading_record_service.dart';

void main() {
  late _FakeRecordPort port;

  setUp(() {
    port = _FakeRecordPort();
    ReadingRecordService.configureRecordPort(port);
  });

  tearDown(ReadingRecordService.resetRecordPort);

  test('reset clears the configured reading record port', () {
    ReadingRecordService.resetRecordPort();

    expect(ReadingRecordService.isReady, isFalse);
    expect(ReadingRecordService.getStats('month'), isNull);
  });

  test('recordReading validates and forwards the persistence delta', () {
    expect(
      ReadingRecordService.recordReading(
        bookId: 'book',
        bookName: '测试书',
        chars: 12,
        durationSeconds: 90000,
      ),
      isTrue,
    );
    expect(port.chars, 12);
    expect(port.durationSeconds, 86400);
    expect(
      ReadingRecordService.recordReading(
        bookId: 'book',
        bookName: '测试书',
        chars: -1,
        durationSeconds: 1,
      ),
      isFalse,
    );
  });

  test('detailed sessions keep the strict two-minute threshold', () {
    final start = DateTime(2026, 1, 1);
    expect(
      ReadingRecordService.recordDetailedReadSession(
        bookName: '测试书',
        startTime: start,
        endTime: start.add(const Duration(seconds: 120)),
        readIteration: 0,
      ),
      isFalse,
    );
    expect(
      ReadingRecordService.recordDetailedReadSession(
        bookName: '测试书',
        startTime: start,
        endTime: start.add(const Duration(seconds: 121)),
        readIteration: 2,
      ),
      isTrue,
    );
    expect(port.readIteration, 2);
  });

  test('statistics and exports are provided by the port', () {
    final stats = ReadingRecordService.getStats('month');
    expect(stats?.totalChars, 123);
    expect(ReadingRecordService.exportRecords('json'), '{json}');
    expect(ReadingRecordService.exportDetailedReadRecords(), '{detail}');
  });
}

class _FakeRecordPort implements ReadingRecordPort {
  @override
  bool isAvailable = true;
  int? chars;
  int? durationSeconds;
  int? readIteration;

  @override
  ReadingStats? getStats(String range) {
    expect(range, 'month');
    return const ReadingStats(
      totalChars: 123,
      totalDurationSeconds: 4,
      todayChars: 1,
      todayDurationSeconds: 2,
      weekChars: 3,
      daily: [],
    );
  }

  @override
  String? exportRecords(String format) => format == 'json' ? '{json}' : null;

  @override
  String? exportDetailedReadRecords() => '{detail}';

  @override
  bool recordReading({
    required String bookId,
    required String bookName,
    required int chars,
    required int durationSeconds,
  }) {
    this.chars = chars;
    this.durationSeconds = durationSeconds;
    return true;
  }

  @override
  bool recordDetailedReadSession({
    required String bookName,
    required DateTime startTime,
    required DateTime endTime,
    required int readIteration,
  }) {
    this.readIteration = readIteration;
    return true;
  }
}
