import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用级配置（底栏显隐等）— ChangeNotifier，变更后立即生效
class AppConfig extends ChangeNotifier {
  static const _showDiscoveryKey = 'app_config_show_discovery';
  static const _showRssKey = 'app_config_show_rss';

  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._();

  AppConfig._();

  /// 测试或自定义注入
  @visibleForTesting
  static void resetForTest([AppConfig? config]) {
    _instance = config;
  }

  bool _showDiscovery = true;
  bool _showRSS = true;
  bool _loaded = false;

  bool get showDiscovery => _showDiscovery;
  bool get showRSS => _showRSS;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _showDiscovery = prefs.getBool(_showDiscoveryKey) ?? true;
    _showRSS = prefs.getBool(_showRssKey) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setShowDiscovery(bool value) async {
    if (_showDiscovery == value) return;
    _showDiscovery = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showDiscoveryKey, value);
  }

  Future<void> setShowRSS(bool value) async {
    if (_showRSS == value) return;
    _showRSS = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showRssKey, value);
  }
}
