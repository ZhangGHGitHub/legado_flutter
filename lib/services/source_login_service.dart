import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/ports/js_eval_port.dart';
import '../infrastructure/engine/frb_js_eval_port.dart';
import '../models/book_source.dart';
import '../models/rss_source.dart';

/// JS 侧 `java.*` 命令 — 对齐 Jingshiro [SourceLoginJsExtensions]
class LoginJsCommand {
  LoginJsCommand({
    required this.op,
    this.text = '',
    this.url = '',
    this.html = '',
    this.data,
  });

  final String op; // copy | browser | upLogin | reUi | putHeader | delHeader
  final String text;
  final String url;
  final String html;
  final Map<String, dynamic>? data;
}

class LoginJsResult {
  LoginJsResult({
    required this.output,
    required this.commands,
    this.loginInfo = const {},
  });

  final String output;
  final List<LoginJsCommand> commands;
  final Map<String, String> loginInfo;
}

/// 书源登录 JS 辅助 — 对齐 Jingshiro SourceLoginDialog / SourceLoginJsExtensions。
abstract final class SourceLoginService {
  static JsEvalPort _jsPort = const FrbJsEvalPort();

  @visibleForTesting
  static void configureJsPort(JsEvalPort port) {
    _jsPort = port;
  }

  @visibleForTesting
  static void resetJsPort() {
    _jsPort = const FrbJsEvalPort();
  }

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
    return t.startsWith('@js:') || t.startsWith('<js>') || t.startsWith('<JS>');
  }

  /// RSS 登录用临时 BookSource 视图
  static BookSource bookSourceForRss(RssSource r) {
    return BookSource.fromJson({
      'bookSourceUrl': r.sourceUrl,
      'bookSourceName': r.sourceName,
      'loginUrl': r.loginUrl ?? '',
      'loginUi': r.loginUi,
      'jsLib': r.jsLib,
      'enabled': true,
    });
  }

  static String eval(String script, {String jsLib = '', String baseUrl = ''}) {
    return _jsPort.eval(script: script, jsLib: jsLib, baseUrl: baseUrl);
  }

  static String _prelude(
    BookSource source,
    Map<String, String> loginInfo, {
    String loginHeader = '',
  }) {
    final infoJson = jsonEncode(loginInfo);
    final sourceJson = jsonEncode(source.toJson());
    return '''
var result = $infoJson;
var __legado_cmds = [];
var __legado_login_header = ${jsonEncode(loginHeader)};
if (typeof __legado_set_ajax_ctx === 'function') {
  __legado_set_ajax_ctx($sourceJson, __legado_login_header);
}
if (typeof java === 'undefined' || java === null) { java = {}; }
java.copyText = function(t) { __legado_cmds.push({op:'copy', text: String(t||'')}); };
java.showBrowser = function(url, html) {
  __legado_cmds.push({op:'browser', url: String(url||''), html: html==null?'':String(html)});
};
java.upLoginData = function(d) { __legado_cmds.push({op:'upLogin', data: d||null}); };
java.reLoginView = function(delta) { __legado_cmds.push({op:'reUi', text: String(!!delta)}); };
if (typeof java.ajax !== 'function') {
  java.ajax = (typeof __legado_java_ajax === 'function')
    ? function(u){ return __legado_java_ajax(String(u==null?'':u)); }
    : function(u){ return ''; };
}
var source = {
  getLoginInfoMap: function() { return result; },
  getLoginInfo: function() { return JSON.stringify(result); },
  putLoginInfo: function(s) { try { result = typeof s === 'string' ? JSON.parse(s) : s; } catch(e) {} },
  getLoginHeader: function() { return __legado_login_header; },
  putLoginHeader: function(h) {
    __legado_login_header = String(h||'');
    if (typeof __legado_set_ajax_ctx === 'function') {
      __legado_set_ajax_ctx($sourceJson, __legado_login_header);
    }
    __legado_cmds.push({op:'putHeader', text: __legado_login_header});
  },
  removeLoginHeader: function() {
    __legado_login_header = '';
    if (typeof __legado_set_ajax_ctx === 'function') {
      __legado_set_ajax_ctx($sourceJson, '');
    }
    __legado_cmds.push({op:'delHeader'});
  },
  getKey: function() { return ${jsonEncode(source.bookSourceUrl)}; },
  getTag: function() { return ${jsonEncode(source.bookSourceName)}; },
  getVariable: function() { return ''; }
};
''';
  }

  /// 解析动态 loginUi：脚本末值应为 JSON 数组
  static List<Map<String, dynamic>> evalLoginUi(
    BookSource source,
    Map<String, String> loginInfo, {
    String loginHeader = '',
  }) {
    final script = extractScript(source.loginUi);
    if (script.isEmpty) return [];
    final wrapped =
        '''
${_prelude(source, loginInfo, loginHeader: loginHeader)}
$script
''';
    final out = eval(
      wrapped,
      jsLib: source.jsLib,
      baseUrl: source.bookSourceUrl,
    );
    return _parseRowList(out);
  }

  /// 对齐 SourceLoginDialog.login：执行 loginUrl + `login()`
  static LoginJsResult evalLoginScript(
    BookSource source,
    Map<String, String> loginInfo, {
    String loginHeader = '',
  }) {
    final script = extractScript(source.loginUrl);
    final wrapped =
        '''
${_prelude(source, loginInfo, loginHeader: loginHeader)}
$script
var __legado_out = '';
if (typeof login=='function'){ __legado_out = String(login.apply(this)||''); }
else { throw('Function login not implements!!!'); }
JSON.stringify({ result: __legado_out, cmds: __legado_cmds, login: result });
''';
    final raw = eval(
      wrapped,
      jsLib: source.jsLib,
      baseUrl: source.bookSourceUrl,
    );
    return _parseExtResult(raw);
  }

  /// 对齐 handleButtonClick：loginUrl JS + 按钮 action
  static LoginJsResult evalButtonAction(
    BookSource source,
    Map<String, String> loginInfo,
    String actionScript, {
    String loginHeader = '',
  }) {
    final loginJs = isJsUrl(source.loginUrl)
        ? extractScript(source.loginUrl)
        : '';
    final action = extractScript(actionScript);
    final wrapped =
        '''
${_prelude(source, loginInfo, loginHeader: loginHeader)}
$loginJs
$action
JSON.stringify({ result: '', cmds: __legado_cmds, login: result });
''';
    final raw = eval(
      wrapped,
      jsLib: source.jsLib,
      baseUrl: source.bookSourceUrl,
    );
    return _parseExtResult(raw);
  }

  static Future<void> applyCommands(
    List<LoginJsCommand> cmds, {
    required Future<void> Function(String url, String html) onShowBrowser,
    required void Function(Map<String, dynamic>?) onUpLogin,
    required VoidCallback onReUi,
    required Future<void> Function(String header) onPutHeader,
    required Future<void> Function() onDelHeader,
  }) async {
    for (final c in cmds) {
      switch (c.op) {
        case 'copy':
          await Clipboard.setData(ClipboardData(text: c.text));
        case 'browser':
          await onShowBrowser(c.url, c.html);
        case 'upLogin':
          onUpLogin(c.data);
        case 'reUi':
          onReUi();
        case 'putHeader':
          await onPutHeader(c.text);
        case 'delHeader':
          await onDelHeader();
      }
    }
  }

  static LoginJsResult _parseExtResult(String raw) {
    final t = raw.trim();
    try {
      final obj = jsonDecode(t);
      if (obj is Map) {
        final cmds = <LoginJsCommand>[];
        final cmdsRaw = obj['cmds'];
        if (cmdsRaw is List) {
          for (final e in cmdsRaw) {
            if (e is! Map) continue;
            final m = Map<String, dynamic>.from(e);
            cmds.add(
              LoginJsCommand(
                op: m['op']?.toString() ?? '',
                text: m['text']?.toString() ?? '',
                url: m['url']?.toString() ?? '',
                html: m['html']?.toString() ?? '',
                data: m['data'] is Map
                    ? Map<String, dynamic>.from(m['data'] as Map)
                    : null,
              ),
            );
          }
        }
        final login = <String, String>{};
        final loginRaw = obj['login'];
        if (loginRaw is Map) {
          loginRaw.forEach((k, v) {
            login[k.toString()] = v?.toString() ?? '';
          });
        }
        return LoginJsResult(
          output: obj['result']?.toString() ?? '',
          commands: cmds,
          loginInfo: login,
        );
      }
    } catch (e) {
      debugPrint('[SourceLogin] ext result parse: $e');
    }
    return LoginJsResult(output: t, commands: const []);
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
