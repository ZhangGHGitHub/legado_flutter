import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/preferences/source_variable_port.dart';
import '../../application/preferences/code_edit_prefs_port.dart';
import '../../application/platform/clipboard_port.dart';
import '../../application/qr/qr_code_port.dart';
import '../../application/source_login/source_login_cookie_clear_port.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import '../../providers/source_provider.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/legado_popup_menu.dart';
import '../code_edit/code_edit_page.dart';
import '../code_edit/keyboard_tool_bar.dart';
import 'qrcode_capture_page.dart';
import '../search/search_page.dart';
import 'rule_complete.dart';
import 'source_debug_page.dart';
import 'source_login_page.dart';

/// 书源规则编辑 — 1:1 对齐 Jingshiro 截图 + [BookSourceEditActivity] /
/// [activity_book_source_edit.xml] + [item_source_edit.xml] + [menu/source_edit.xml]。
///
/// Chrome：TitleBar「编辑书源」；类型/启用/发现/CookieJar/事件监听/定制按钮在 Tab 上方；
/// Tab：基本 | 搜索 | 发现 | 详情 | 目录 | 正文；红标签+底线输入；菜单对齐 source_edit。
class SourceEditorPage extends StatefulWidget {
  final BookSource source;

  const SourceEditorPage({super.key, required this.source});

  @override
  State<SourceEditorPage> createState() => _SourceEditorPageState();
}

class _EditField {
  _EditField(this.key, this.hint, [String? initial])
    : controller = TextEditingController(text: initial ?? ''),
      focus = FocusNode();

