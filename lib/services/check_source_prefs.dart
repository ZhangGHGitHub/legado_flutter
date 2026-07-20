import 'package:shared_preferences/shared_preferences.dart';

/// 书源校验设置 — 对齐 Jingshiro `CheckSourceConfig`
abstract final class CheckSourcePrefs {
  static const timeoutSecKey = 'check_source_timeout_sec';
  static const checkSearchKey = 'check_search';
  static const checkDiscoveryKey = 'check_discovery';
  static const checkTocKey = 'check_toc';
  static const checkContentKey = 'check_content';
  static const lastKeywordKey = 'check_source_last_keyword';

  static const defaultTimeoutSec = 30;

  static Future<int> timeoutSec() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(timeoutSecKey) ?? defaultTimeoutSec;
  }

  static Future<void> setTimeoutSec(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(timeoutSecKey, v);
  }

  static Future<bool> checkSearch() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(checkSearchKey) ?? true;
  }

  static Future<void> setCheckSearch(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(checkSearchKey, v);
  }

  static Future<bool> checkDiscovery() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(checkDiscoveryKey) ?? true;
  }

  static Future<void> setCheckDiscovery(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(checkDiscoveryKey, v);
  }

  static Future<bool> checkToc() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(checkTocKey) ?? true;
  }

  static Future<void> setCheckToc(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(checkTocKey, v);
  }

  static Future<bool> checkContent() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(checkContentKey) ?? true;
  }

  static Future<void> setCheckContent(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(checkContentKey, v);
  }

  static Future<String> lastKeyword() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(lastKeywordKey) ?? '';
  }

  static Future<void> setLastKeyword(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(lastKeywordKey, v);
  }
}
