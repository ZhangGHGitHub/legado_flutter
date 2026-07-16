import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/book_source.dart';
import '../../models/login_row_ui.dart';
import '../../services/source_login_prefs.dart';
import '../../services/source_login_service.dart';
import '../common/app_webview_page.dart';

/// 书源登录 — 对齐 Jingshiro `SourceLoginDialog` + `dialog_login.xml`
///
/// 支持：静态 JSON loginUi、JS 动态 loginUi、http WebView 登录、JS loginUrl 脚本。
class SourceLoginPage extends StatefulWidget {
  final BookSource source;

  const SourceLoginPage({super.key, required this.source});

  static Future<void> open(BuildContext context, BookSource source) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SourceLoginPage(source: source)),
    );
  }

  @override
  State<SourceLoginPage> createState() => _SourceLoginPageState();
}

class _SourceLoginPageState extends State<SourceLoginPage> {
  final Map<String, TextEditingController> _textCtrls = {};
  final Map<String, String> _values = {};
  final Map<String, bool> _checks = {};
  List<LoginRowUi> _rows = [];
  bool _loading = true;
  bool _jsUi = false;
  bool _busy = false;
  String? _status;

  BookSource get source => widget.source;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    for (final c in _textCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    final saved = await SourceLoginPrefs.load(source.bookSourceUrl);
    final header =
        await SourceLoginPrefs.loadHeader(source.bookSourceUrl) ?? '';
    final loginUi = source.loginUi;
    _jsUi = LoginRowUi.isJsLoginUi(loginUi);

    if (_jsUi) {
      try {
        final maps = SourceLoginService.evalLoginUi(
          source,
          saved,
          loginHeader: header,
        );
        _rows = maps
            .map(LoginRowUi.fromJson)
            .where((e) => e.name.isNotEmpty)
            .toList();
        if (_rows.isEmpty) {
          _status = 'JS loginUi 未返回有效表单，已提供通用用户名/密码';
        }
      } catch (e) {
        _status = 'JS loginUi 执行失败: $e';
        debugPrint('[SourceLogin] loginUi JS: $e');
      }
    } else {
      _rows = LoginRowUi.parse(loginUi);
    }

    _applyRows(saved);

    // 无 loginUi 结果但有 loginUrl：通用用户名/密码
    if (_rows.isEmpty && source.loginUrl.trim().isNotEmpty) {
      _rows = const [
        LoginRowUi(name: 'username', type: LoginRowType.text, viewName: '用户名'),
        LoginRowUi(
          name: 'password',
          type: LoginRowType.password,
          viewName: '密码',
        ),
      ];
      _applyRows(saved);
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _applyRows(Map<String, String> saved) {
    for (final row in _rows) {
      final savedVal = saved[row.name];
      final def = savedVal ?? row.defaultValue ?? '';
      switch (row.type) {
        case LoginRowType.text:
        case LoginRowType.password:
          _textCtrls[row.name] = TextEditingController(text: def);
          _values[row.name] = def;
        case LoginRowType.toggle:
        case LoginRowType.select:
          final chars = row.chars.isNotEmpty ? row.chars : [def];
          final initial =
              chars.contains(def) ? def : (chars.isEmpty ? '' : chars.first);
          _values[row.name] = initial;
        case LoginRowType.checkbox:
          _checks[row.name] =
              savedVal == 'true' ||
              savedVal == '1' ||
              (savedVal == null && def == 'true');
          _values[row.name] = _checks[row.name]! ? 'true' : 'false';
        case LoginRowType.button:
          break;
      }
    }
  }

  Map<String, String> _collect() {
    final out = <String, String>{};
    for (final row in _rows) {
      switch (row.type) {
        case LoginRowType.text:
        case LoginRowType.password:
          out[row.name] = _textCtrls[row.name]?.text ?? '';
        case LoginRowType.toggle:
        case LoginRowType.select:
          out[row.name] = _values[row.name] ?? '';
        case LoginRowType.checkbox:
          out[row.name] = (_checks[row.name] ?? false) ? 'true' : 'false';
        case LoginRowType.button:
          break;
      }
    }
    return out;
  }

  Future<void> _save({bool snack = true}) async {
    final info = _collect();
    await SourceLoginPrefs.save(source.bookSourceUrl, info);
    if (mounted && snack) {
      setState(() => _status = '登录信息已保存');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录信息已保存')),
      );
    }
  }

  Future<void> _clear() async {
    await SourceLoginPrefs.clear(source.bookSourceUrl);
    for (final c in _textCtrls.values) {
      c.clear();
    }
    for (final row in _rows) {
      _values[row.name] = row.defaultValue ?? '';
      _checks[row.name] = false;
      if (_textCtrls.containsKey(row.name)) {
        _textCtrls[row.name]!.text = row.defaultValue ?? '';
      }
    }
    if (mounted) {
      setState(() => _status = '已清除登录信息');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清除登录信息')),
      );
    }
  }