  final String key;
  final String hint;
  final TextEditingController controller;
  final FocusNode focus;

  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

class _SourceEditorPageState extends State<SourceEditorPage>
    with SingleTickerProviderStateMixin {
  static const _bookTypes = ['文本', '音频', '图片', '文件', '视频'];
  static const _tabs = ['基本', '搜索', '发现', '详情', '目录', '正文'];
  late TabController _tabController;
  late String _originalJson;

  int _bookTypeIndex = 0;
  bool _enabled = true;
  bool _enabledExplore = true;
  bool _enabledCookieJar = true;
  bool _eventListener = false;
  bool _customButton = false;
  bool _autoComplete = true;
  bool _isSaving = false;
  bool _applyingHistory = false;

  /// 每字段撤销栈（对齐 KeyboardToolPop 撤销/重做）
  final Map<String, List<String>> _undoStacks = {};
  final Map<String, List<String>> _redoStacks = {};

  late List<_EditField> _baseFields;
  late List<_EditField> _searchFields;
  late List<_EditField> _exploreFields;
  late List<_EditField> _infoFields;
  late List<_EditField> _tocFields;
  late List<_EditField> _contentFields;

  List<_EditField> get _allFields => [
    ..._baseFields,
    ..._searchFields,
    ..._exploreFields,
    ..._infoFields,
    ..._tocFields,
    ..._contentFields,
  ];

  List<_EditField> get _currentFields {
    switch (_tabController.index) {
      case 1:
        return _searchFields;
      case 2:
        return _exploreFields;
      case 3:
        return _infoFields;
      case 4:
        return _tocFields;
      case 5:
        return _contentFields;
      default:
        return _baseFields;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _initFromSource(widget.source);
    _originalJson = _encodeCurrent();
    _seedHistory();
    _loadAutoComplete();
  }

  Future<void> _loadAutoComplete() async {
    final prefs = context.read<CodeEditPrefsPort>();
    final s = await prefs.load();
    if (!mounted) return;
    setState(() => _autoComplete = s.autoComplete);
  }

  void _seedHistory() {
    for (final f in _allFields) {
      _undoStacks[f.key] = [f.controller.text];
      _redoStacks[f.key] = [];
      f.focus.removeListener(_onFieldFocusChange);
      f.focus.addListener(_onFieldFocusChange);
    }
  }

  void _onFieldFocusChange() {
    if (mounted) setState(() {});
  }

  void _pushHistory(_EditField field) {
    if (_applyingHistory) return;
    final stack = _undoStacks.putIfAbsent(field.key, () => []);
    final text = field.controller.text;
    if (stack.isEmpty || stack.last != text) {
      stack.add(text);
      if (stack.length > 40) stack.removeAt(0);
      _redoStacks[field.key]?.clear();
    }
  }

  void _initFromSource(BookSource source) {
    final map = _parseMap(source);

    _bookTypeIndex = _typeToIndex(map['bookSourceType']);
    _enabled = map['enabled'] != false;
    _enabledExplore = map['enabledExplore'] != false;
    // Jingshiro: enabledCookieJar ?: false
    _enabledCookieJar = map['enabledCookieJar'] == true;
    _eventListener = map['eventListener'] == true;
    _customButton = map['customButton'] == true;

    final sr = _asMap(map['ruleSearch']);
    final er = _asMap(map['ruleExplore']);
    final ir = _asMap(map['ruleBookInfo']);
    final tr = _asMap(map['ruleToc']);
    final cr = _asMap(map['ruleContent']);

    _baseFields = [
      _EditField(
        'bookSourceUrl',
        '源 URL（sourceUrl）',
        _str(map, 'bookSourceUrl'),
      ),
      _EditField(
        'bookSourceName',
        '源名称（sourceName）',
        _str(map, 'bookSourceName'),
      ),
      _EditField(
        'bookSourceGroup',
        '源分组（sourceGroup）',
        _str(map, 'bookSourceGroup'),
      ),
      _EditField(
        'bookSourceComment',
        '源注释（sourceComment）',
        _str(map, 'bookSourceComment'),
      ),
      _EditField('loginUrl', '登录 URL(loginUrl)', _str(map, 'loginUrl')),
      _EditField('loginUi', '登录 UI（loginUi）', _loginUiStr(map)),
      _EditField(
        'loginCheckJs',
        '登录检查 JS（loginCheckJs）',
        _str(map, 'loginCheckJs'),
      ),
      _EditField(
        'coverDecodeJs',
        '封面解密（coverDecodeJs）',
        _str(map, 'coverDecodeJs'),
      ),
      _EditField(
        'bookUrlPattern',
        '书籍 URL 正则（bookUrlPattern）',
        _str(map, 'bookUrlPattern').isNotEmpty
            ? _str(map, 'bookUrlPattern')
            : source.ruleBookUrlPattern,
      ),
      _EditField('header', '请求头（header）', _headerStr(map)),
      _EditField(
        'variableComment',
        '变量说明(variableComment)',
        _str(map, 'variableComment'),
      ),
      _EditField(
        'concurrentRate',
        '并发率（concurrentRate）',
        _str(map, 'concurrentRate'),
      ),
      _EditField('jsLib', 'jsLib', _jsLibStr(map)),
    ];

    _searchFields = [
      _EditField(
        'searchUrl',
        '搜索地址（url）',
        _str(map, 'searchUrl').isNotEmpty
            ? _str(map, 'searchUrl')
            : source.ruleSearchUrl,
      ),
      _EditField(
        'checkKeyWord',
        '校验关键字（checkKeyWord）',
        _str(sr, 'checkKeyWord'),
      ),
      _EditField(
        'bookList',
        '书籍列表规则（bookList）',
        _str(sr, 'bookList').isNotEmpty
            ? _str(sr, 'bookList')
            : source.ruleSearchList,
      ),
      _EditField(
        'name',
        '书名规则（name）',
        _str(sr, 'name').isNotEmpty ? _str(sr, 'name') : source.ruleSearchName,
      ),
      _EditField(
        'author',
        '作者规则（author）',
        _str(sr, 'author').isNotEmpty
            ? _str(sr, 'author')
            : source.ruleSearchAuthor,
      ),
      _EditField(
        'kind',
        '分类规则（kind）',
        _str(sr, 'kind').isNotEmpty ? _str(sr, 'kind') : source.ruleSearchKind,
      ),
      _EditField('wordCount', '字数规则（wordCount）', _str(sr, 'wordCount')),
      _EditField('lastChapter', '最新章节规则（lastChapter）', _str(sr, 'lastChapter')),
      _EditField(
        'intro',
        '简介规则（intro）',
        _str(sr, 'intro').isNotEmpty
            ? _str(sr, 'intro')
            : source.ruleSearchNote,
      ),
      _EditField(
        'coverUrl',
        '封面规则（coverUrl）',
        _str(sr, 'coverUrl').isNotEmpty
            ? _str(sr, 'coverUrl')
            : source.ruleSearchCoverUrl,
      ),
      _EditField('bookUrl', '详情页 URL 规则（bookUrl）', _str(sr, 'bookUrl')),
    ];

    _exploreFields = [
      _EditField('exploreUrl', '发现地址规则（url）', _str(map, 'exploreUrl')),
      _EditField('bookList', '书籍列表规则（bookList）', _str(er, 'bookList')),
      _EditField('name', '书名规则（name）', _str(er, 'name')),
      _EditField('author', '作者规则（author）', _str(er, 'author')),
      _EditField('kind', '分类规则（kind）', _str(er, 'kind')),
      _EditField('wordCount', '字数规则（wordCount）', _str(er, 'wordCount')),
      _EditField('lastChapter', '最新章节规则（lastChapter）', _str(er, 'lastChapter')),
      _EditField('intro', '简介规则（intro）', _str(er, 'intro')),
      _EditField('coverUrl', '封面规则（coverUrl）', _str(er, 'coverUrl')),
      _EditField('bookUrl', '详情页 URL 规则（bookUrl）', _str(er, 'bookUrl')),
    ];

    _infoFields = [
      _EditField('init', '预处理规则（bookInfoInit）', _str(ir, 'init')),
      _EditField(
        'name',
        '书名规则（name）',
        _str(ir, 'name').isNotEmpty ? _str(ir, 'name') : source.ruleBookName,
      ),
      _EditField(
        'author',
        '作者规则（author）',
        _str(ir, 'author').isNotEmpty
            ? _str(ir, 'author')
            : source.ruleBookAuthor,
      ),
      _EditField('kind', '分类规则（kind）', _str(ir, 'kind')),
      _EditField('wordCount', '字数规则（wordCount）', _str(ir, 'wordCount')),
      _EditField(
        'lastChapter',
        '最新章节规则（lastChapter）',
        _str(ir, 'lastChapter').isNotEmpty
            ? _str(ir, 'lastChapter')
            : source.ruleBookLastChapter,
      ),
      _EditField(
        'intro',
        '简介规则（intro）',
        _str(ir, 'intro').isNotEmpty ? _str(ir, 'intro') : source.ruleBookNote,
      ),
      _EditField(
        'coverUrl',
        '封面规则（coverUrl）',
        _str(ir, 'coverUrl').isNotEmpty
            ? _str(ir, 'coverUrl')
            : source.ruleBookCoverUrl,
      ),
      _EditField('tocUrl', '目录 URL 规则（tocUrl）', _str(ir, 'tocUrl')),
      _EditField('canReName', '允许修改书名作者（canReName）', _str(ir, 'canReName')),
      _EditField(
        'downloadUrls',
        '下载URL规则(downloadUrls)',
        _str(ir, 'downloadUrls'),
      ),
    ];

    _tocFields = [
      _EditField(
        'preUpdateJs',
        '更新之前 JS（preUpdateJs）',
        _str(tr, 'preUpdateJs'),
      ),
      _EditField(
        'chapterList',
        '目录列表规则（chapterList）',
        _str(tr, 'chapterList').isNotEmpty
            ? _str(tr, 'chapterList')
            : source.ruleChapterList,
      ),
      _EditField(
        'chapterName',
        '章节名称规则（ChapterName）',
        _str(tr, 'chapterName').isNotEmpty
            ? _str(tr, 'chapterName')
            : source.ruleChapterName,
      ),
      _EditField(
        'chapterUrl',
        '章节 URL 规则（chapterUrl）',
        _str(tr, 'chapterUrl').isNotEmpty
            ? _str(tr, 'chapterUrl')
            : source.ruleChapterUrl,
      ),
      _EditField('formatJs', '格式化规则(formatJs)', _str(tr, 'formatJs')),
      _EditField('isVolume', 'Volume 标识（isVolume）', _str(tr, 'isVolume')),
      _EditField('updateTime', '章节信息（ChapterInfo）', _str(tr, 'updateTime')),
      _EditField('isVip', 'VIP 标识（isVip）', _str(tr, 'isVip')),
      _EditField('isPay', '购买标识（isPay）', _str(tr, 'isPay')),
      _EditField('nextTocUrl', '目录下一页规则（nextTocUrl）', _str(tr, 'nextTocUrl')),
    ];

    // 字段顺序对齐 BookSourceEditActivity.contentEntities
    _contentFields = [
      _EditField(
        'content',
        '正文规则（content）',
        _str(cr, 'content').isNotEmpty
            ? _str(cr, 'content')
            : source.ruleContent,
      ),
      _EditField(
        'nextContentUrl',
        '正文下一页 URL 规则（nextContentUrl）',
        _str(cr, 'nextContentUrl'),
      ),
      _EditField('subContent', '副文规则（subContent）', _str(cr, 'subContent')),
      _EditField(
        'replaceRegex',
        '替换规则（replaceRegex）',
        _str(cr, 'replaceRegex').isNotEmpty
            ? _str(cr, 'replaceRegex')
            : source.ruleContentRemove,
      ),
      _EditField('title', '章节名称规则（ChapterName）', _str(cr, 'title')),
      _EditField('sourceRegex', '资源正则（sourceRegex）', _str(cr, 'sourceRegex')),
      _EditField('imageStyle', '图片样式（imageStyle）', _str(cr, 'imageStyle')),
      _EditField('imageDecode', '图片解密（imageDecode）', _str(cr, 'imageDecode')),
      _EditField('webJs', 'WebView JS（webJs）', _str(cr, 'webJs')),
      _EditField('payAction', '购买操作（payAction）', _str(cr, 'payAction')),
      _EditField('callBackJs', '回调操作（callBackJs）', _str(cr, 'callBackJs')),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final f in _allFields) {
      f.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _parseMap(BookSource source) {
    if (source.rawSourceJson.isNotEmpty) {
      try {
        final o = jsonDecode(source.rawSourceJson);
        if (o is Map) {
          return Map<String, dynamic>.from(o);
        }
      } catch (_) {}
    }
    return Map<String, dynamic>.from(source.toJson());
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) {
      return Map<String, dynamic>.from(v);
    }
    return {};
  }

  static String _str(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v == null) return '';
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    try {
      return const JsonEncoder().convert(v);
    } catch (_) {
      return v.toString();
    }
  }

  static String _loginUiStr(Map<String, dynamic> map) {
    final v = map['loginUi'];
    if (v is String) return v;
    if (v is List || v is Map) {
      try {
        return const JsonEncoder.withIndent('  ').convert(v);
      } catch (_) {}
    }
    return '';
  }

  static String _headerStr(Map<String, dynamic> map) {
    final v = map['header'];
    if (v is String) return v;
    if (v is Map) {
      try {
        return const JsonEncoder.withIndent('  ').convert(v);
      } catch (_) {}
    }
    return '';
  }

  static String _jsLibStr(Map<String, dynamic> map) {
    final v = map['jsLib'];
    if (v is String) return v;
    if (v is Map) {
      try {
        return const JsonEncoder.withIndent('  ').convert(v);
      } catch (_) {}
    }
    return '';
  }

  static int _typeToIndex(dynamic type) {
    final n = type is int ? type : int.tryParse(type?.toString() ?? '') ?? 0;
    if (n >= 0 && n <= 4) return n;
    return 0;
  }

  String? _blankToNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  Map<String, dynamic> _buildMap() {
    final map = _parseMap(widget.source);

    map['bookSourceType'] = _bookTypeIndex;
    map['enabled'] = _enabled;
    map['enabledExplore'] = _enabledExplore;
    map['enabledCookieJar'] = _enabledCookieJar;
    map['eventListener'] = _eventListener;
    map['customButton'] = _customButton;

    for (final f in _baseFields) {
      final v = _blankToNull(f.controller.text);
      switch (f.key) {
        case 'bookSourceUrl':
          map['bookSourceUrl'] = v ?? '';
        case 'bookSourceName':
          map['bookSourceName'] = v ?? '';
        case 'bookSourceGroup':
          map['bookSourceGroup'] = v;
        case 'bookSourceComment':
          map['bookSourceComment'] = v;
        case 'loginUrl':
          map['loginUrl'] = v;
        case 'loginUi':
          map['loginUi'] = v;
        case 'loginCheckJs':
          map['loginCheckJs'] = v;
        case 'coverDecodeJs':
          map['coverDecodeJs'] = v;
        case 'bookUrlPattern':
          map['bookUrlPattern'] = v;
        case 'header':
          map['header'] = v;
        case 'variableComment':
          map['variableComment'] = v;
        case 'concurrentRate':
          map['concurrentRate'] = v;
        case 'jsLib':
          map['jsLib'] = v;
      }
    }

    String? searchUrl;
    final searchRule = <String, dynamic>{};
    for (final f in _searchFields) {
      final v = _blankToNull(f.controller.text);
      if (f.key == 'searchUrl') {
        searchUrl = v;
      } else if (v != null) {
        searchRule[f.key] = v;
      }
    }
    map['searchUrl'] = searchUrl;
    map['ruleSearch'] = searchRule;

    String? exploreUrl;
    final exploreRule = <String, dynamic>{};
    for (final f in _exploreFields) {
      final v = _blankToNull(f.controller.text);
      if (f.key == 'exploreUrl') {
        exploreUrl = v;
      } else if (v != null) {
        exploreRule[f.key] = v;
      }
    }
    map['exploreUrl'] = exploreUrl;
    map['ruleExplore'] = exploreRule;

    final infoRule = <String, dynamic>{};
    for (final f in _infoFields) {
      final v = _blankToNull(f.controller.text);
      if (v != null) infoRule[f.key] = v;
    }
    map['ruleBookInfo'] = infoRule;

    final tocRule = <String, dynamic>{};
    for (final f in _tocFields) {
      final v = _blankToNull(f.controller.text);
      if (v != null) tocRule[f.key] = v;
    }
    map['ruleToc'] = tocRule;

    final contentRule = <String, dynamic>{};
    for (final f in _contentFields) {
      final v = _blankToNull(f.controller.text);
      if (v != null) contentRule[f.key] = v;
    }
    map['ruleContent'] = contentRule;

    // 清理旧扁平字段，避免与嵌套规则冲突
    for (final k in [
      'ruleSearchUrl',
      'ruleSearchList',
      'ruleSearchName',
      'ruleSearchAuthor',
      'ruleSearchCoverUrl',
      'ruleSearchKind',
      'ruleSearchNote',
      'ruleChapterList',
      'ruleChapterName',
      'ruleChapterUrl',
      'ruleContentUrl',
      'ruleContentRemove',
      'ruleBookName',
      'ruleBookAuthor',
      'ruleBookCoverUrl',
    ]) {
      map.remove(k);
    }

    return map;
  }

  String _encodeCurrent() {
    try {
      return const JsonEncoder.withIndent('  ').convert(_buildMap());
    } catch (_) {
      return jsonEncode(_buildMap());
    }
  }

  bool _isDirty() => _encodeCurrent() != _originalJson;

  BookSource _toBookSource() {
    final map = _buildMap();
    final raw = const JsonEncoder().convert(map);
    map['rawSourceJson'] = raw;
    return BookSource.fromJson(map);
  }

  _EditField? _focusedField() {
    for (final f in _allFields) {
      if (f.focus.hasFocus) return f;
    }
    return null;
  }

  Future<void> _openCodeEdit() async {
    final field = _focusedField();
    if (field == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请将光标聚焦在文本框')));
      return;
    }
    final sel = field.controller.selection;
    final cursor = sel.isValid ? sel.baseOffset : field.controller.text.length;
    final result = await CodeEditPage.open(
      context,
      text: field.controller.text,
      title: field.hint,
      cursorPosition: cursor.clamp(0, field.controller.text.length),
      languageName: 'source.js',
    );
    if (!mounted || result == null) return;
    field.controller.value = TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(
        offset: result.cursorPosition.clamp(0, result.text.length),
      ),
    );
    setState(() {});
  }

  Future<BookSource?> _save({bool popOnSuccess = false}) async {
    setState(() => _isSaving = true);
    try {
      final updated = _toBookSource();
      if (updated.bookSourceUrl.trim().isEmpty ||
          updated.bookSourceName.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('源 URL 与源名称不能为空')));
        }
        return null;
      }
      await context.read<SourceProvider>().updateSource(updated);
      _originalJson = _encodeCurrent();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('书源已保存')));
        if (popOnSuccess) Navigator.of(context).pop(true);
      }
      return updated;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
      return null;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _debugSource() async {
    final saved = await _save();
    if (!mounted || saved == null) return;
    await SourceDebugPage.open(context, saved);
  }

  Future<void> _copySource() async {
    final json = _encodeCurrent();
    await context.read<ClipboardPort>().copyText(json);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已拷贝源')));
  }

  Future<void> _pasteSource() async {
    final text =
        (await context.read<ClipboardPort>().pasteText())?.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('剪贴板为空')));
      return;
    }
    try {
      final decoded = jsonDecode(text);
      Map<String, dynamic> map;
      if (decoded is Map) {
        map = Map<String, dynamic>.from(decoded);
      } else if (decoded is List &&
          decoded.isNotEmpty &&
          decoded.first is Map) {
        map = Map<String, dynamic>.from(decoded.first as Map);
      } else {
        throw FormatException('不是书源 JSON');
      }
      final source = BookSource.fromJson(map);
      for (final f in _allFields) {
        f.dispose();
      }
      setState(() {
        _initFromSource(source);
        _seedHistory();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('粘贴失败: $e')));
    }
  }

  Future<void> _importQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrCodeCapturePage()),
    );
    if (!mounted || result == null || result.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(result);
      Map<String, dynamic> map;
      if (decoded is Map) {
        map = Map<String, dynamic>.from(decoded);
      } else if (decoded is List &&
          decoded.isNotEmpty &&
          decoded.first is Map) {
        map = Map<String, dynamic>.from(decoded.first as Map);
      } else {
        throw FormatException('二维码内容不是书源 JSON');
      }
      final source = BookSource.fromJson(map);
      for (final f in _allFields) {
        f.dispose();
      }
      setState(() {
        _initFromSource(source);
        _seedHistory();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
  }

  Future<void> _shareStr() async {
    await Share.share(_encodeCurrent(), subject: '分享书源');
  }

  Future<void> _shareQr() async {
    final json = _encodeCurrent();
    final png = context.read<QrCodePort>().encodeToPngBytes(json);
    if (png == null) {
      await Share.share(json, subject: '分享书源');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('内容过长无法生成二维码，已改为字符串分享')));
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('二维码分享'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(png, width: 240, height: 240, fit: BoxFit.contain),
              const SizedBox(height: 8),
              Text('扫描可导入书源', style: Theme.of(ctx).textTheme.bodySmall),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () async {
              final dir = await getTemporaryDirectory();
              final file = File(
                '${dir.path}/legado_source_qr_${DateTime.now().millisecondsSinceEpoch}.png',
              );
              await file.writeAsBytes(png);
              await Share.shareXFiles([XFile(file.path)], subject: '分享书源二维码');
            },
            child: const Text('分享图片'),
          ),
        ],
      ),
    );
  }

  Future<void> _setSourceVariable() async {
    final variablePort = context.read<SourceVariablePort>();
    final saved = await _save();
    if (!mounted || saved == null) return;
    final current = await variablePort.read(saved.bookSourceUrl);
    if (!mounted) return;
    final comment = _baseFields
        .firstWhere(
          (f) => f.key == 'variableComment',
          orElse: () => _EditField('variableComment', ''),
        )
        .controller
        .text
        .trim();
    final ctrl = TextEditingController(text: current);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置源变量'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment.isNotEmpty ? comment : '源变量可在js中通过source.getVariable()获取',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '变量内容',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await variablePort.write(saved.bookSourceUrl, ctrl.text);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('源变量已保存')));
      }
    }
    ctrl.dispose();
  }

  Future<void> _openLogin() async {
    final saved = await _save();
    if (!mounted || saved == null) return;
    await SourceLoginPage.open(context, saved);
  }

  Future<void> _openSearch() async {
    final saved = await _save();
    if (!mounted || saved == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SearchPage(initialRestrictSourceUrls: {saved.bookSourceUrl}),
      ),
    );
  }

  Future<void> _clearCookie() async {
    final prefs = context.read<CodeEditPrefsPort>();
    final cookieClear = context.read<SourceLoginCookieClearPort>();
    try {
      final sourceUrl = _toBookSource().bookSourceUrl.trim();
      if (sourceUrl.isEmpty) throw StateError('源 URL 不能为空');
      await cookieClear.clear(sourceUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已清除 Cookie')));
      await prefs.appendLog('清除书源 Cookie');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('清除失败: $e')));
    }
  }

  void _undo() {
    final field = _focusedField();
    if (field == null) return;
    final stack = _undoStacks[field.key];
    if (stack == null || stack.length < 2) return;
    final current = stack.removeLast();
    _redoStacks.putIfAbsent(field.key, () => []).add(current);
    final prev = stack.last;
    _applyingHistory = true;
    field.controller.value = TextEditingValue(
      text: prev,
      selection: TextSelection.collapsed(offset: prev.length),
    );
    _applyingHistory = false;
    setState(() {});
  }

  void _redo() {
    final field = _focusedField();
    if (field == null) return;
    final redo = _redoStacks[field.key];
    if (redo == null || redo.isEmpty) return;
    final next = redo.removeLast();
    _undoStacks.putIfAbsent(field.key, () => []).add(next);
    _applyingHistory = true;
    field.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _applyingHistory = false;
    setState(() {});
  }

  void _sendText(String snippet) {
    final field = _focusedField();
    if (field == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请将光标聚焦在文本框')));
      return;
    }
    final next = RuleComplete.applySnippet(field.controller.value, snippet);
    _pushHistory(field);
    field.controller.value = next;
    _pushHistory(field);
    setState(() {});
  }

  List<KeyboardAssistItem> _ruleSuggestions() {
    if (!_autoComplete) return const [];
    final field = _focusedField();
    if (field == null) return const [];
    final sel = field.controller.selection;
    final cursor = sel.isValid ? sel.baseOffset : field.controller.text.length;
    final token = RuleComplete.currentToken(field.controller.text, cursor);
    return RuleComplete.suggestions(token);
  }

  Future<bool> _confirmExit() async {
    if (!_isDirty()) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出'),
        content: const Text('尚未保存，是否继续编辑'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('是'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('否'),
          ),
        ],
      ),
    );
    // 「是」= 继续编辑 → 不退出；「否」= 放弃退出
    return result == false;
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('帮助'),
        content: const SingleChildScrollView(
          child: Text(
            '书源规则编写说明（对齐 Legado ruleHelp）：\n\n'
            '• 基本：源 URL、名称、分组、登录、请求头、jsLib、并发率等\n'
            '• 搜索/发现：searchUrl / exploreUrl 与列表字段规则\n'
            '• 详情/目录/正文：bookInfo / toc / content 规则\n'
            '• 常用前缀：@css: @XPath: @Json: @Regex: <js></js>\n'
            '• 组合：|| 备选、&& 合并、%% 交错、## 正则替换\n'
            '• 底栏键盘条可插入规则片段；开启「自动补全」时按输入前缀提示\n'
            '• 聚焦文本框后点「编辑内容」可全屏代码编辑\n'
            '• 完整教程请参考 Legado 书源文档 / 语雀 Wiki',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLog() async {
    final prefs = context.read<CodeEditPrefsPort>();
    final logs = await prefs.loadLog();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('日志'),
        content: SizedBox(
          width: double.maxFinite,
          child: logs.isEmpty
              ? const Text('暂无编辑会话日志。调试运行日志请打开「调试源」。')
              : SingleChildScrollView(
                  child: SelectableText(
                    logs.join('\n'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
        ),
        actions: [
          if (logs.isNotEmpty)
            TextButton(
              onPressed: () async {
                await prefs.clearLog();
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

  Future<void> _onMenuSelected(String value) async {
    switch (value) {
      case 'login':
        await _openLogin();
      case 'search':
        await _openSearch();
      case 'cookie':
        await _clearCookie();
      case 'auto_complete':
        final prefs = context.read<CodeEditPrefsPort>();
        setState(() => _autoComplete = !_autoComplete);
        await prefs.saveAutoComplete(_autoComplete);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_autoComplete ? '已开启自动补全' : '已关闭自动补全')),
          );
        }
      case 'copy':
        await _copySource();
      case 'paste':
        await _pasteSource();
      case 'variable':
        await _setSourceVariable();
      case 'qr_import':
        await _importQr();
      case 'qr_share':
        await _shareQr();
      case 'str_share':
        await _shareStr();
      case 'log':
        await _showLog();
      case 'help':
        _showHelp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = LegadoTokens.sourceDotRed;
    final loginUrl = _baseFields
        .firstWhere((f) => f.key == 'loginUrl')
        .controller
        .text
        .trim();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmExit()) {
          nav.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          // 截图：棕褐/栗色 TitleBar，跟随主题 primary
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          title: const Text('编辑书源'),
          actions: [
            IconButton(
              icon: const Icon(Icons.code),
              tooltip: '编辑内容',
              onPressed: _openCodeEdit,
            ),
            IconButton(
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.save),
              tooltip: '保存',
              onPressed: _isSaving ? null : () => _save(popOnSuccess: true),
            ),
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: '调试源',
              onPressed: _isSaving ? null : _debugSource,
            ),
            PopupMenuButton<String>(
              offset: legadoAppBarPopupOffset(context),
              onSelected: _onMenuSelected,
              itemBuilder: (ctx) => [
                if (loginUrl.isNotEmpty)
                  const PopupMenuItem(value: 'login', child: Text('登录')),
                const PopupMenuItem(value: 'search', child: Text('搜索')),
                const PopupMenuItem(value: 'cookie', child: Text('清除 Cookie')),
                CheckedPopupMenuItem(
                  value: 'auto_complete',
                  checked: _autoComplete,
                  child: const Text('自动补全'),
                ),
                const PopupMenuItem(value: 'copy', child: Text('拷贝源')),
                const PopupMenuItem(value: 'paste', child: Text('粘贴源')),
                const PopupMenuItem(value: 'variable', child: Text('设置源变量')),
                const PopupMenuItem(value: 'qr_import', child: Text('二维码导入')),
                const PopupMenuItem(value: 'qr_share', child: Text('二维码分享')),
                const PopupMenuItem(value: 'str_share', child: Text('字符串分享')),
                const PopupMenuItem(value: 'log', child: Text('日志')),
                const PopupMenuItem(value: 'help', child: Text('帮助')),
              ],
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sticky header above tabs（activity_book_source_edit.xml）
            Material(
              color: theme.colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      children: [
                        Text(
                          '类型：',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        DropdownButton<int>(
                          value: _bookTypeIndex,
                          underline: const SizedBox.shrink(),
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                          items: [
                            for (var i = 0; i < _bookTypes.length; i++)
                              DropdownMenuItem(
                                value: i,
                                child: Text(_bookTypes[i]),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _bookTypeIndex = v);
                            }
                          },
                        ),
                        _check(
                          '启用',
                          _enabled,
                          accent,
                          (v) => setState(() => _enabled = v),
                        ),
                        _check(
                          '发现',
                          _enabledExplore,
                          accent,
                          (v) => setState(() => _enabledExplore = v),
                        ),
                        _check(
                          'CookieJar',
                          _enabledCookieJar,
                          accent,
                          (v) => setState(() => _enabledCookieJar = v),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                    child: Row(
                      children: [
                        _check(
                          '事件监听',
                          _eventListener,
                          accent,
                          (v) => setState(() => _eventListener = v),
                        ),
                        _check(
                          '定制按钮',
                          _customButton,
                          accent,
                          (v) => setState(() => _customButton = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: theme.colorScheme.surface,
              elevation: 3,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: accent,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: accent,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                tabs: [for (final t in _tabs) Tab(text: t, height: 36)],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _currentFields.length,
                itemBuilder: (_, i) {
                  final field = _currentFields[i];
                  return Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: TextField(
                      controller: field.controller,
                      focusNode: field.focus,
                      maxLines: null,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      cursorColor: accent,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.35,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: field.hint,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelStyle: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        floatingLabelStyle: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.fromLTRB(0, 18, 0, 6),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accent, width: 1.5),
                        ),
                      ),
                      onTap: () => setState(() {}),
                      onChanged: (_) {
                        _pushHistory(field);
                        setState(() {});
                      },
                    ),
                  );
                },
              ),
            ),
            if (_ruleSuggestions().isNotEmpty)
              Material(
                color: theme.colorScheme.surfaceContainerHighest,
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    children: [
                      for (final s in _ruleSuggestions())
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(
                              s.key,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () => _sendText(s.value),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            KeyboardToolBar(
              onSendText: _sendText,
              onUndo: _undo,
              onRedo: _redo,
              onHelp: _showHelp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _check(
    String label,
    bool value,
    Color accent,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          width: 36,
          child: Checkbox(
            value: value,
            activeColor: accent,
            checkColor: Colors.white,
            side: BorderSide(
              color: value ? accent : Theme.of(context).colorScheme.outline,
            ),
            onChanged: (v) => onChanged(v ?? false),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: value ? accent : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
