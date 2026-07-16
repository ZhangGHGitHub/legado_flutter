import 'dart:convert';

import 'package:flutter/material.dart';

/// 代码编辑结果 — 对齐 Jingshiro [CodeEditActivity] `RESULT_OK` extras。
class CodeEditResult {
  const CodeEditResult({required this.text, required this.cursorPosition});

  final String text;
  final int cursorPosition;
}

/// 代码编辑器 — 1:1 对齐 Jingshiro [activity_code_edit.xml] + [CodeEditActivity]。
///
/// Chrome：TitleBar、搜索/保存、溢出菜单（主题/格式化/设置/自动换行/日志）、
/// 底栏查找·替换（正则、上个/下个/替换/全部）。
/// 语法高亮为 stub（无 Sora TextMate）；monospace + 可选暗色主题底。
class CodeEditPage extends StatefulWidget {
  const CodeEditPage({
    super.key,
    required this.initialText,
    this.title,
    this.cursorPosition = 0,
    this.writable = true,
    this.languageName,
  });

  /// 对齐 intent `text` / `cacheKey` 只读文本。
  final String initialText;

  /// 对齐 intent `title`；空则用 `@string/edit_code`「编辑代码」。
  final String? title;

  /// 对齐 intent `cursorPosition`。
  final int cursorPosition;

  /// 对齐 ViewModel `writable`（cacheKey 只读时为 false）。
  final bool writable;

  /// 对齐 intent `languageName`（如 `source.js`）；用于格式化分支。
  final String? languageName;

  /// 打开编辑器并等待结果（对齐 `StartActivityForResult`）。
  static Future<CodeEditResult?> open(
    BuildContext context, {
    required String text,
    String? title,
    int cursorPosition = 0,
    bool writable = true,
    String? languageName,
  }) {
    return Navigator.of(context).push<CodeEditResult>(
      MaterialPageRoute(
        builder: (_) => CodeEditPage(
          initialText: text,
          title: title,
          cursorPosition: cursorPosition,
          writable: writable,
          languageName: languageName,
        ),
      ),
    );
  }

  @override
  State<CodeEditPage> createState() => _CodeEditPageState();
}

class _CodeEditPageState extends State<CodeEditPage> {
  static const _themeNames = [
    'Monokai Dimmed',
    'Monokai',
    'Modern Dark',
    'Modern Light',
    'Solarized Dark',
    'Solarized Light',
    'Abyss',
    'Quiet Light',
  ];

  late final TextEditingController _controller;
  late final FocusNode _editorFocus;
  final _findCtrl = TextEditingController();
  final _replaceCtrl = TextEditingController();
  final _findFocus = FocusNode();
  final _replaceFocus = FocusNode();

  late String _initialText;
  bool _searchVisible = false;
  bool _replaceVisible = false;
  bool _isRegex = true;
  bool _autoWrap = true;
  double _fontSize = 18;
  int _themeIndex = 1;
  int _matchIndex = -1;
  List<TextRange> _matches = const [];

  @override
  void initState() {
    super.initState();
    _initialText = widget.initialText;
    _controller = TextEditingController(text: _initialText);
    _editorFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pos = widget.cursorPosition.clamp(0, _controller.text.length);
      _controller.selection = TextSelection.collapsed(offset: pos);
      _editorFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorFocus.dispose();
    _findCtrl.dispose();
    _replaceCtrl.dispose();
    _findFocus.dispose();
    _replaceFocus.dispose();
    super.dispose();
  }

  bool get _isDarkTheme {
    final name = _themeNames[_themeIndex.clamp(0, _themeNames.length - 1)];
    return name.contains('Dark') ||
        name == 'Monokai' ||
        name == 'Monokai Dimmed' ||
        name == 'Abyss';
  }