  Future<void> _handleJsResult(LoginJsResult r) async {
    if (r.loginInfo.isNotEmpty) {
      await SourceLoginPrefs.save(source.bookSourceUrl, r.loginInfo);
      for (final e in r.loginInfo.entries) {
        _values[e.key] = e.value;
        if (_textCtrls.containsKey(e.key)) {
          _textCtrls[e.key]!.text = e.value;
        }
      }
    }
    await SourceLoginService.applyCommands(
      r.commands,
      onShowBrowser: (url, html) async {
        if (!mounted) return;
        if (html.isNotEmpty) {
          await AppWebViewPage.openHtml(
            context,
            title: '登录',
            html: html,
            baseUrl: url.isNotEmpty ? url : source.bookSourceUrl,
          );
        } else if (url.isNotEmpty) {
          await AppWebViewPage.openUrl(context, title: '登录', url: url);
        }
      },
      onUpLogin: (data) {
        if (data == null) return;
        setState(() {
          data.forEach((k, v) {
            final s = v?.toString() ?? '';
            _values[k] = s;
            if (_textCtrls.containsKey(k)) _textCtrls[k]!.text = s;
          });
        });
      },
      onReUi: () {
        _init();
      },
      onPutHeader: (h) => SourceLoginPrefs.saveHeader(source.bookSourceUrl, h),
      onDelHeader: () => SourceLoginPrefs.clearHeader(source.bookSourceUrl),
    );
  }

  Future<void> _showLoginHeader() async {
    final h = await SourceLoginPrefs.loadHeader(source.bookSourceUrl);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('登录头'),
        content: SelectableText(
          (h == null || h.isEmpty) ? '（空）' : h,
        ),
        actions: [
          if (h != null && h.isNotEmpty)
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: h));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('复制'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearLoginHeader() async {
    await SourceLoginPrefs.clearHeader(source.bookSourceUrl);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已删除登录头')),
    );
  }

  Future<void> _login() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _save(snack: false);
      final info = _collect();
      final url = source.loginUrl.trim();

      if (url.isEmpty) {
        if (mounted) {
          setState(() => _status = '已保存表单（无可执行 loginUrl）');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录信息已保存；本书源无 loginUrl')),
          );
        }
        return;
      }

      if (SourceLoginService.isHttpUrl(url)) {
        if (!mounted) return;
        await AppWebViewPage.openUrl(
          context,
          title: '登录 · ${source.bookSourceName}',
          url: url,
        );
        if (mounted) {
          setState(() => _status = '已打开登录页，完成后可返回');
        }
        return;
      }

      if (SourceLoginService.isJsUrl(url)) {
        final header =
            await SourceLoginPrefs.loadHeader(source.bookSourceUrl) ?? '';
        final r = SourceLoginService.evalLoginScript(
          source,
          info,
          loginHeader: header,
        );
        await _handleJsResult(r);
        if (mounted) {
          setState(
            () => _status = r.output.isEmpty ? '登录脚本已执行' : '脚本结果：${r.output}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录脚本完成')),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => _status = '无法识别的 loginUrl 格式');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = '登录失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runButton(LoginRowUi row) async {
    final action = row.name.trim().isNotEmpty
        ? row.name
        : (row.defaultValue ?? '');
    if (action.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${row.label}：无动作脚本')),
      );
      return;
    }
    try {
      await _save(snack: false);
      final header =
          await SourceLoginPrefs.loadHeader(source.bookSourceUrl) ?? '';
      final r = SourceLoginService.evalButtonAction(
        source,
        _collect(),
        action,
        loginHeader: header,
      );
      await _handleJsResult(r);
      if (!mounted) return;
      setState(() => _status = r.output.isEmpty ? '${row.label} 已执行' : r.output);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${row.label} 已执行')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${row.label} 失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('登录 · ${source.bookSourceName}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'header':
                  await _showLoginHeader();
                case 'del_header':
                  await _clearLoginHeader();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'header', child: Text('查看登录头')),
              PopupMenuItem(value: 'del_header', child: Text('删除登录头')),
            ],
          ),
          TextButton(onPressed: _busy ? null : _clear, child: const Text('清除')),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('登录'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_jsUi)
                  Card(
                    color: theme.colorScheme.secondaryContainer,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        '本书源 loginUi 为 JS 动态表单，已尝试执行并渲染返回的字段。',
                      ),
                    ),
                  ),
                if (_rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      source.loginUrl.isEmpty
                          ? '本书源未配置 loginUi / loginUrl'
                          : '无可用表单字段，可直接点登录打开 loginUrl',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ..._rows.map(_buildRow),
                if (_status != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _status!,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ],
                const SizedBox(height: 24),
                if (source.loginUrl.isNotEmpty)
                  Text(
                    'loginUrl：${source.loginUrl}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildRow(LoginRowUi row) {
    switch (row.type) {
      case LoginRowType.text:
      case LoginRowType.password:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _textCtrls[row.name],
            obscureText: row.type == LoginRowType.password,
            decoration: InputDecoration(
              labelText: row.label,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => _values[row.name] = v,
          ),
        );
      case LoginRowType.select:
        final chars = row.chars.isNotEmpty
            ? row.chars
            : [_values[row.name] ?? ''];
        final current = _values[row.name];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: row.label,
              border: const OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: chars.contains(current)
                    ? current
                    : (chars.isEmpty ? null : chars.first),
                items: chars
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _values[row.name] = v);
                },
              ),
            ),
          ),
        );
      case LoginRowType.toggle:
        final chars = row.chars.isNotEmpty ? row.chars : ['开', '关'];
        final current = _values[row.name] ?? chars.first;
        final idx = chars.indexOf(current);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(row.label),
            trailing: Text(
              current,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            onTap: () {
              final next = chars[(idx + 1) % chars.length];
              setState(() => _values[row.name] = next);
            },
          ),
        );
      case LoginRowType.checkbox:
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(row.label),
          value: _checks[row.name] ?? false,
          onChanged: (v) {
            setState(() {
              _checks[row.name] = v ?? false;
              _values[row.name] = (v ?? false) ? 'true' : 'false';
            });
          },
        );
      case LoginRowType.button:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: () => _runButton(row),
            child: Text(row.label),
          ),
        );
    }
  }
}
