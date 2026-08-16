import '../../features/reader/reader_settings.dart';

/// 全局阅读配置的应用层持久化边界。
abstract interface class ReadBookConfigPrefsPort {
  Future<ReaderSettings> load({ReaderSettings base = const ReaderSettings()});

  Future<void> save(ReaderSettings settings);
}
