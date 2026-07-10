import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_js/quickjs/quickjs_runtime2.dart';
import 'jsoup_polyfill.dart';

/// Legado `@js:` 规则执行器
///
/// 使用 QuickJS 引擎执行 JavaScript 表达式，支持 Legado 书源中的 `@js:` 规则。
/// 每个表达式执行时会将当前数据上下文注入为 `result` 变量，
/// 并预置 Legado 标准库函数（base64Decode, javaTimeNow 等）。
class JsEvaluatorService {
  QuickJsRuntime2? _runtime;
  bool _initialized = false;
  bool _libLoaded = false;
  bool _jsoupLoaded = false;
  int _evalCount = 0;
  static const _maxEvalBeforeCleanup = 100;

  // ── Legado 标准库 JS 代码 ──
  static const String _legadoStdLib = '''
// Legado 标准库函数
var legadoResult = null;

function base64Decode(str) {
  try {
    var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
    var output = '';
    var bytes = [];
    for (var i = 0; i < str.length; i++) {
      var c = str.charAt(i);
      if (c === '=') break;
      var idx = chars.indexOf(c);
      if (idx === -1) continue;
      bytes.push(idx);
    }
    var buf = [];
    for (var i = 0; i < bytes.length; i += 4) {
      var b1 = bytes[i], b2 = bytes[i+1]||0, b3 = bytes[i+2]||0, b4 = bytes[i+3]||0;
      buf.push((b1 << 2) | (b2 >> 4));
      if (b3 !== 0) buf.push(((b2 & 0xF) << 4) | (b3 >> 2));
      if (b4 !== 0) buf.push(((b3 & 0x3) << 6) | b4);
    }
    for (var i = 0; i < buf.length; i++) {
      output += String.fromCharCode(buf[i]);
    }
    return output;
  } catch(e) { return ''; }
}

function base64Encode(str) {
  try {
    var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    var bytes = [];
    for (var i = 0; i < str.length; i++) {
      bytes.push(str.charCodeAt(i));
    }
    var result = '';
    for (var i = 0; i < bytes.length; i += 3) {
      var b1 = bytes[i], b2 = bytes[i+1]||0, b3 = bytes[i+2]||0;
      result += chars.charAt(b1 >> 2);
      result += chars.charAt(((b1 & 3) << 4) | (b2 >> 4));
      result += chars.charAt(((b2 & 15) << 2) | (b3 >> 6));
      result += chars.charAt(b3 & 63);
    }
    if (bytes.length % 3 === 1) result = result.substring(0, result.length-2) + '==';
    if (bytes.length % 3 === 2) result = result.substring(0, result.length-1) + '=';
    return result;
  } catch(e) { return ''; }
}

function javaTimeNow() {
  return new Date().getTime();
}

function currentTime() {
  return javaTimeNow();
}

function replaceRegex(str, pattern, replacement) {
  try {
    var flags = 'gm';
    if (pattern.startsWith('/')) {
      var end = pattern.lastIndexOf('/');
      if (end > 0) {
        flags = pattern.substring(end + 1) || 'gm';
        pattern = pattern.substring(1, end);
      }
    }
    return str.replace(new RegExp(pattern, flags), replacement);
  } catch(e) { return str; }
}

function formatDate(date, fmt) {
  try {
    var d = typeof date === 'number' ? new Date(date) : new Date(date);
    var map = {
      'yyyy': d.getFullYear(),
      'MM': ('0' + (d.getMonth()+1)).slice(-2),
      'dd': ('0' + d.getDate()).slice(-2),
      'HH': ('0' + d.getHours()).slice(-2),
      'mm': ('0' + d.getMinutes()).slice(-2),
      'ss': ('0' + d.getSeconds()).slice(-2),
    };
    var result = fmt;
    for (var key in map) result = result.replace(key, map[key]);
    return result;
  } catch(e) { return fmt; }
}

function substr(str, start, len) {
  if (len !== undefined) return str.substring(start, start + len);
  return str.substring(start);
}

function toInt(str) {
  var n = parseInt(str);
  return isNaN(n) ? 0 : n;
}

function toFloat(str) {
  var n = parseFloat(str);
  return isNaN(n) ? 0.0 : n;
}

function join(list, sep) {
  if (Array.isArray(list)) return list.join(sep || ',');
  return '' + list;
}

function getDomain(url) {
  try {
    var m = url.match(/https?:\\/\\/([^\\/]+)/);
    return m ? m[1] : '';
  } catch(e) { return ''; }
}

function getResponseUrl() {
  return legadoResult && legadoResult._responseUrl ? legadoResult._responseUrl : '';
}

function baseUrl(url) {
  try {
    var m = url.match(/^(https?:\\/\\/[^\\/]+)/);
    return m ? m[1] : '';
  } catch(e) { return ''; }
}

function parseUrl(url, base) {
  if (url.startsWith('http')) return url;
  var b = baseUrl(base);
  if (url.startsWith('/')) return b + url;
  return b + '/' + url;
}
''';

