import 'package:flutter/material.dart';

import '../../widgets/legado_popup_menu.dart';
import 'code_edit_formatter.dart';
import 'code_edit_highlighter.dart';
import '../../services/code_edit_prefs.dart';
import 'code_edit_theme.dart';
import 'keyboard_tool_bar.dart';

/// 代码编辑结果 — 对齐 Jingshiro [CodeEditActivity] `RESULT_OK` extras。
class CodeEditResult {
  const CodeEditResult({required this.text, required this.cursorPosition});

  final String text;
  final int cursorPosition;
}

/// 代码编辑器 — 1:1 对齐 Jingshiro [activity_code_edit.xml] + [CodeEditActivity]。
///
/// Chrome：TitleBar、搜索/保存、溢出菜单、底栏查找替换、键盘辅助条。
/// 语法高亮：轻量 JSON/JS tokenizer，颜色对齐 TextMate Monokai 等主题。
class CodeEditPage extends StatefulWidget {
  const CodeEditPage({
    super.key,
    required this.initialText,
    this.title,
    this.cursorPosition = 0,
    this.writable = true,
    this.languageName,
  });

  final String initialText;
  final String? title;
  final int cursorPosition;
  final bool writable;
  final String? languageName;

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
  late HighlightEditingController _controller;
  late final FocusNode _editorFocus;
  final _findCtrl = TextEditingController();
  final _replaceCtrl = TextEditingController();
  final _findFocus = FocusNode();
  final _replaceFocus = FocusNode();

  late String _initialText;
  bool _ready = false;
  bool _searchVisible = false;
  bool _replaceVisible = false;
  bool _isRegex = true;
  bool _autoWrap = true;
  bool _autoComplete = true;
  bool _themeAuto = true;
  double _fontSize = 18;
  int _themeIndex = 1;
  int _themeLightIndex = 1;
  int _themeDarkIndex = 1;
  int _matchIndex = -1;
  List<TextRange> _matches = const [];

  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _applyingHistory = false;
  @override
  void initState() {
    super.initState();
    _initialText = widget.initialText;
    _controller = HighlightEditingController(
      text: _initialText,
      palette: CodeEditPalette.byIndex(1),
    );
    _editorFocus = FocusNode();
    _controller.addListener(_onTextChanged);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final s = await CodeEditPrefs.load();
    if (!mounted) return;
    final systemDark = Theme.of(context).brightness == Brightness.dark;
    final idx = s.resolveThemeIndex(systemDark: systemDark);
    setState(() {
      _themeLightIndex = s.themeIndex;
      _themeDarkIndex = s.themeDarkIndex;
      _themeAuto = s.themeAuto;
      _themeIndex = idx;
      _fontSize = s.fontScale.toDouble();
      _autoWrap = s.autoWrap;
      _autoComplete = s.autoComplete;
      _controller.palette = CodeEditPalette.byIndex(idx);
      _ready = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pos = widget.cursorPosition.clamp(0, _controller.text.length);
      _controller.selection = TextSelection.collapsed(offset: pos);
      _editorFocus.requestFocus();
    });
  }

