import '../../application/reader/read_book_config_prefs_port.dart';
import '../../features/reader/reader_settings.dart';
import '../../services/read_book_config_prefs.dart' as service;

/// 保留既有 SharedPreferences 键和配置合并语义的端口适配器。
final class ReadBookConfigPrefsPortAdapter implements ReadBookConfigPrefsPort {
  const ReadBookConfigPrefsPortAdapter();

  @override
  Future<ReaderSettings> load({ReaderSettings base = const ReaderSettings()}) =>
      service.ReadBookConfigPrefs.load(base: base);

  @override
  Future<void> save(ReaderSettings settings) =>
      service.ReadBookConfigPrefs.save(settings);
}
