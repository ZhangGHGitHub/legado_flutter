import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 的进程级初始化状态。
enum SharedPreferencesRuntimeState {
  uninitialized,
  initializing,
  ready,
  failed,
}

/// 统一管理 SharedPreferences 初始化，避免启动阶段重复竞态和未捕获异常。
abstract final class SharedPreferencesRuntime {
  static SharedPreferences? _prefs;
  static Future<SharedPreferences?>? _pending;
  static Future<SharedPreferences> Function()? _loaderOverride;
  static SharedPreferencesRuntimeState _state =
      SharedPreferencesRuntimeState.uninitialized;
  static Object? _error;

  static SharedPreferencesRuntimeState get state => _state;
  static bool get isReady => _state == SharedPreferencesRuntimeState.ready;
  static Object? get error => _error;

  /// 初始化失败时返回 null；后续调用允许重试，以覆盖平台存储短暂不可用的情况。
  static Future<SharedPreferences?> load({
    Future<SharedPreferences> Function()? loader,
  }) {
    final prefs = _prefs;
    if (prefs != null) return Future<SharedPreferences?>.value(prefs);
    final pending = _pending;
    if (pending != null) return pending;

    _state = SharedPreferencesRuntimeState.initializing;
    final future = _load(
      loader ?? _loaderOverride ?? SharedPreferences.getInstance,
    );
    _pending = future;
    return future;
  }

  static Future<SharedPreferences?> _load(
    Future<SharedPreferences> Function() loader,
  ) async {
    try {
      final prefs = await loader();
      _prefs = prefs;
      _error = null;
      _state = SharedPreferencesRuntimeState.ready;
      return prefs;
    } catch (error) {
      _prefs = null;
      _error = error;
      _state = SharedPreferencesRuntimeState.failed;
      debugPrint('[Preferences] SharedPreferences 初始化失败: $error');
      return null;
    } finally {
      _pending = null;
    }
  }

  static Future<SharedPreferences?> getOrNull() => load();

  @visibleForTesting
  static void setLoaderForTest(Future<SharedPreferences> Function()? loader) {
    _loaderOverride = loader;
  }

  @visibleForTesting
  static void resetForTest() {
    _prefs = null;
    _pending = null;
    _loaderOverride = null;
    _error = null;
    _state = SharedPreferencesRuntimeState.uninitialized;
  }
}
