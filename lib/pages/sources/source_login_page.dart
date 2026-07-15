import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/book_source.dart';
import '../../models/login_row_ui.dart';
import '../../services/source_login_prefs.dart';

/// 书源登录 — 对齐 Jingshiro `SourceLoginDialog` + `dialog_login.xml`
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
    final saved = await SourceLoginPrefs.load(source.bookSourceUrl);
    final loginUi = source.loginUi;
    _jsUi = LoginRowUi.isJsLoginUi(loginUi);
    _rows = LoginRowUi.parse(loginUi);

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
          final initial = chars.contains(def) ? def : (chars.isEmpty ? '' : chars.first);
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

    // 无 loginUi 但有 loginUrl：提供用户名/密码通用两项
    if (_rows.isEmpty && !_jsUi && source.loginUrl.trim().isNotEmpty) {
      _rows = const [
        LoginRowUi(name: 'username', type: LoginRowType.text, viewName: '用户名'),
        LoginRowUi(
          name: 'password',
          type: LoginRowType.password,
          viewName: '密码',
        ),
      ];
      for (final row in _rows) {
        final def = saved[row.name] ?? '';
        _textCtrls[row.name] = TextEditingController(text: def);
        _values[row.name] = def;
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
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

  Future<void> _login() async {
    await _save(snack: false);
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

    // URL 登录：浏览器打开（对齐 WebView 登录的轻量路径）
    if (url.startsWith('http://') || url.startsWith('https://')) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          setState(() => _status = '已打开登录页，完成后可返回');
        }
        return;
      }
    }

    // JS / 特殊 loginUrl：引擎侧登录尚未接通
    if (mounted) {
      setState(() => _status = 'JS 登录脚本暂未接通引擎');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('表单已保存；JS 登录执行尚需引擎接口（后续接入）'),
        ),
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
          TextButton(onPressed: _clear, child: const Text('清除')),
          FilledButton(
            onPressed: _login,
            child: const Text('登录'),
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
                        '本书源 loginUi 为 JS 动态表单，当前版本暂以通用表单/URL 登录代替；'
                        '静态 JSON loginUi 可完整渲染。',
                      ),
                    ),
                  ),
                if (_rows.isEmpty && !_jsUi)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      source.loginUrl.isEmpty
                          ? '本书源未配置 loginUi / loginUrl'
                          : '无 loginUi，已提供用户名/密码输入',
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
                value: chars.contains(current) ? current : (chars.isEmpty ? null : chars.first),
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${row.label}：自定义按钮 JS 尚未接入')),
              );
            },
            child: Text(row.label),
          ),
        );
    }
  }
}