  void _ensureInit() {
    if (_initialized) return;
    try {
      _runtime = QuickJsRuntime2(stackSize: 1024 * 512, timeout: 5000);
      _initialized = true;
      _evalCount = 0;
      _libLoaded = false;
      debugPrint('🔧 JS 引擎初始化完成');
    } catch (e) {
      debugPrint('⚠️ JS 引擎初始化失败: $e');
    }
  }

  /// 注入 Legado 标准库
  void _ensureLibLoaded() {
    if (_libLoaded || _runtime == null) return;
    try {
      _runtime!.evaluate(_legadoStdLib);
      _libLoaded = true;
      debugPrint('📚 Legado 标准库已注入');
    } catch (e) {
      debugPrint('⚠️ Legado 标准库注入失败: $e');
    }
  }

  /// 注入 Jsoup 兼容层（Packages.org.jsoup.Jsoup）
  void _ensureJsoupLoaded() {
    if (_jsoupLoaded || _runtime == null) return;
    try {
      _runtime!.evaluate(jsoupPolyfill);
      _jsoupLoaded = true;
      debugPrint('📚 Jsoup 兼容层已注入');
    } catch (e) {
      debugPrint('⚠️ Jsoup 兼容层注入失败: $e');
    }
  }

  /// 对 HTML 字符串执行 Legado <js> 脚本（result = html）
  String runHtmlJs(String script, String html, {String jsLib = ''}) {
    _ensureInit();
    if (_runtime == null) return '';
    try {
      _ensureLibLoaded();
      _ensureJsoupLoaded();
      _evalCount++;
      if (_evalCount > _maxEvalBeforeCleanup) _recreateEngine();
      final escaped = jsonEncode(html);
      final code =
          'legadoResult = $escaped;\nvar result = legadoResult;\n$jsLib\n$script';
      final jsResult = _runtime!.evaluate(code);
      final raw = jsResult.rawResult;
      final str = jsResult.stringResult;
      if (raw is String) return raw;
      if (str.isNotEmpty) return str;
      if (raw != null) return raw.toString();
      return '';
    } catch (e) {
      debugPrint('⚠️ HTML JS 脚本执行失败: $e');
      return '';
    }
  }

  /// 执行 JS 表达式，[data] 作为 `result` 变量注入
  String eval(String expression, [Map<String, dynamic>? data]) {
    _ensureInit();
    if (_runtime == null) {
      debugPrint('⚠️ JS 引擎不可用，跳过: "$expression"');
      return '';
    }

    try {
      _ensureLibLoaded();

      // 构造 JS 代码：注入 data 为 result 变量，然后执行表达式
      final escaped = jsonEncode(data ?? {});
      // 将数据同时注入 result 和 legadoResult（供标准库函数访问）
      final code =
          'legadoResult = $escaped;\nvar result = legadoResult;\n($expression)';

      _evalCount++;
      if (_evalCount > _maxEvalBeforeCleanup) {
        _recreateEngine();
      }

      final jsResult = _runtime!.evaluate(code);
      final raw = jsResult.rawResult;
      final str = jsResult.stringResult;

      if (raw is String) return raw;
      if (raw is num) return raw.toString();
      if (raw is bool) return raw.toString();
      if (str.isNotEmpty) return str;
      if (raw != null) return raw.toString();

      return '';
    } catch (e) {
      debugPrint('⚠️ JS 执行失败: "$expression" — $e');
      return '';
    }
  }

  /// 重建 JS 引擎
  void _recreateEngine() {
    try {
      _runtime?.dispose();
    } catch (_) {}
    _runtime = QuickJsRuntime2(stackSize: 1024 * 512, timeout: 5000);
    _evalCount = 0;
    _libLoaded = false;
    _jsoupLoaded = false;
    debugPrint('🔧 JS 引擎已重建');
  }

  /// 释放引擎资源
  void dispose() {
    try {
      _runtime?.dispose();
    } catch (_) {}
    _runtime = null;
    _initialized = false;
    _libLoaded = false;
    _jsoupLoaded = false;
  }

  /// Execute a full script (not wrapped in expression parens).
  /// Suitable for scripts with var/function declarations.
  String runScript(String code) {
    _ensureInit();
    if (_runtime == null) return '';
    try {
      _ensureLibLoaded();
      _evalCount++;
      if (_evalCount > _maxEvalBeforeCleanup) _recreateEngine();
      final jsResult = _runtime!.evaluate(code);
      final raw = jsResult.rawResult;
      final str = jsResult.stringResult;
      if (raw is String) return raw;
      if (raw is num) return raw.toString();
      if (raw is bool) return raw.toString();
      if (str.isNotEmpty) return str;
      if (raw != null) return raw.toString();
      return '';
    } catch (e) {
      debugPrint('⚠️ JS 脚本执行失败: $e');
      return '';
    }
  }
}
