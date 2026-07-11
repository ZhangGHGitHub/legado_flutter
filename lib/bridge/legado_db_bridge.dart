import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../bridge/legado_engine_bridge.dart';
import '../src/rust/api/db.dart' as rust_db;

/// Rust rusqlite 数据库桥接（与 `legado.db` 同路径）
class LegadoDbBridge {
  static bool _ready = false;

  static bool get isReady => _ready && LegadoEngineBridge.isAvailable;

  /// [dbPathOverride] 仅用于测试，指定完整数据库文件路径。
  static Future<void> init({String? dbPathOverride}) async {
    if (!LegadoEngineBridge.isAvailable || _ready) return;
    final path = dbPathOverride ??
        p.join((await getApplicationSupportDirectory()).path, 'legado.db');
    rust_db.dbInit(path: path);
    _ready = true;
  }

  static void requireReady() {
    if (!isReady) {
      throw StateError('Rust 数据库未初始化，请确保 legado_engine 已加载');
    }
  }
}
