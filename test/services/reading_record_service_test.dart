import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/reading_record_service.dart';

void main() {
  group('ReadingRecordService formatting', () {
    test('formatChars uses 千字 and 万字', () {
      expect(ReadingRecordService.formatChars(500), '500 字');
      expect(ReadingRecordService.formatChars(1500), '1.5 千字');
      expect(ReadingRecordService.formatChars(25000), '2.5 万字');
    });

    test('formatDuration shows minutes and hours', () {
      expect(ReadingRecordService.formatDuration(45), '45 秒');
      expect(ReadingRecordService.formatDuration(120), '2 分钟');
      expect(ReadingRecordService.formatDuration(3660), '1 小时 1 分');
    });
  });
}
