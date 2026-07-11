import '../bridge/legado_db_bridge.dart';
import '../bridge/legado_engine_bridge.dart';
import '../src/rust/api.dart' as rust_api;

/// 阅读记录服务（Rust DB）
class ReadingRecordService {
  static bool get isReady =>
      LegadoEngineBridge.isAvailable && LegadoDbBridge.isReady;

  static void recordReading({
    required String bookId,
    required String bookName,
    required int chars,
    required int durationSeconds,
  }) {
    if (!isReady || chars <= 0) return;
    try {
      rust_api.recordReading(
        bookId: bookId,
        bookName: bookName,
        chars: chars,
        durationSeconds: durationSeconds.clamp(0, 86400),
      );
    } catch (_) {}
  }

  static rust_api.ReadingStats? getStats(String range) {
    if (!isReady) return null;
    try {
      return rust_api.getReadingStats(range: range);
    } catch (_) {
      return null;
    }
  }

  static String? exportRecords(String format) {
    if (!isReady) return null;
    try {
      return rust_api.exportReadingRecords(format: format);
    } catch (_) {
      return null;
    }
  }

  static String formatChars(int chars) {
    if (chars >= 10000) {
      return '${(chars / 10000).toStringAsFixed(1)} 万字';
    }
    if (chars >= 1000) {
      return '${(chars / 1000).toStringAsFixed(1)} 千字';
    }
    return '$chars 字';
  }

  static String formatDuration(int seconds) {
    if (seconds < 60) return '$seconds 秒';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    if (remain == 0) return '$hours 小时';
    return '$hours 小时 $remain 分';
  }
}
