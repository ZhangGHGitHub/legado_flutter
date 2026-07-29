import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:legado_flutter/domain/source/book_source.dart';
import '../../providers/source_provider.dart';
import '../../services/import_url_history_store.dart';
import '../../services/check_source_prefs.dart';
import '../../services/source_group_tags.dart';
import '../../services/source_manage_help_prefs.dart';
import '../../services/reader_font_loader.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/check_source_keyword_dialog.dart';
import '../../widgets/error_view.dart';
import '../../widgets/import_book_source_dialog.dart';
import '../../widgets/legado_popup_menu.dart';
import '../../widgets/source_group_manage_dialog.dart';
import '../../widgets/source_manage_help_dialog.dart';
import '../../widgets/source_status_dot.dart';
import '../../widgets/source_validation_sheet.dart';
import '../explore/explore_utils.dart';
import 'qrcode_capture_page.dart';
import '../search/search_page.dart';
import 'source_debug_page.dart';
import 'source_editor_page.dart';
import 'source_login_page.dart';
import 'source_market_page.dart';

/// 排序 — 对齐 Jingshiro `menu_group_sort`
enum _SourceSort { manual, auto, name, url, enabled, lastUpdate, respondTime }

/// 书源管理 — 对齐 Jingshiro [BookSourceActivity] /
/// `activity_book_source.xml` + `item_book_source.xml` + `menu/book_source.xml`
class SourcesPage extends StatefulWidget {
  const SourcesPage({super.key});

  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  static const _checkboxLaneWidth = 48.0;
  static const _edgeScrollZone = 48.0;
  static const _edgeScrollStep = 10.0;

  final _searchController = TextEditingController();
  final _listScrollController = ScrollController();
  final _listViewportKey = GlobalKey();
  final _selected = <String>{};
  final _selectBarKey = GlobalKey();
  final _rowKeys = <String, GlobalKey>{};

  _SourceSort _sort = _SourceSort.manual;
  bool _sortDesc = false;

  /// all | enabled | disabled | login | null_group | explore_on | explore_off | group:xxx
  String _filter = 'all';
  bool _groupByDomain = false;
  bool _showDebugMessage = true;

  bool _dragSelectActive = false;
  bool _dragSelectMode = true;
  int? _dragAnchorIndex;
  int? _dragCurrentIndex;
  Set<String>? _dragSelectSnapshot;
  Timer? _dragAutoScrollTimer;
  Offset? _dragLastGlobalPos;
  bool _dragPending = false;
  Offset? _dragStartPos;
  int? _dragPendingIndex;
  List<BookSource>? _dragPendingVisible;

