import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/simulated_reading_prefs_port.dart';

void main() {
  test('disabled reading exposes all chapters', () {
    final config = SimulatedReadingConfig(
      startDate: DateTime.now(),
      dailyChapters: 4,
    );

    expect(config.simulatedTotalChapterNum(20), 20);
    expect(config.maxReadableIndex(20), 19);
  });

  test('enabled reading unlocks start chapters plus daily interval', () {
    final today = DateTime.now();
    final config = SimulatedReadingConfig(
      enabled: true,
      startDate: DateTime(today.year, today.month, today.day),
      startChapter: 2,
      dailyChapters: 4,
    );

    expect(config.simulatedTotalChapterNum(20), 6);
    expect(config.maxReadableIndex(20), 5);
  });

  test('unlock count is capped at total chapters', () {
    final today = DateTime.now();
    final config = SimulatedReadingConfig(
      enabled: true,
      startDate: DateTime(today.year, today.month, today.day),
      dailyChapters: 10,
    );

    expect(config.simulatedTotalChapterNum(3), 3);
  });
}
