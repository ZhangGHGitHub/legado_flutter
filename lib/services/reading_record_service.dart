import 'package:flutter/foundation.dart';

import '../domain/ports/reading_record_port.dart';
import '../domain/reading_stats.dart';

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

/// 阅读页的增量会话计时器，避免只在页面销毁时写入整段会话。
class ReadingSessionTracker {
  ReadingSessionTracker({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  DateTime? _startedAt;
  int _totalChars = 0;
  int _committedChars = 0;

  bool get isStarted => _startedAt != null;

  void start() {
    _startedAt ??= _clock();
  }

  void addChars(int chars) {
    if (chars > 0) _totalChars += chars;
  }

  ReadingSessionDelta? pending() {
    final startedAt = _startedAt;
    if (startedAt == null) return null;
    final endedAt = _clock();
    final durationSeconds = endedAt.difference(startedAt).inSeconds;
    if (durationSeconds <= 0) return null;
    return ReadingSessionDelta(
      chars: _totalChars - _committedChars,
      durationSeconds: durationSeconds,
      endedAt: endedAt,
    );
  }

  void commit(ReadingSessionDelta delta) {
    _committedChars += delta.chars;
    _startedAt = delta.endedAt;
  }
}

class ReadingSessionDelta {
  const ReadingSessionDelta({
    required this.chars,
    required this.durationSeconds,
    required this.endedAt,
  });

  final int chars;
  final int durationSeconds;
  final DateTime endedAt;
}

/// 原版 DetailedReadRecordTracker 的 Dart 侧会话计时器。
class DetailedReadingSessionTracker {
  DetailedReadingSessionTracker({
    required this.bookName,
    required this.readIteration,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final String bookName;
  final int readIteration;
  final DateTime Function() _clock;
  DateTime? _startedAt;

  void start() {
    _startedAt ??= _clock();
  }

  DetailedReadingSession? stop() {
    final startedAt = _startedAt;
    _startedAt = null;
    if (startedAt == null) return null;
    final endedAt = _clock();
    if (endedAt.difference(startedAt).inMilliseconds <= 120000 ||
        bookName.trim().isEmpty) {
      return null;
    }
    return DetailedReadingSession(
      bookName: bookName.trim(),
      startTime: startedAt,
      endTime: endedAt,
      readIteration: readIteration,
    );
  }
}

class DetailedReadingSession {
  const DetailedReadingSession({
    required this.bookName,
    required this.startTime,
    required this.endTime,
    required this.readIteration,
  });

  final String bookName;
  final DateTime startTime;
  final DateTime endTime;
  final int readIteration;
}