  Future<void> _save({required bool checkUnsaved}) async {
    if (!widget.writable) {
      Navigator.of(context).pop();
      return;
    }
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset.clamp(0, text.length);

    if (text == _initialText) {
      if (cursor > 0) {
        Navigator.of(context).pop(
          CodeEditResult(text: text, cursorPosition: cursor),
        );
      } else {
        Navigator.of(context).pop();
      }
      return;
    }

    if (checkUnsaved) {
      final cont = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('退出'),
          content: const Text('尚未保存，是否继续编辑'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('否'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('是'),
            ),
          ],
        ),
      );
      // 是 = 继续编辑；否 = 不保存退出（对齐 CodeEditActivity.save(check=true)）
      if (!mounted || cont == true || cont == null) return;
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop(
      CodeEditResult(text: text, cursorPosition: cursor),
    );
  }

  void _openSearch() {
    if (_searchVisible) return;
    setState(() => _searchVisible = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findFocus.requestFocus();
      _runSearch(_findCtrl.text);
    });
  }

  void _closeSearch() {
    setState(() {
      _searchVisible = false;
      _replaceVisible = false;
      _matches = const [];
      _matchIndex = -1;
    });
    _editorFocus.requestFocus();
  }

  void _closeReplace() {
    setState(() => _replaceVisible = false);
    _findFocus.requestFocus();
  }

  void _runSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _matches = const [];
        _matchIndex = -1;
      });
      return;
    }
    final text = _controller.text;
    final ranges = <TextRange>[];
    try {
      if (_isRegex) {
        final re = RegExp(query);
        for (final m in re.allMatches(text)) {
          ranges.add(TextRange(start: m.start, end: m.end));
        }
      } else {
        var from = 0;
        final q = query;
        while (true) {
          final i = text.indexOf(q, from);
          if (i < 0) break;
          ranges.add(TextRange(start: i, end: i + q.length));
          from = i + (q.isEmpty ? 1 : q.length);
        }
      }
    } on FormatException {
      setState(() {
        _matches = const [];
        _matchIndex = -1;
      });
      return;
    }
    setState(() {
      _matches = ranges;
      _matchIndex = ranges.isEmpty ? -1 : 0;
    });
    if (ranges.isNotEmpty) _selectMatch(0);
  }

  void _selectMatch(int index) {
    if (_matches.isEmpty) return;
    final i = index % _matches.length;
    final r = _matches[i];
    setState(() => _matchIndex = i);
    _controller.selection = TextSelection(
      baseOffset: r.start,
      extentOffset: r.end,
    );
  }

  void _gotoPrevious() {
    if (_matches.isEmpty) return;
    final next = _matchIndex <= 0 ? _matches.length - 1 : _matchIndex - 1;
    _selectMatch(next);
  }

  void _gotoNext() {
    if (_matches.isEmpty) return;
    _selectMatch(_matchIndex + 1);
  }

  void _onReplacePressed() {
    if (!_replaceVisible) {
      setState(() => _replaceVisible = true);
      _replaceFocus.requestFocus();
      return;
    }
    _replaceCurrent();
  }

  void _replaceCurrent() {
    if (_matches.isEmpty || _matchIndex < 0) return;
    final r = _matches[_matchIndex];
    final repl = _replaceCtrl.text;
    final text = _controller.text;
    final next = text.replaceRange(r.start, r.end, repl);
    final cursor = r.start + repl.length;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: cursor),
    );
    _runSearch(_findCtrl.text);
  }

  void _replaceAll() {
    if (_matches.isEmpty || _findCtrl.text.isEmpty) return;
    final repl = _replaceCtrl.text;
    String next;
    try {
      if (_isRegex) {
        next = _controller.text.replaceAll(RegExp(_findCtrl.text), repl);
      } else {
        next = _controller.text.replaceAll(_findCtrl.text, repl);
      }
    } on FormatException {
      return;
    }
    _controller.text = next;
    _runSearch(_findCtrl.text);
  }

  void _formatCode() {
    final text = _controller.text;
    final lang = widget.languageName ?? '';
    if (lang.contains('markdown')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('markdown不需要格式化')),
      );
      return;
    }
    try {
      final decoded = jsonDecode(text);
      final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      _controller.text = pretty;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已格式化')),
      );
    } catch (_) {
      // 无 js-beautify WebView：非 JSON 时仅 trim 行空白（stub）
      final lines = text.split('\n').map((l) => l.trimRight()).toList();
      _controller.text = lines.join('\n').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已整理空白（完整 JS 格式化待接）')),
      );
    }
  }

  Future<void> _showThemePicker() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择主题'),
        children: [
          for (var i = 0; i < _themeNames.length; i++)
            ListTile(
              title: Text(_themeNames[i]),
              trailing: i == _themeIndex
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, i),
            ),
        ],
      ),
    );
    if (picked != null) setState(() => _themeIndex = picked);
  }

  Future<void> _showSettings() async {
    var font = _fontSize;
    var wrap = _autoWrap;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('字号'),
                  Expanded(
                    child: Slider(
                      value: font,
                      min: 12,
                      max: 28,
                      divisions: 16,
                      label: font.round().toString(),
                      onChanged: (v) => setLocal(() => font = v),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('自动换行'),
                value: wrap,
                onChanged: (v) => setLocal(() => wrap = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _fontSize = font;
                  _autoWrap = wrap;
                });
                Navigator.pop(ctx);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('日志'),
        content: const SizedBox(
          width: double.maxFinite,
          child: Text('暂无日志', style: TextStyle(fontFamily: 'monospace')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String get _searchResultLabel {
    if (_matches.isEmpty) return '0';
    final cur = _matchIndex >= 0 ? '${_matchIndex + 1}/' : '';
    return '$cur${_matches.length}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = _isDarkTheme;
    final editorBg = dark ? const Color(0xFF1E1E1E) : theme.colorScheme.surface;
    final editorFg = dark ? const Color(0xFFD4D4D4) : theme.colorScheme.onSurface;
    final cardBg = theme.colorScheme.surfaceContainerLow;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _save(checkUnsaved: true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            (widget.title?.trim().isNotEmpty == true)
                ? widget.title!.trim()
                : '编辑代码',
          ),
          actions: [
            IconButton(
              tooltip: '搜索',
              icon: const Icon(Icons.search),
              onPressed: _openSearch,
            ),
            if (widget.writable)
              IconButton(
                tooltip: '保存',
                icon: const Icon(Icons.save_outlined),
                onPressed: () => _save(checkUnsaved: false),
              ),
            PopupMenuButton<_CodeMenu>(
              onSelected: (item) {
                switch (item) {
                  case _CodeMenu.theme:
                    _showThemePicker();
                  case _CodeMenu.format:
                    _formatCode();
                  case _CodeMenu.settings:
                    _showSettings();
                  case _CodeMenu.autoWrap:
                    setState(() => _autoWrap = !_autoWrap);
                  case _CodeMenu.log:
                    _showLog();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: _CodeMenu.theme,
                  child: Text('选择主题'),
                ),
                const PopupMenuItem(
                  value: _CodeMenu.format,
                  child: Text('格式化'),
                ),
                const PopupMenuItem(
                  value: _CodeMenu.settings,
                  child: Text('设置'),
                ),
                CheckedPopupMenuItem(
                  value: _CodeMenu.autoWrap,
                  checked: _autoWrap,
                  child: const Text('自动换行'),
                ),
                const PopupMenuItem(
                  value: _CodeMenu.log,
                  child: Text('日志'),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: editorBg,
                child: _autoWrap
                    ? TextField(
                        controller: _controller,
                        focusNode: _editorFocus,
                        readOnly: !widget.writable,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: _fontSize,
                          height: 1.45,
                          color: editorFg,
                        ),
                        cursorColor: theme.colorScheme.primary,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        keyboardType: TextInputType.multiline,
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.sizeOf(context).width,
                            minHeight: MediaQuery.sizeOf(context).height * 0.5,
                          ),
                          child: IntrinsicWidth(
                            child: TextField(
                              controller: _controller,
                              focusNode: _editorFocus,
                              readOnly: !widget.writable,
                              maxLines: null,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: _fontSize,
                                height: 1.45,
                                color: editorFg,
                              ),
                              cursorColor: theme.colorScheme.primary,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                              ),
                              keyboardType: TextInputType.multiline,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            if (_searchVisible) _buildSearchGroup(cardBg, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchGroup(Color cardBg, ThemeData theme) {
    final primaryText = theme.colorScheme.onSurface;
    return Material(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('搜索结果:', style: TextStyle(fontSize: 14, color: primaryText)),
                const SizedBox(width: 8),
                Text(
                  _searchResultLabel,
                  style: TextStyle(fontSize: 14, color: primaryText),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('正则', style: TextStyle(fontSize: 14, color: primaryText)),
                    Switch(
                      value: _isRegex,
                      onChanged: (v) {
                        setState(() => _isRegex = v);
                        _runSearch(_findCtrl.text);
                      },
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Text('查找', style: TextStyle(fontSize: 14, color: primaryText)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _findCtrl,
                    focusNode: _findFocus,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onChanged: _runSearch,
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _closeSearch,
                ),
              ],
            ),
            if (_replaceVisible)
              Row(
                children: [
                  Text('替换', style: TextStyle(fontSize: 14, color: primaryText)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _replaceCtrl,
                      focusNode: _replaceFocus,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _closeReplace,
                  ),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _gotoPrevious,
                    child: Text(
                      '上个',
                      style: TextStyle(fontSize: 14, color: primaryText),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _gotoNext,
                    child: Text(
                      '下个',
                      style: TextStyle(fontSize: 14, color: primaryText),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _onReplacePressed,
                    child: Text(
                      '替换',
                      style: TextStyle(fontSize: 14, color: primaryText),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _replaceVisible ? _replaceAll : null,
                    child: Text(
                      '全部',
                      style: TextStyle(
                        fontSize: 14,
                        color: _replaceVisible
                            ? primaryText
                            : theme.disabledColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _CodeMenu { theme, format, settings, autoWrap, log }
