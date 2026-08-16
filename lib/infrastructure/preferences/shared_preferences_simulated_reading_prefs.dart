import 'package:legado_flutter/application/reader/simulated_reading_prefs_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/services/simulated_reading_prefs.dart';

/// 将现有模拟追读 SharedPreferences 服务接入应用层端口。
final class SharedPreferencesSimulatedReadingPrefs
    implements SimulatedReadingPrefsPort {
  const SharedPreferencesSimulatedReadingPrefs();

  @override
  Future<({SimulatedReadingConfig config, bool needsBookMigrate})> loadForBook(
    Book book,
  ) => SimulatedReadingPrefs.loadForBook(book);

  @override
  Future<void> save(String bookId, SimulatedReadingConfig config) =>
      SimulatedReadingPrefs.save(bookId, config);
}