  void _onTextChanged() {
    if (_applyingHistory) return;
    final t = _controller.text;
    if (_undoStack.isEmpty || _undoStack.last != t) {
      _undoStack.add(t);
      if (_undoStack.length > 80) _undoStack.removeAt(0);
      _redoStack.clear();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _editorFocus.dispose();
    _findCtrl.dispose();
    _replaceCtrl.dispose();
    _findFocus.dispose();
    _replaceFocus.dispose();
    super.dispose();
  }

  CodeEditPalette get _palette => CodeEditPalette.byIndex(_themeIndex);

  Future<void> _log(String line) async {
    await CodeEditPrefs.appendLog(line);
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
        Navigator.of(
          context,
        ).pop(CodeEditResult(text: text, cursorPosition: cursor));
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
      if (!mounted || cont == true || cont == null) return;
      Navigator.of(context).pop();
      return;
    }

    await _log('保存 ${text.length} 字符');
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(CodeEditResult(text: text, cursorPosition: cursor));
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
        while (true) {
          final i = text.indexOf(query, from);
          if (i < 0) break;
          ranges.add(TextRange(start: i, end: i + query.length));
          from = i + query.length;
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
    final next = _controller.text.replaceRange(r.start, r.end, repl);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: r.start + repl.length),
    );
    _runSearch(_findCtrl.text);
  }

  void _replaceAll() {
    if (_matches.isEmpty || _findCtrl.text.isEmpty) return;
    String next;
    try {
      if (_isRegex) {
        next = _controller.text.replaceAll(
          RegExp(_findCtrl.text),
          _replaceCtrl.text,
        );
      } else {
        next = _controller.text.replaceAll(_findCtrl.text, _replaceCtrl.text);
      }
    } on FormatException {
      return;
    }
    _controller.text = next;
    _runSearch(_findCtrl.text);
  }

  Future<void> _formatCode() async {
    final text = _controller.text;
    try {
      final pretty = CodeEditFormatter.format(
        text,
        languageName: widget.languageName,
      );
      _controller.text = pretty;
      await _log('格式化成功');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已格式化')));
      }
    } on FormatSkipException catch (e) {
      await _log(e.message);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      await _log('格式化失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('格式化失败: $e')));
      }
    }
  }

  Future<void> _showThemePicker() async {
    var auto = _themeAuto;
    var light = _themeLightIndex;
    var dark = _themeDarkIndex;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final systemDark = Theme.of(ctx).brightness == Brightness.dark;
          final active = auto && systemDark ? dark : light;
          return AlertDialog(
            title: const Text('选择主题'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('跟随系统深色'),
                    value: auto,
                    onChanged: (v) => setLocal(() => auto = v),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: CodeEditPalette.names.length,
                      itemBuilder: (_, i) {
                        return ListTile(
                          title: Text(CodeEditPalette.names[i]),
                          trailing: i == active
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(ctx).colorScheme.primary,
                                )
                              : null,
                          onTap: () => setLocal(() {
                            if (auto && systemDark) {
                              dark = i;
                            } else {
                              light = i;
                            }
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  await CodeEditPrefs.saveThemeAuto(auto);
                  await CodeEditPrefs.saveTheme(light, dark: false);
                  await CodeEditPrefs.saveTheme(dark, dark: true);
                  if (!mounted) return;
                  final sysDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final idx = auto && sysDark ? dark : light;
                  setState(() {
                    _themeAuto = auto;
                    _themeLightIndex = light;
                    _themeDarkIndex = dark;
                    _themeIndex = idx;
                    _controller.palette = CodeEditPalette.byIndex(idx);
                  });
                  await _log('主题 → ${CodeEditPalette.names[idx]}');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showSettings() async {
    var font = _fontSize;
    var wrap = _autoWrap;
    var complete = _autoComplete;
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
                  Text('字号 ${font.round()}'),
                  Expanded(
                    child: Slider(
                      value: font,
                      min: 9,
                      max: 36,
                      divisions: 27,
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
              SwitchListTile(
                title: const Text('自动补全'),
                value: complete,
                onChanged: (v) => setLocal(() => complete = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () async {
                await CodeEditPrefs.saveFontScale(font.round());
                await CodeEditPrefs.saveAutoWrap(wrap);
                await CodeEditPrefs.saveAutoComplete(complete);
                if (!mounted) return;
                setState(() {
                  _fontSize = font;
                  _autoWrap = wrap;
                  _autoComplete = complete;
                });
                await _log('设置 字号=${font.round()} 换行=$wrap');
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAutoWrap() async {
    final next = !_autoWrap;
    setState(() => _autoWrap = next);
    await CodeEditPrefs.saveAutoWrap(next);
    await _log('自动换行 → $next');
  }

  Future<void> _showLog() async {
    final logs = await CodeEditPrefs.loadLog();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('日志'),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: logs.isEmpty
              ? const Text('暂无日志', style: TextStyle(fontFamily: 'monospace'))
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (_, i) => Text(
                    logs[logs.length - 1 - i],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await CodeEditPrefs.clearLog();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('清空'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _undo() {
    if (_undoStack.length < 2) return;
    _applyingHistory = true;
    final current = _undoStack.removeLast();
    _redoStack.add(current);
    final prev = _undoStack.last;
    _controller.value = TextEditingValue(
      text: prev,
      selection: TextSelection.collapsed(offset: prev.length),
    );
    _applyingHistory = false;
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _applyingHistory = true;
    final next = _redoStack.removeLast();
    _undoStack.add(next);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _applyingHistory = false;
  }

  void _sendText(String text) {
    final focus = FocusManager.instance.primaryFocus;
    // 查找/替换框优先
    if (_findFocus.hasFocus) {
      _insertInto(_findCtrl, text);
      _runSearch(_findCtrl.text);
      return;
    }
    if (_replaceFocus.hasFocus) {
      _insertInto(_replaceCtrl, text);
      return;
    }
    if (focus == null || _editorFocus.hasFocus || focus == _editorFocus) {
      _insertInto(_controller, text);
      return;
    }
    _insertInto(_controller, text);
  }

  void _insertInto(TextEditingController c, String text) {
    final value = c.value;
    final start = value.selection.start < 0
        ? value.text.length
        : value.selection.start;
    final end = value.selection.end < 0
        ? value.text.length
        : value.selection.end;
    final s = start <= end ? start : end;
    final e = start <= end ? end : start;
    final next = value.text.replaceRange(s, e, text);
    c.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: s + text.length),
    );
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('书源教程'),
              onTap: () {
                Navigator.pop(ctx);
                _log('帮助: 书源教程');
              },
            ),
            ListTile(
              title: const Text('js教程'),
              onTap: () {
                Navigator.pop(ctx);
                _log('帮助: js教程');
              },
            ),
            ListTile(
              title: const Text('正则教程'),
              onTap: () {
                Navigator.pop(ctx);
                _log('帮助: 正则教程');
              },
            ),
          ],
        ),
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
    final palette = _palette;
    final cardBg = theme.colorScheme.surfaceContainerLow;

    if (!_ready) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            (widget.title?.trim().isNotEmpty == true)
                ? widget.title!.trim()
                : '编辑代码',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
              offset: legadoAppBarPopupOffset(context),
              onSelected: (item) {
                switch (item) {
                  case _CodeMenu.theme:
                    _showThemePicker();
                  case _CodeMenu.format:
                    _formatCode();
                  case _CodeMenu.settings:
                    _showSettings();
                  case _CodeMenu.autoWrap:
                    _toggleAutoWrap();
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
                const PopupMenuItem(value: _CodeMenu.log, child: Text('日志')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: palette.background,
                child: _buildEditor(palette, theme),
              ),
            ),
            // 对齐 KeyboardToolPop：片段芯片（桌面无 IME 时仍常驻便于操作）
            if (widget.writable)
              KeyboardToolBar(
                onSendText: _sendText,
                onUndo: _undo,
                onRedo: _redo,
                onHelp: _showHelp,
              ),
            if (_searchVisible) _buildSearchGroup(cardBg, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(CodeEditPalette palette, ThemeData theme) {
    final style = TextStyle(
      fontFamily: 'monospace',
      fontSize: _fontSize,
      height: 1.45,
      color: palette.foreground,
    );
    final field = TextField(
      controller: _controller,
      focusNode: _editorFocus,
      readOnly: !widget.writable,
      maxLines: null,
      expands: _autoWrap,
      textAlignVertical: TextAlignVertical.top,
      style: style,
      cursorColor: palette.keyword,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(12),
      ),
      keyboardType: TextInputType.multiline,
    );
    if (_autoWrap) return field;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.sizeOf(context).width,
          minHeight: MediaQuery.sizeOf(context).height * 0.4,
        ),
        child: IntrinsicWidth(
          child: TextField(
            controller: _controller,
            focusNode: _editorFocus,
            readOnly: !widget.writable,
            maxLines: null,
            style: style,
            cursorColor: palette.keyword,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            keyboardType: TextInputType.multiline,
          ),
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
                Text(
                  '搜索结果:',
                  style: TextStyle(fontSize: 14, color: primaryText),
                ),
                const SizedBox(width: 8),
                Text(
                  _searchResultLabel,
                  style: TextStyle(fontSize: 14, color: primaryText),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '正则',
                      style: TextStyle(fontSize: 14, color: primaryText),
                    ),
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
                  Text(
                    '替换',
                    style: TextStyle(fontSize: 14, color: primaryText),
                  ),
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
