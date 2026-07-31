import 'package:flutter/foundation.dart';

import '../domain/ports/reading_record_port.dart';
import '../domain/reading_stats.dart';

export '../application/reader/reading_session_tracker.dart';

/// 阅读记录服务（Rust DB）
class ReadingRecordService {
  static ReadingRecordPort? _configuredRecordPort;

  static ReadingRecordPort get _recordPort =>
      _configuredRecordPort ??
      (throw StateError('ReadingRecordService 尚未配置 ReadingRecordPort'));

  static bool get isReady => _configuredRecordPort?.isAvailable ?? false;

  static void configureRecordPort(ReadingRecordPort port) {
    _configuredRecordPort = port;
  }

  @visibleForTesting
  static void resetRecordPort() {
    _configuredRecordPort = null;
  }

  static bool recordReading({
    required String bookId,
    required String bookName,
    required int chars,
    required int durationSeconds,
  }) {
    if (!isReady || chars < 0 || durationSeconds <= 0) return false;
    return _recordPort.recordReading(
      bookId: bookId,
      bookName: bookName,
      chars: chars,
      durationSeconds: durationSeconds.clamp(0, 86400),
    );
  }

  static ReadingStats? getStats(String range) {
    if (!isReady) return null;
    try {
      return _recordPort.getStats(range);
    } catch (_) {
      return null;
    }
  }

  static String? exportRecords(String format) {
    if (!isReady) return null;
    try {
      return _recordPort.exportRecords(format);
    } catch (_) {
      return null;
    }
  }

  static bool recordDetailedReadSession({
    required String bookName,
    required DateTime startTime,
    required DateTime endTime,
    required int readIteration,
  }) {
    if (!isReady ||
        bookName.trim().isEmpty ||
        endTime.difference(startTime).inMilliseconds <= 120000) {
      return false;
    }
    return _recordPort.recordDetailedReadSession(
      bookName: bookName.trim(),
      startTime: startTime,
      endTime: endTime,
      readIteration: readIteration,
    );
  }

  static String? exportDetailedReadRecords() {
    if (!isReady) return null;
    try {
      return _recordPort.exportDetailedReadRecords();
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
