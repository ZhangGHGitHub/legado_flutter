import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../bridge/legado_engine_bridge.dart';
import '../services/app_paths.dart';
import '../src/rust/api/db.dart' as rust_db;

/// Rust rusqlite 数据库桥接（与 `legado.db` 同路径）
enum LegadoDbInitState { uninitialized, initializing, ready, failed }

class LegadoDbBridge {
  static bool _ready = false;
  static Future<void>? _pendingInit;
  static LegadoDbInitState _state = LegadoDbInitState.uninitialized;
  static Object? _initError;

  static bool get isReady => _ready && LegadoEngineBridge.isAvailable;
  static LegadoDbInitState get initState => _state;
  static Object? get initError => _initError;

  /// [dbPathOverride] 仅用于测试，指定完整数据库文件路径。
  static Future<void> init({String? dbPathOverride}) {
    if (!LegadoEngineBridge.isAvailable || _ready) {
      return Future<void>.value();
    }
    final pending = _pendingInit;
    if (pending != null) return pending;

    _state = LegadoDbInitState.initializing;
    final future = _initInternal(dbPathOverride: dbPathOverride);
    _pendingInit = future;
    return future;
  }

  static Future<void> _initInternal({String? dbPathOverride}) async {
    try {
      final appDir = dbPathOverride == null
          ? (await AppPaths.dataRoot()).path
          : p.dirname(dbPathOverride);
      rust_db.init(appDir: appDir);
      _ready = true;
      _initError = null;
      _state = LegadoDbInitState.ready;
    } catch (error) {
      _ready = false;
      _initError = error;
      _state = LegadoDbInitState.failed;
      // 这里不能依赖 AppLog：数据库初始化失败时日志存储也可能未就绪。
      debugPrint('[Database] Rust SQLite 初始化失败: $error');
    } finally {
      _pendingInit = null;
    }
  }

  static void requireReady() {
    if (!isReady) {
      final suffix = _state == LegadoDbInitState.failed
          ? '（初始化失败：$_initError）'
          : '';
      throw StateError('Rust 数据库当前不可用，请确保 legado_engine 已加载$suffix');
    }
  }
}
