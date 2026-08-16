import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_session_tracker.freezed.dart';

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

@freezed
class ReadingSessionDelta with _$ReadingSessionDelta {
  const factory ReadingSessionDelta({
    required int chars,
    required int durationSeconds,
    required DateTime endedAt,
  }) = _ReadingSessionDelta;
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

@freezed
class DetailedReadingSession with _$DetailedReadingSession {
  const factory DetailedReadingSession({
    required String bookName,
    required DateTime startTime,
    required DateTime endTime,
    required int readIteration,
  }) = _DetailedReadingSession;
}
