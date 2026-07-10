import 'package:shared_preferences/shared_preferences.dart';

/// 书源引擎配置 — 控制 Rust / Dart 双轨切换
class EngineConfig {
  static const _prefKey = 'use_rust_engine';

  /// 默认使用 Rust 引擎；不可用时自动回退 Dart
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
