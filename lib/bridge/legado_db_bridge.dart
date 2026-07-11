import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../bridge/legado_engine_bridge.dart';
import '../src/rust/api/db.dart' as rust_db;

/// Rust rusqlite 数据库桥接（与 `legado.db` 同路径）
class LegadoDbBridge {
  static bool _ready = false;

  static bool get isReady => _ready && LegadoEngineBridge.isAvailable;

  static Future<void> init() async {
    if (!LegadoEngineBridge.isAvailable || _ready) return;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'legado.db');
    rust_db.dbInit(path: path);
    _ready = true;
  }

  static void requireReady() {
    if (!isReady) {
      throw StateError('Rust 数据库未初始化，请确保 legado_engine 已加载');
    }
  }
}
