import 'package:flutter/foundation.dart';

/// Per-source rate limiter for Legado concurrency control.
///
/// Supports two formats:
///   `1000` - minimum interval of 1000ms between requests
///   `20/60000` - max 20 requests per 60000ms sliding window
class RateLimiter {
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();

  // Source URL -> list of request timestamps (for sliding window)
  final _requestTimes = <String, List<int>>{};
  // Source URL -> parsed config cache
  final _configs = <String, _RateConfig>{};

  /// Parse and cache rate limit config
  /// Format: "1000" or "20/60000"
  void configure(String sourceUrl, String configStr) {
    if (configStr.isEmpty) return;
    try {
      if (configStr.contains('/')) {
        final parts = configStr.split('/');
        final count = int.tryParse(parts[0].trim());
        final windowMs = int.tryParse(parts[1].trim());
        if (count != null && windowMs != null && count > 0 && windowMs > 0) {
          _configs[sourceUrl] = _RateConfig(count: count, windowMs: windowMs);
          debugPrint('  RateLimiter: $sourceUrl -> $count / ${windowMs}ms');
        }
      } else {
        final interval = int.tryParse(configStr.trim());
        if (interval != null && interval > 0) {
          _configs[sourceUrl] = _RateConfig(intervalMs: interval);
          debugPrint('  RateLimiter: $sourceUrl -> interval ${interval}ms');
        }
      }
    } catch (e) {
      debugPrint('  RateLimiter parse error: $configStr -> $e');
    }
  }

  /// Wait until the request is allowed. Returns the wait duration in ms.
  Future<int> waitIfNeeded(String sourceUrl) async {
    final config = _configs[sourceUrl];
    if (config == null) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final times = _requestTimes.putIfAbsent(sourceUrl, () => []);

    if (config.intervalMs > 0) {
      // Interval-based: wait if last request was too recent
      if (times.isNotEmpty) {
        final elapsed = now - times.last;
        if (elapsed < config.intervalMs) {
          final waitMs = config.intervalMs - elapsed;
          debugPrint(
            '  RateLimiter: wait ${waitMs}ms (interval ${config.intervalMs}ms)',
          );
          await Future.delayed(Duration(milliseconds: waitMs));
        }
      }
    } else if (config.count > 0 && config.windowMs > 0) {
      // Sliding window: remove old entries, check count
      final windowStart = now - config.windowMs;
      times.removeWhere((t) => t < windowStart);

      if (times.length >= config.count) {
        // Wait until the oldest entry expires
        final oldest = times.first;
        final waitMs = (oldest + config.windowMs) - now + 1;
        if (waitMs > 0) {
          debugPrint(
            '  RateLimiter: wait ${waitMs}ms (${config.count}/${config.windowMs}ms window)',
          );
          await Future.delayed(Duration(milliseconds: waitMs));
        }
      }
    }

    // Record this request
    _requestTimes[sourceUrl]!.add(DateTime.now().millisecondsSinceEpoch);
    // Trim old entries periodically
    if (_requestTimes[sourceUrl]!.length > 100) {
      final cutoff = now - 60000;
      _requestTimes[sourceUrl]!.removeWhere((t) => t < cutoff);
    }

    return 0;
  }

  /// Clear rate limit state for a source
  void reset(String sourceUrl) {
    _requestTimes.remove(sourceUrl);
    _configs.remove(sourceUrl);
  }

  /// Clear all rate limit state
  void clear() {
    _requestTimes.clear();
    _configs.clear();
  }
}

class _RateConfig {
  final int intervalMs; // e.g. 1000ms between requests
  final int count; // e.g. 20 requests
  final int windowMs; // e.g. per 60000ms

  const _RateConfig({this.intervalMs = 0, this.count = 0, this.windowMs = 0});
}
