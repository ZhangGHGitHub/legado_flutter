import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_js/quickjs/quickjs_runtime2.dart';

/// Legado `@js:` 规则执行器
///
/// 使用 QuickJS 引擎执行 JavaScript 表达式，支持 Legado 书源中的 `@js:` 规则。
/// 每个表达式执行时会将当前数据上下文注入为 `result` 变量。
class JsEvaluatorService {
  QuickJsRuntime2? _runtime;
  bool _initialized = false;
  int _evalCount = 0;
  static const _maxEvalBeforeCleanup = 100;

  void _ensureInit() {
    if (_initialized) return;
    try {
      _runtime = QuickJsRuntime2(
        stackSize: 1024 * 512,
        timeout: 1000,
      );
      _initialized = true;
      _evalCount = 0;
      debugPrint('🔧 JS 引擎初始化完成');
    } catch (e) {
      debugPrint('⚠️ JS 引擎初始化失败: $e');
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
      // 构造 JS 代码：注入 data 为 result 变量，然后执行表达式
      final escaped = jsonEncode(data ?? {});
      final code = 'var result = $escaped;\n($expression)';

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
    _runtime = QuickJsRuntime2(
      stackSize: 1024 * 512,
      timeout: 1000,
    );
    _evalCount = 0;
    debugPrint('🔧 JS 引擎已重建');
  }

  /// 释放引擎资源
  void dispose() {
    try {
      _runtime?.dispose();
    } catch (_) {}
    _runtime = null;
    _initialized = false;
  }
}
