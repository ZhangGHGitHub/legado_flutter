import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../bridge/legado_engine_bridge.dart';
import '../models/book_source.dart';
import '../src/rust/api.dart' as rust_api;

/// 书源登录 JS 辅助 — 对齐 Jingshiro Source.login / loginUi 动态表单。
abstract final class SourceLoginService {
  /// 从 `@js:` / `<js>` 抽出脚本体。
  static String extractScript(String raw) {
    final t = raw.trim();
    if (t.startsWith('@js:')) return t.substring(4).trim();
    final m = RegExp(
      r'<js>([\s\S]*?)</js>',
      caseSensitive: false,
    ).firstMatch(t);
    return (m?.group(1) ?? t).trim();
  }

  static bool isHttpUrl(String url) {
    final u = url.trim().toLowerCase();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  static bool isJsUrl(String url) {
    final t = url.trim();
    return t.startsWith('@js:') ||
        t.startsWith('<js>') ||
        t.startsWith('<JS>');
  }

  /// 执行 JS，返回字符串结果；引擎不可用时抛错。
  static String eval(
    String script, {
    String jsLib = '',
    String baseUrl = '',
  }) {
    if (!LegadoEngineBridge.isAvailable) {
      throw StateError('Rust 引擎不可用，无法执行登录 JS');
    }
    return rust_api.evalJs(script: script, jsLib: jsLib, baseUrl: baseUrl);
  }

  /// 解析动态 loginUi：执行 JS，期望返回 JSON 数组（RowUi 列表）。
  static List<Map<String, dynamic>> evalLoginUi(
    BookSource source,
    Map<String, String> loginInfo,
  ) {
    final script = extractScript(source.loginUi);
    if (script.isEmpty) return [];
    final infoJson = jsonEncode(loginInfo);
    final wrapped = '''
var result = $infoJson;
var source = {
  getLoginInfoMap: function() { return result; },
  getLoginInfo: function() { return JSON.stringify(result); },
  getKey: function() { return ${jsonEncode(source.bookSourceUrl)}; },
  getTag: function() { return ${jsonEncode(source.bookSourceName)}; }
};
$script
''';
    final out = eval(
      wrapped,
      jsLib: source.jsLib,
      baseUrl: source.bookSourceUrl,
    );
    return _parseRowList(out);
  }

  /// 执行 loginUrl 中的 JS 登录脚本；对齐 Jingshiro SourceLoginDialog.login：
  /// 先执行 loginUrl 脚本体，再调用 `login()`（若存在）。
  static String evalLoginScript(
    BookSource source,
    Map<String, String> loginInfo,
  ) {
    final script = extractScript(source.loginUrl);
    final infoJson = jsonEncode(loginInfo);
    final wrapped = '''
var result = $infoJson;
var source = {
  getLoginInfoMap: function() { return result; },
  getLoginInfo: function() { return JSON.stringify(result); },
  putLoginInfo: function(s) { try { result = typeof s === 'string' ? JSON.parse(s) : s; } catch(e) {} },
  getKey: function() { return ${jsonEncode(source.bookSourceUrl)}; },
  getTag: function() { return ${jsonEncode(source.bookSourceName)}; }
};
$script
if (typeof login=='function'){ login.apply(this); } else { throw('Function login not implements!!!') }
''';
    return eval(
      wrapped,
      jsLib: source.jsLib,
      baseUrl: source.bookSourceUrl,
    );
  }

  /// 执行登录表单按钮上的 action JS（row 的 name 常为脚本）。
  static String evalButtonAction(
    BookSource source,
    Map<String, String> loginInfo,
    String actionScript,
  ) {
    final script = extractScript(actionScript);
    if (script.isEmpty) return '';
    final infoJson = jsonEncode(loginInfo);
    final wrapped = '''
var result = $infoJson;
var source = {
  getLoginInfoMap: function() { return result; },
  getLoginInfo: function() { return JSON.stringify(result); },
  putLoginInfo: function(s) { try { result = typeof s === 'string' ? JSON.parse(s) : s; } catch(e) {} },
  getKey: function() { return ${jsonEncode(source.bookSourceUrl)}; },
  getTag: function() { return ${jsonEncode(source.bookSourceName)}; }
};
$script
''';
    return eval(
      wrapped,
      jsLib: source.jsLib,
      baseUrl: source.bookSourceUrl,
    );
  }

  static List<Map<String, dynamic>> _parseRowList(String out) {
    final t = out.trim();
    if (t.isEmpty) return [];
    try {
      dynamic decoded = jsonDecode(t);
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('[SourceLogin] loginUi JS 结果解析失败: $e\n$t');
      return [];
    }
  }
}
