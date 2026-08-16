import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/simulated_reading_prefs_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_simulated_reading_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads legacy values and marks them for Book migration', () async {
    SharedPreferences.setMockInitialValues({
      'sim_read_book-1_enabled': true,
      'sim_read_book-1_date': '2026-07-29',
      'sim_read_book-1_start': 4,
      'sim_read_book-1_daily': 5,
    });
    final adapter = const SharedPreferencesSimulatedReadingPrefs();

    final loaded = await adapter.loadForBook(Book(id: 'book-1', name: '测试书'));

    expect(loaded.needsBookMigrate, isTrue);
    expect(loaded.config.enabled, isTrue);
    expect(loaded.config.startDateIso, '2026-07-29');
    expect(loaded.config.startChapter, 4);
    expect(loaded.config.dailyChapters, 5);
  });

  test('prefers Book values over legacy preferences', () async {
    SharedPreferences.setMockInitialValues({
      'sim_read_book-1_enabled': true,
      'sim_read_book-1_date': '2026-07-29',
      'sim_read_book-1_start': 4,
      'sim_read_book-1_daily': 5,
    });
    final adapter = const SharedPreferencesSimulatedReadingPrefs();

    final loaded = await adapter.loadForBook(
      Book(
        id: 'book-1',
        name: '测试书',
        simReadEnabled: false,
        simReadStartDate: '2026-07-28',
        simReadStartChapter: 1,
        simReadDailyChapters: 2,
      ),
    );

    expect(loaded.needsBookMigrate, isFalse);
    expect(loaded.config.enabled, isFalse);
    expect(loaded.config.startDateIso, '2026-07-28');
    expect(loaded.config.startChapter, 1);
    expect(loaded.config.dailyChapters, 2);
  });

  test('saves the existing legacy keys', () async {
    final adapter = const SharedPreferencesSimulatedReadingPrefs();
    final config = SimulatedReadingConfig(
      enabled: true,
      startDate: DateTime(2026, 7, 30),
      startChapter: 3,
      dailyChapters: 6,
    );

    await adapter.save('book-1', config);
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getBool('sim_read_book-1_enabled'), isTrue);
    expect(prefs.getString('sim_read_book-1_date'), '2026-07-30');
    expect(prefs.getInt('sim_read_book-1_start'), 3);
    expect(prefs.getInt('sim_read_book-1_daily'), 6);
  });
}