  @override
  void initState() {
    super.initState();
    _loadCheckSourceUiPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoShowHelp());
  }

  Future<void> _loadCheckSourceUiPrefs() async {
    final showDebug = await CheckSourcePrefs.showDebugMessage();
    if (!mounted) return;
    setState(() => _showDebugMessage = showDebug);
  }

  Future<void> _maybeAutoShowHelp() async {
    if (!mounted) return;
    if (!await SourceManageHelpPrefs.shouldAutoShow()) return;
    if (!mounted) return;
    await SourceManageHelpDialog.show(context);
    await SourceManageHelpPrefs.markShown();
  }

  Future<void> _showHelp() async {
    if (!mounted) return;
    await SourceManageHelpDialog.show(context);
    await SourceManageHelpPrefs.markShown();
  }

  @override
  void dispose() {
    _dragAutoScrollTimer?.cancel();
    _listScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  GlobalKey _rowKeyFor(String url) => _rowKeys.putIfAbsent(url, GlobalKey.new);

  void _beginDragSelect(int index, List<BookSource> visible) {
    final url = visible[index].bookSourceUrl;
    _dragSelectActive = true;
    _dragAnchorIndex = index;
    _dragCurrentIndex = index;
    _dragSelectMode = !_selected.contains(url);
    _dragSelectSnapshot = Set<String>.from(_selected);
    _applyDragSelectRange(index, index, visible);
    _startDragAutoScroll(visible);
  }

  void _applyDragSelectRange(
    int anchor,
    int current,
    List<BookSource> visible,
  ) {
    final snapshot = _dragSelectSnapshot;
    if (snapshot == null) return;
    final lo = math.min(anchor, current);
    final hi = math.max(anchor, current);
    setState(() {
      _selected
        ..clear()
        ..addAll(snapshot);
      for (var i = lo; i <= hi; i++) {
        final url = visible[i].bookSourceUrl;
        if (_dragSelectMode) {
          _selected.add(url);
        } else {
          _selected.remove(url);
        }
      }
    });
  }

  void _updateDragSelect(Offset globalPos, List<BookSource> visible) {
    if (!_dragSelectActive || _dragAnchorIndex == null) return;
    _dragLastGlobalPos = globalPos;
    _performEdgeScroll(globalPos.dy);
    final index = _indexAtGlobalY(globalPos.dy, visible);
    if (index == null || index == _dragCurrentIndex) return;
    _dragCurrentIndex = index;
    _applyDragSelectRange(_dragAnchorIndex!, index, visible);
  }

  void _endDragSelect() {
    if (_dragSelectActive) {
      _dragSelectActive = false;
      _dragAnchorIndex = null;
      _dragCurrentIndex = null;
      _dragSelectSnapshot = null;
      _dragLastGlobalPos = null;
      _dragAutoScrollTimer?.cancel();
      _dragAutoScrollTimer = null;
    }
    _dragPending = false;
    _dragStartPos = null;
    _dragPendingIndex = null;
    _dragPendingVisible = null;
  }

  void _onDragPointerUp(List<BookSource> visible) {
    _endDragSelect();
  }

  void _onDragPointerMove(Offset globalPos, List<BookSource> visible) {
    if (_dragPending &&
        _dragStartPos != null &&
        _dragPendingIndex != null &&
        _dragPendingVisible != null) {
      if ((globalPos - _dragStartPos!).distance >= 4) {
        _dragPending = false;
        _beginDragSelect(_dragPendingIndex!, _dragPendingVisible!);
        _updateDragSelect(globalPos, visible);
      }
      return;
    }
    if (_dragSelectActive) _updateDragSelect(globalPos, visible);
  }

  int? _indexAtGlobalY(double globalY, List<BookSource> visible) {
    for (var i = 0; i < visible.length; i++) {
      final ctx = _rowKeys[visible[i].bookSourceUrl]?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      if (globalY >= top && globalY <= bottom) return i;
    }
    return null;
  }

  void _performEdgeScroll(double globalDy) {
    if (!_listScrollController.hasClients) return;
    final viewportCtx = _listViewportKey.currentContext;
    if (viewportCtx == null) return;
    final viewport = viewportCtx.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.hasSize) return;

    final top = viewport.localToGlobal(Offset.zero).dy;
    final bottom = top + viewport.size.height;
    final position = _listScrollController.position;

    double? target;
    if (globalDy < top + _edgeScrollZone) {
      target = (position.pixels - _edgeScrollStep).clamp(
        0.0,
        position.maxScrollExtent,
      );
    } else if (globalDy > bottom - _edgeScrollZone) {
      target = (position.pixels + _edgeScrollStep).clamp(
        0.0,
        position.maxScrollExtent,
      );
    }
    if (target != null && target != position.pixels) {
      _listScrollController.jumpTo(target);
    }
  }

  void _startDragAutoScroll(List<BookSource> visible) {
    _dragAutoScrollTimer?.cancel();
    _dragAutoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      _,
    ) {
      if (!_dragSelectActive) return;
      final pos = _dragLastGlobalPos;
      if (pos == null) return;
      _performEdgeScroll(pos.dy);
      _updateDragSelect(pos, visible);
    });
  }

  Widget _wrapListWithDragSelect(List<BookSource> visible, Widget list) {
    return KeyedSubtree(
      key: _listViewportKey,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (e) => _onDragPointerMove(e.position, visible),
        onPointerUp: (_) => _onDragPointerUp(visible),
        onPointerCancel: (_) => _endDragSelect(),
        child: list,
      ),
    );
  }

  TextStyle _uiText({
    required Color color,
    double size = 14,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: 1.25,
      fontFamily: ReaderFontLoader.platformSansFamily(),
      fontFamilyFallback: ReaderFontLoader.cjkFallbackFamilies(),
    );
  }

  List<BookSource> _visibleSources(List<BookSource> all) {
    var list = List<BookSource>.from(all);

    switch (_filter) {
      case 'enabled':
        list = list.where((s) => s.enabled).toList();
      case 'disabled':
        list = list.where((s) => !s.enabled).toList();
      case 'login':
        list = list.where((s) => s.hasLoginConfig).toList();
      case 'null_group':
        list = list.where((s) => s.bookSourceGroup.trim().isEmpty).toList();
      case 'explore_on':
        list = list
            .where((s) => hasExploreUrl(s) && isExploreEnabled(s))
            .toList();
      case 'explore_off':
        list = list
            .where((s) => hasExploreUrl(s) && !isExploreEnabled(s))
            .toList();
      default:
        if (_filter.startsWith('group:')) {
          final g = _filter.substring(6);
          list = list
              .where((s) => sourceHasGroupTag(s.bookSourceGroup, g))
              .toList();
        }
    }

    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (s) =>
                s.bookSourceName.toLowerCase().contains(q) ||
                s.bookSourceUrl.toLowerCase().contains(q) ||
                s.bookSourceGroup.toLowerCase().contains(q),
          )
          .toList();
    }

    int cmp(BookSource a, BookSource b) {
      final r = switch (_sort) {
        _SourceSort.manual => a.customOrder.compareTo(b.customOrder),
        _SourceSort.auto => a.weight.compareTo(b.weight),
        _SourceSort.name => a.bookSourceName.toLowerCase().compareTo(
          b.bookSourceName.toLowerCase(),
        ),
        _SourceSort.url => a.bookSourceUrl.toLowerCase().compareTo(
          b.bookSourceUrl.toLowerCase(),
        ),
        _SourceSort.enabled => (b.enabled ? 1 : 0).compareTo(a.enabled ? 1 : 0),
        _SourceSort.lastUpdate => a.lastUpdateTime.compareTo(b.lastUpdateTime),
        _SourceSort.respondTime => a.respondTime.compareTo(b.respondTime),
      };
      return _sortDesc ? -r : r;
    }

    list.sort(cmp);
    return list;
  }

  List<String> _allGroups(SourceProvider provider) => provider.knownGroups;

  String _hostOf(BookSource s) {
    final u = Uri.tryParse(s.bookSourceUrl);
    if (u != null && u.host.isNotEmpty) return u.host;
    return '未知域名';
  }

  Widget _buildSearchField(ColorScheme scheme) {
    final onBar = scheme.onPrimary;
    return SizedBox(
      height: 32,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: _uiText(color: onBar),
        cursorColor: onBar,
        decoration: InputDecoration(
          hintText: '搜索书源',
          hintStyle: _uiText(color: onBar.withValues(alpha: 0.72)),
          isDense: true,
          filled: true,
          fillColor: onBar.withValues(alpha: 0.14),
          contentPadding: EdgeInsets.zero,
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: onBar.withValues(alpha: 0.85),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: onBar.withValues(alpha: 0.85),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: onBar.withValues(alpha: 0.28),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  void _setFilter(String filter) {
    setState(() {
      _filter = filter;
      _selected.clear();
    });
  }

  Future<void> _onOverflow(String value) async {
    switch (value) {
      case 'add':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SourceEditorPage(
              source: BookSource(bookSourceUrl: '', bookSourceName: ''),
            ),
          ),
        );
      case 'import_local':
        await _importFromJsonFile(context);
      case 'import_online':
        _showImportUrlDialog(context);
      case 'import_qr':
        await _importFromQr(context);
      case 'group_domain':
        setState(() => _groupByDomain = !_groupByDomain);
        return;
      case 'group_manage':
        await showSourceGroupManageDialog(context);
        return;
      case 'help':
        if (!mounted) return;
        await _showHelp();
        return;
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除书源'),
        content: Text('确定删除选中的 $count 个书源？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<SourceProvider>().deleteSources(_selected);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已删除 $count 个书源')));
    setState(() => _selected.clear());
  }

  Future<void> _batchEnable(bool enabled) async {
    if (_selected.isEmpty) return;
    final n = _selected.length;
    await context.read<SourceProvider>().setSourcesEnabled(_selected, enabled);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(enabled ? '已启用 $n 个书源' : '已禁用 $n 个书源')),
    );
  }

  Future<void> _batchSetGroup() async {
    if (_selected.isEmpty) return;
    final provider = context.read<SourceProvider>();
    final groups = _allGroups(provider);
    final controller = TextEditingController();
    final group = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置分组'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '输入分组名（空=未分组）',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              if (groups.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '已有分组',
                    style: _uiText(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      size: 12,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final g in groups)
                        ListTile(
                          dense: true,
                          title: Text(g),
                          onTap: () => Navigator.pop(ctx, g),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('清除分组'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (group == null || !mounted) return;
    final count = _selected.length;
    if (group.isEmpty) {
      await provider.clearGroupOnSources(_selected);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已清除 $count 个书源分组')));
    } else {
      await provider.setSourcesGroup(_selected, group);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已将 $count 个书源移至「$group」')));
    }
  }

  Future<void> _batchValidateSelected() async {
    if (_selected.isEmpty) return;
    final keyword = await showCheckSourceKeywordDialog(context);
    await _loadCheckSourceUiPrefs();
    if (keyword == null || !mounted) return;
    final provider = context.read<SourceProvider>();
    final selected = provider.sources
        .where((s) => _selected.contains(s.bookSourceUrl))
        .toList();
    if (selected.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BatchValidateDialog(
        provider: provider,
        sources: selected,
        keyword: keyword,
      ),
    );
  }

  Future<void> _batchExploreEnable(bool enabled) async {
    if (_selected.isEmpty) return;
    final n = _selected.length;
    await context.read<SourceProvider>().setSourcesExploreEnabled(
      _selected,
      enabled,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(enabled ? '已启用 $n 个书源发现' : '已禁用 $n 个书源发现')),
    );
  }

  Future<void> _batchAddGroup() async {
    if (_selected.isEmpty) return;
    final controller = TextEditingController();
    final group = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加分组'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入分组名',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final g = controller.text.trim();
              if (g.isEmpty) return;
              Navigator.pop(ctx, g);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (group == null || group.isEmpty || !mounted) return;
    final n = _selected.length;
    await context.read<SourceProvider>().addGroupToSources(_selected, group);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已将 $n 个书源添加至「$group」')));
  }

  Future<void> _batchRemoveGroup() async {
    if (_selected.isEmpty) return;
    final provider = context.read<SourceProvider>();
    final tags = <String>{};
    for (final s in provider.sources) {
      if (!_selected.contains(s.bookSourceUrl)) continue;
      tags.addAll(splitSourceGroups(s.bookSourceGroup));
    }
    if (tags.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('所选书源没有分组标签')));
      return;
    }
    final sortedTags = tags.toList()..sort();
    const clearAll = '__clear_all__';
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移除分组'),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final g in sortedTags)
                  ListTile(
                    dense: true,
                    title: Text(g),
                    onTap: () => Navigator.pop(ctx, g),
                  ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  title: const Text('清除全部分组'),
                  onTap: () => Navigator.pop(ctx, clearAll),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    final n = _selected.length;
    if (choice == clearAll) {
      await provider.clearGroupOnSources(_selected);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已清除 $n 个书源的全部分组')));
    } else {
      final withTag = provider.sources
          .where(
            (s) =>
                _selected.contains(s.bookSourceUrl) &&
                sourceHasGroupTag(s.bookSourceGroup, choice),
          )
          .length;
      await provider.removeGroupTagFromSources(_selected, choice);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已从 $withTag 个书源移除「$choice」')));
    }
  }

  Future<void> _batchMoveToTop() async {
    if (_selected.isEmpty) return;
    await context.read<SourceProvider>().moveSourcesToTop(_selected);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已将 ${_selected.length} 个书源置顶')));
  }

  Future<void> _batchMoveToBottom() async {
    if (_selected.isEmpty) return;
    await context.read<SourceProvider>().moveSourcesToBottom(_selected);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已将 ${_selected.length} 个书源置底')));
  }

  Future<void> _exportSelected() async {
    if (_selected.isEmpty) return;
    final provider = context.read<SourceProvider>();
    final json = await provider.exportSourcesJson(_selected);
    final bytes = utf8.encode(json);
    try {
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: '导出书源',
        fileName: 'bookSource.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      if (!mounted) return;
      if (saved == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已取消导出')));
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('书源导出成功')));
    } catch (_) {
      await Share.share(json, subject: '书源');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前平台不支持保存文件，已改为分享')));
    }
  }

  Future<void> _shareSelected() async {
    if (_selected.isEmpty) return;
    final json = await context.read<SourceProvider>().exportSourcesJson(
      _selected,
    );
    try {
      await Share.share(json, subject: '书源');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _onBottomMore(String value) async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择书源')));
      return;
    }
    switch (value) {
      case 'enable':
        await _batchEnable(true);
      case 'disable':
        await _batchEnable(false);
      case 'explore_enable':
        await _batchExploreEnable(true);
      case 'explore_disable':
        await _batchExploreEnable(false);
      case 'group':
        await _batchSetGroup();
      case 'add_group':
        await _batchAddGroup();
      case 'remove_group':
        await _batchRemoveGroup();
      case 'top':
        await _batchMoveToTop();
      case 'bottom':
        await _batchMoveToBottom();
      case 'export':
        await _exportSelected();
      case 'share':
        await _shareSelected();
      case 'validate':
        await _batchValidateSelected();
    }
  }

  void _showItemMenu(BookSource source, Offset anchor) {
    final provider = context.read<SourceProvider>();
    final manual = _sort == _SourceSort.manual;
    final explore = hasExploreUrl(source);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        anchor.dx,
        anchor.dy,
        anchor.dx,
        anchor.dy,
      ),
      items: [
        if (manual) const PopupMenuItem(value: 'top', child: Text('置顶')),
        if (manual) const PopupMenuItem(value: 'bottom', child: Text('置底')),
        const PopupMenuItem(value: 'edit', child: Text('编辑')),
        const PopupMenuItem(value: 'validate', child: Text('校验')),
        if (source.hasLoginConfig)
          const PopupMenuItem(value: 'login', child: Text('登录')),
        const PopupMenuItem(value: 'search', child: Text('搜索')),
        const PopupMenuItem(value: 'debug', child: Text('调试')),
        PopupMenuItem(
          value: 'toggle',
          child: Text(source.enabled ? '禁用' : '启用'),
        ),
        if (explore)
          PopupMenuItem(
            value: 'explore',
            child: Text(isExploreEnabled(source) ? '禁用发现' : '启用发现'),
          ),
        const PopupMenuItem(value: 'del', child: Text('删除')),
      ],
    ).then((action) async {
      if (action == null || !mounted) return;
      switch (action) {
        case 'top':
          await provider.moveSourcesToTop([source.bookSourceUrl]);
        case 'bottom':
          await provider.moveSourcesToBottom([source.bookSourceUrl]);
        case 'edit':
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: provider,
                child: SourceEditorPage(source: source),
              ),
            ),
          );
        case 'validate':
          await _validateOne(context, source);
        case 'login':
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SourceLoginPage(source: source)),
          );
        case 'search':
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SearchPage(initialRestrictSourceUrls: {source.bookSourceUrl}),
            ),
          );
        case 'debug':
          await SourceDebugPage.open(context, source);
        case 'toggle':
          await provider.toggleSource(source.bookSourceUrl, !source.enabled);
        case 'explore':
          await provider.setSourcesExploreEnabled([
            source.bookSourceUrl,
          ], !isExploreEnabled(source));
        case 'del':
          final yes = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('删除'),
              content: Text('确定删除\n${source.bookSourceName}？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('删除'),
                ),
              ],
            ),
          );
          if (yes == true) {
            await provider.deleteSources([source.bookSourceUrl]);
            _selected.remove(source.bookSourceUrl);
            if (mounted) setState(() {});
          }
      }
    });
  }

  PopupMenuItem<String> _menuItem(
    IconData icon,
    String label,
    String value,
    ColorScheme scheme, {
    bool checked = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: _uiText(color: scheme.onSurface)),
          ),
          if (checked) Icon(Icons.check, size: 18, color: scheme.secondary),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.secondary;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _buildSearchField(scheme),
        ),
        actions: [
          // 排序 — menu action_sort
          PopupMenuButton<String>(
            tooltip: '排序',
            icon: const Icon(Icons.sort_by_alpha),
            offset: legadoAppBarPopupOffset(context),
            onSelected: (v) {
              setState(() {
                if (v == 'desc') {
                  _sortDesc = !_sortDesc;
                } else {
                  _sort = switch (v) {
                    'manual' => _SourceSort.manual,
                    'auto' => _SourceSort.auto,
                    'name' => _SourceSort.name,
                    'url' => _SourceSort.url,
                    'enabled' => _SourceSort.enabled,
                    'lastUpdate' => _SourceSort.lastUpdate,
                    'respondTime' => _SourceSort.respondTime,
                    _ => _sort,
                  };
                }
              });
            },
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: 'desc',
                checked: _sortDesc,
                child: Text('降序', style: _uiText(color: scheme.onSurface)),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem(
                value: 'manual',
                checked: _sort == _SourceSort.manual,
                child: Text('手动', style: _uiText(color: scheme.onSurface)),
              ),
              CheckedPopupMenuItem(
                value: 'auto',
                checked: _sort == _SourceSort.auto,
                child: Text('智能排序', style: _uiText(color: scheme.onSurface)),
              ),
              CheckedPopupMenuItem(
                value: 'name',
                checked: _sort == _SourceSort.name,
                child: Text('名称', style: _uiText(color: scheme.onSurface)),
              ),
              CheckedPopupMenuItem(
                value: 'url',
                checked: _sort == _SourceSort.url,
                child: Text('URL', style: _uiText(color: scheme.onSurface)),
              ),
              CheckedPopupMenuItem(
                value: 'enabled',
                checked: _sort == _SourceSort.enabled,
                child: Text('启用状态', style: _uiText(color: scheme.onSurface)),
              ),
              CheckedPopupMenuItem(
                value: 'lastUpdate',
                checked: _sort == _SourceSort.lastUpdate,
                child: Text('更新时间排序', style: _uiText(color: scheme.onSurface)),
              ),
              CheckedPopupMenuItem(
                value: 'respondTime',
                checked: _sort == _SourceSort.respondTime,
                child: Text('响应时间排序', style: _uiText(color: scheme.onSurface)),
              ),
            ],
          ),
          // 分组筛选 — menu_group
          Consumer<SourceProvider>(
            builder: (context, provider, _) {
              final groups = _allGroups(provider);
              return PopupMenuButton<String>(
                tooltip: '分组',
                icon: const Icon(Icons.hub_outlined),
                offset: legadoAppBarPopupOffset(context),
                onSelected: (v) {
                  if (v == 'manage') {
                    showSourceGroupManageDialog(context);
                    return;
                  }
                  _setFilter(v);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'manage',
                    child: Text(
                      '分组管理',
                      style: _uiText(color: scheme.onSurface),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'all',
                    child: Text('全部', style: _uiText(color: scheme.onSurface)),
                  ),
                  PopupMenuItem(
                    value: 'enabled',
                    child: Text('已启用', style: _uiText(color: scheme.onSurface)),
                  ),
                  PopupMenuItem(
                    value: 'disabled',
                    child: Text('已禁用', style: _uiText(color: scheme.onSurface)),
                  ),
                  PopupMenuItem(
                    value: 'login',
                    child: Text(
                      '需要登录',
                      style: _uiText(color: scheme.onSurface),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'null_group',
                    child: Text('未分组', style: _uiText(color: scheme.onSurface)),
                  ),
                  PopupMenuItem(
                    value: 'explore_on',
                    child: Text(
                      '启用发现',
                      style: _uiText(color: scheme.onSurface),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'explore_off',
                    child: Text(
                      '禁用发现',
                      style: _uiText(color: scheme.onSurface),
                    ),
                  ),
                  if (groups.isNotEmpty) const PopupMenuDivider(),
                  ...groups.map(
                    (g) => PopupMenuItem(
                      value: 'group:$g',
                      child: Text(g, style: _uiText(color: scheme.onSurface)),
                    ),
                  ),
                ],
              );
            },
          ),
          // 更多 — 对齐 Jingshiro menu/book_source.xml
          PopupMenuButton<String>(
            tooltip: '更多',
            icon: const Icon(Icons.more_vert),
            offset: legadoAppBarPopupOffset(context),
            onSelected: _onOverflow,
            itemBuilder: (_) => [
              _menuItem(Icons.add, '新建书源', 'add', scheme),
              _menuItem(
                Icons.file_download_outlined,
                '本地导入',
                'import_local',
                scheme,
              ),
              _menuItem(
                Icons.cloud_download_outlined,
                '网络导入',
                'import_online',
                scheme,
              ),
              _menuItem(Icons.qr_code_scanner, '二维码导入', 'import_qr', scheme),
              _menuItem(
                Icons.dns_outlined,
                '按域名分组',
                'group_domain',
                scheme,
                checked: _groupByDomain,
              ),
              _menuItem(Icons.help_outline, '帮助', 'help', scheme),
            ],
          ),
        ],
      ),
      body: Consumer<SourceProvider>(
        builder: (context, provider, _) {
          final sources = provider.sources;

          if (provider.isLoading &&
              sources.isEmpty &&
              provider.loadError == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadError != null && sources.isEmpty) {
            return ErrorView(
              message: provider.loadError!,
              onRetry: () => provider.loadSources(),
            );
          }
          if (sources.isEmpty) {
            return _buildEmptyState(scheme);
          }

          final visible = _visibleSources(sources);
          if (visible.isEmpty) {
            return Center(
              child: Text(
                '没有匹配的书源',
                style: _uiText(color: scheme.onSurfaceVariant),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: _groupByDomain
                    ? _buildDomainGroupedList(visible, provider, scheme, accent)
                    : _buildFlatList(visible, provider, scheme, accent),
              ),
              _buildSelectActionBar(scheme, visible),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 48, color: scheme.primary),
          const SizedBox(height: 16),
          Text('还没有书源', style: _uiText(color: scheme.onSurface, size: 18)),
          const SizedBox(height: 8),
          Text(
            '右上角菜单可新建或导入书源',
            style: _uiText(color: scheme.onSurfaceVariant, size: 13),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.store),
            label: const Text('打开书源市场'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SourceMarketPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatList(
    List<BookSource> visible,
    SourceProvider provider,
    ColorScheme scheme,
    Color accent,
  ) {
    final canReorder =
        _sort == _SourceSort.manual &&
        !_groupByDomain &&
        _filter == 'all' &&
        _searchController.text.trim().isEmpty;

    if (canReorder) {
      return _wrapListWithDragSelect(
        visible,
        ReorderableListView.builder(
          scrollController: _listScrollController,
          buildDefaultDragHandles: false,
          itemCount: visible.length,
          onReorder: (oldIndex, newIndex) async {
            var target = newIndex;
            if (oldIndex < target) target--;
            final items = List<BookSource>.from(visible);
            final moved = items.removeAt(oldIndex);
            items.insert(target, moved);
            final urls = items.map((s) => s.bookSourceUrl).toList();
            await provider.reorderSources(urls);
          },
          itemBuilder: (_, i) {
            final s = visible[i];
            return Column(
              key: ValueKey(s.bookSourceUrl),
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSourceRow(
                  s,
                  i,
                  visible,
                  provider,
                  scheme,
                  accent,
                  dragHandle: ReorderableDragStartListener(
                    index: i,
                    child: Icon(
                      Icons.drag_handle,
                      size: 22,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ],
            );
          },
        ),
      );
    }

    return _wrapListWithDragSelect(
      visible,
      ListView.separated(
        controller: _listScrollController,
        itemCount: visible.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        itemBuilder: (_, i) =>
            _buildSourceRow(visible[i], i, visible, provider, scheme, accent),
      ),
    );
  }

  Widget _buildDomainGroupedList(
    List<BookSource> visible,
    SourceProvider provider,
    ColorScheme scheme,
    Color accent,
  ) {
    final map = <String, List<BookSource>>{};
    for (final s in visible) {
      map.putIfAbsent(_hostOf(s), () => []).add(s);
    }
    final keys = map.keys.toList()..sort();
    final indexOf = {
      for (var i = 0; i < visible.length; i++) visible[i].bookSourceUrl: i,
    };
    return _wrapListWithDragSelect(
      visible,
      ListView.builder(
        controller: _listScrollController,
        itemCount: keys.length,
        itemBuilder: (_, gi) {
          final host = keys[gi];
          final items = map[host]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  host,
                  style: _uiText(
                    color: scheme.secondary,
                    size: 16,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
              ...items.map(
                (s) => Column(
                  children: [
                    _buildSourceRow(
                      s,
                      indexOf[s.bookSourceUrl]!,
                      visible,
                      provider,
                      scheme,
                      accent,
                    ),
                    Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 对齐 `item_book_source.xml`：勾选+名 | Switch | 编辑 | 更多 | 发现绿点
  Widget _buildSourceRow(
    BookSource s,
    int index,
    List<BookSource> visible,
    SourceProvider provider,
    ColorScheme scheme,
    Color accent, {
    Widget? dragHandle,
  }) {
    final checked = _selected.contains(s.bookSourceUrl);
    final validating =
        provider.isValidating &&
        provider.validatingSourceUrl == s.bookSourceUrl;
    final validation = provider.validationOf(s.bookSourceUrl);
    final progressMessage = provider.validationProgressOf(s.bookSourceUrl);
    final hasExplore = hasExploreUrl(s);
    final group = s.bookSourceGroup.trim();
    final displayName = group.isEmpty
        ? s.bookSourceName
        : '${s.bookSourceName} ($group)';

    return Material(
      key: _rowKeyFor(s.bookSourceUrl),
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LegadoTokens.spacingMd,
          vertical: 10,
        ),
        child: Row(
          children: [
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                _dragPending = true;
                _dragStartPos = e.position;
                _dragPendingIndex = index;
                _dragPendingVisible = visible;
              },
              child: SizedBox(
                width: _checkboxLaneWidth,
                child: Checkbox(
                  value: checked,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selected.add(s.bookSourceUrl);
                      } else {
                        _selected.remove(s.bookSourceUrl);
                      }
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  SourceStatusDot(source: s, validation: validation),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _uiText(
                            color: s.enabled
                                ? scheme.onSurface
                                : scheme.onSurface.withValues(alpha: 0.55),
                            size: 15,
                          ),
                        ),
                        if (_showDebugMessage && progressMessage != null)
                          Text(
                            progressMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _uiText(
                              color: scheme.onSurface.withValues(alpha: 0.45),
                              size: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (validating)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            Switch(
              value: s.enabled,
              activeThumbColor: Colors.white,
              activeTrackColor: accent,
              onChanged: (v) => provider.toggleSource(s.bookSourceUrl, v),
            ),
            IconButton(
              tooltip: '编辑',
              icon: Icon(Icons.open_in_new, size: 20, color: scheme.onSurface),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: SourceEditorPage(source: s),
                  ),
                ),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Builder(
                  builder: (tileCtx) => IconButton(
                    tooltip: '更多',
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: scheme.onSurface,
                    ),
                    onPressed: () {
                      final box = tileCtx.findRenderObject() as RenderBox?;
                      final offset =
                          box?.localToGlobal(Offset.zero) ?? Offset.zero;
                      _showItemMenu(s, offset);
                    },
                  ),
                ),
                if (hasExplore)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isExploreEnabled(s)
                            ? const Color(0xFF43A047)
                            : const Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            ?dragHandle,
          ],
        ),
      ),
    );
  }

  /// 对齐 `view_select_action_bar.xml`
  ButtonStyle _selectBarButtonStyle(ColorScheme scheme) {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      foregroundColor: scheme.onSurface,
      side: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _buildSelectActionBar(ColorScheme scheme, List<BookSource> visible) {
    final total = visible.length;
    final selectedCount = visible
        .where((s) => _selected.contains(s.bookSourceUrl))
        .length;
    final allSelected = total > 0 && selectedCount == total;
    final hasSelection = selectedCount > 0;

    final bottomBg =
        Theme.of(context).bottomAppBarTheme.color ?? scheme.surface;
    return Material(
      key: _selectBarKey,
      elevation: 2,
      color: bottomBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: allSelected ? true : (selectedCount > 0 ? null : false),
              tristate: true,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (_) {
                setState(() {
                  if (allSelected) {
                    for (final s in visible) {
                      _selected.remove(s.bookSourceUrl);
                    }
                  } else {
                    for (final s in visible) {
                      _selected.add(s.bookSourceUrl);
                    }
                  }
                });
              },
            ),
            Expanded(
              child: Text(
                '全选 ($selectedCount/$total)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _uiText(color: scheme.onSurface, size: 14),
              ),
            ),
            OutlinedButton(
              style: _selectBarButtonStyle(scheme),
              onPressed: total == 0
                  ? null
                  : () {
                      setState(() {
                        for (final s in visible) {
                          if (_selected.contains(s.bookSourceUrl)) {
                            _selected.remove(s.bookSourceUrl);
                          } else {
                            _selected.add(s.bookSourceUrl);
                          }
                        }
                      });
                    },
              child: Text('反选', style: _uiText(color: scheme.onSurface)),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              style: _selectBarButtonStyle(scheme),
              onPressed: hasSelection ? _deleteSelected : null,
              child: Text(
                '删除',
                style: _uiText(
                  color: hasSelection
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ),
            LegadoBottomBarPopupButton<String>(
              barKey: _selectBarKey,
              onSelected: (v) => _onBottomMore(v),
              icon: Icon(Icons.more_vert, color: scheme.onSurface, size: 22),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'enable',
                  child: Text('启用所选', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'disable',
                  child: Text('禁用所选', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'explore_enable',
                  child: Text('启用发现', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'explore_disable',
                  child: Text('禁用发现', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'group',
                  child: Text('设置分组', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'add_group',
                  child: Text('添加分组', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'remove_group',
                  child: Text('移除分组', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'top',
                  child: Text('置顶所选', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'bottom',
                  child: Text('置底所选', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: Text('导出所选', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: Text('分享书源', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'validate',
                  child: Text('校验所选', style: _uiText(color: scheme.onSurface)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 导入 / 校验（保留原业务） ──

  static bool _looksLikeImportUrl(String text) {
    final t = text.trim();
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(t)) return true;
    final uri = Uri.tryParse(t);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> _parseAndPreviewImport(BuildContext context, String text) async {
    final provider = context.read<SourceProvider>();
    final showLoading = _looksLikeImportUrl(text);
    if (showLoading && context.mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    List<BookSource>? candidates;
    try {
      candidates = await provider.parseSourcesForImport(text);
    } catch (e) {
      if (showLoading && context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (showLoading && context.mounted) Navigator.pop(context);
    if (!context.mounted) return;

    if (candidates == null || candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未找到有效书源数据'), backgroundColor: Colors.red),
      );
      return;
    }

    if (showLoading) {
      await ImportUrlHistoryStore.add(text.trim());
      if (!context.mounted) return;
    }

    final existingByUrl = {
      for (final s in provider.sources) s.bookSourceUrl: s,
    };
    await showDialog<void>(
      context: context,
      builder: (_) => ImportBookSourceDialog(
        candidates: candidates!,
        existingByUrl: existingByUrl,
      ),
    );
  }

  Future<void> _importFromJsonFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.single.path!);
      final jsonText = await file.readAsString();
      if (!context.mounted) return;
      await _parseAndPreviewImport(context, jsonText);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importFromQr(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrCodeCapturePage()),
    );
    if (result == null || result.isEmpty || !context.mounted) return;
    await _parseAndPreviewImport(context, result);
  }

  void _showImportUrlDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ImportUrlDialog(
        onImport: (url) => _parseAndPreviewImport(context, url),
      ),
    );
  }

  Future<void> _validateOne(BuildContext context, BookSource source) async {
    final keyword = await showCheckSourceKeywordDialog(context);
    await _loadCheckSourceUiPrefs();
    if (keyword == null || !context.mounted) return;
    final provider = context.read<SourceProvider>();
    final result = await provider.validateSource(
      source,
      keyword: keyword.isEmpty ? null : keyword,
    );
    if (!context.mounted || result == null) return;
    await SourceValidationSheet.show(
      context,
      sourceName: source.bookSourceName,
      result: result,
    );
  }
}

class _ImportUrlDialog extends StatefulWidget {
  final Future<void> Function(String url) onImport;

  const _ImportUrlDialog({required this.onImport});

  @override
  State<_ImportUrlDialog> createState() => _ImportUrlDialogState();
}

class _ImportUrlDialogState extends State<_ImportUrlDialog> {
  final _controller = TextEditingController();
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final list = await ImportUrlHistoryStore.load();
    if (mounted) setState(() => _history = list);
  }

  Future<void> _removeHistory(String url) async {
    await ImportUrlHistoryStore.remove(url);
    await _loadHistory();
  }

  Future<void> _submit() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    Navigator.pop(context);
    await widget.onImport(url);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('网络导入'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '输入书源 JSON 的 URL…',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '最近使用',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _history.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final url = _history[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        url,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => _controller.text = url,
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: '删除',
                        onPressed: () => _removeHistory(url),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('导入')),
      ],
    );
  }
}

class _BatchValidateDialog extends StatefulWidget {
  final SourceProvider provider;
  final List<BookSource>? sources;
  final String? keyword;

  const _BatchValidateDialog({
    required this.provider,
    this.sources,
    this.keyword,
  });

  @override
  State<_BatchValidateDialog> createState() => _BatchValidateDialogState();
}

class _BatchValidateDialogState extends State<_BatchValidateDialog> {
  int _done = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    final targets =
        widget.sources ??
        widget.provider.sources.where((s) => s.enabled).toList();
    _total = targets.length;
    widget.provider
        .validateSources(
          targets,
          keyword: widget.keyword?.isEmpty == true ? null : widget.keyword,
          onProgress: (done, total) {
            if (mounted) {
              setState(() {
                _done = done;
                _total = total;
              });
            }
          },
        )
        .then((passed) {
          if (!mounted) return;
          final messenger = ScaffoldMessenger.maybeOf(context);
          Navigator.pop(context);
          messenger?.showSnackBar(
            SnackBar(content: Text('校验完成：$passed/$_total 书源可用')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('书源校验'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Text('正在校验 $_done / $_total …'),
          const SizedBox(height: 8),
          Text(
            '测试搜索、发现、目录与正文',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
