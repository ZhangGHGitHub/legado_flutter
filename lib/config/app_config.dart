import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用级配置（底栏显隐等）— ChangeNotifier，变更后立即生效
class AppConfig extends ChangeNotifier {
  static const _showDiscoveryKey = 'app_config_show_discovery';
  static const _showRssKey = 'app_config_show_rss';
  static const _defaultHomePageKey = 'app_config_default_home';
  static const _syncBookProgressKey = 'app_config_sync_book_progress';

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
  String _defaultHomePage = 'bookshelf';
  bool _syncBookProgress = true;
  bool _loaded = false;
  Future<void>? _loadFuture;

  bool get showDiscovery => _showDiscovery;
  bool get showRSS => _showRSS;
  String get defaultHomePage => _defaultHomePage;
  bool get syncBookProgress => _syncBookProgress;
  bool get isLoaded => _loaded;

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loadFuture ??= _loadInternal();
  }

  Future<void> _loadInternal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showDiscovery = prefs.getBool(_showDiscoveryKey) ?? true;
      _showRSS = prefs.getBool(_showRssKey) ?? true;
      _defaultHomePage = _normalizeHomePage(
        prefs.getString(_defaultHomePageKey) ?? 'bookshelf',
      );
      _syncBookProgress = prefs.getBool(_syncBookProgressKey) ?? true;
      _loaded = true;
      notifyListeners();
    } finally {
      _loadFuture = null;
    }
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

  Future<void> setDefaultHomePage(String value) async {
    final normalized = _normalizeHomePage(value);
    if (_defaultHomePage == normalized) return;
    _defaultHomePage = normalized;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultHomePageKey, normalized);
  }

  Future<void> setSyncBookProgress(bool value) async {
    if (_syncBookProgress == value) return;
    _syncBookProgress = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncBookProgressKey, value);
  }

  static String _normalizeHomePage(String v) {
    if (const ['bookshelf', 'explore', 'rss', 'mine'].contains(v)) return v;
    return 'bookshelf';
  }
}
