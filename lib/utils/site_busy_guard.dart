/// Guards against hammering overloaded novel-site databases (SQLSTATE 1040 etc.).
class SiteBusyGuard {
  SiteBusyGuard._();

  static const friendlyBusyMessage = '源站数据库繁忙，请稍后重试';

  /// Default backoff between busy retries (2–3 attempts total → 2 delays).
  static const defaultDelays = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];

  static final Map<String, Future<dynamic>> _inflight = {};

  static bool isSiteBusyError(Object error) {
    final s = error.toString();
    return s.contains('Too many connections') ||
        (s.contains('SQLSTATE') && s.contains('1040')) ||
        s.contains('目录页站点异常') ||
        s.contains('数据库连接失败');
  }

  static String friendlyMessage(Object error) {
    if (isSiteBusyError(error)) return friendlyBusyMessage;
    final s = error.toString();
    // Strip Exception: / Error: prefixes for snackbars
    final stripped = s
        .replaceFirst(RegExp(r'^(Exception|Error|StateError):\s*'), '')
        .trim();
    return stripped.isEmpty ? s : stripped;
  }

  /// Retries [action] when the failure looks like site DB overload.
  ///
  /// Total attempts = `delays.length + 1` (default 3).
  static Future<T> retryOnBusy<T>(
    Future<T> Function() action, {
    List<Duration> delays = defaultDelays,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        if (!isSiteBusyError(e) || attempt >= delays.length) {
          rethrow;
        }
        await Future<void>.delayed(delays[attempt]);
        attempt++;
      }
    }
  }

  /// Coalesces concurrent work for the same [key] onto one shared [Future].
  static Future<T> dedupeByKey<T>(String key, Future<T> Function() action) {
    final existing = _inflight[key];
    if (existing != null) {
      return existing.then((v) => v as T);
    }
    final future = action();
    _inflight[key] = future;
    future.whenComplete(() {
      if (identical(_inflight[key], future)) {
        _inflight.remove(key);
      }
    });
    return future;
  }

  /// Test-only: clear coalescing map.
  static void debugReset() => _inflight.clear();
}
