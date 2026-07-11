import 'package:shared_preferences/shared_preferences.dart';

/// 书源引擎配置 — Rust 为唯一书源引擎（Phase E-B）
class EngineConfig {
  static const _prefKey = 'use_rust_engine';

  /// 默认启用 Rust；关闭后书源操作将报错（无 Dart 回退）
  static bool useRust = true;

  /// 从 SharedPreferences 加载配置
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    useRust = prefs.getBool(_prefKey) ?? true;
  }

  /// 切换引擎并持久化
  static Future<void> setUseRust(bool value) async {
    useRust = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }
}
