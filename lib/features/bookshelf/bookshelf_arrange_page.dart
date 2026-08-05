import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/bookshelf/book_group_store_port.dart';
import '../../application/bookshelf/bookshelf_arrange_delete_command_port.dart';
import '../../application/bookshelf/bookshelf_arrange_group_command_port.dart';
import '../../application/bookshelf/bookshelf_arrange_port.dart';
import '../../application/bookshelf/bookshelf_arrange_snapshot_port.dart';
import '../../application/source_management/source_controller.dart';
import '../../application/source_management/source_notifier.dart';
import '../../domain/book/book_group.dart';
import 'package:legado_flutter/domain/book/book.dart';
import '../../widgets/book_group_manage_dialog.dart';
import '../../widgets/book_group_select_dialog.dart';
import '../../widgets/legado_popup_menu.dart';
import '../../features/book/book_info_page.dart';

/// 书架整理 — 对齐 legado [BookshelfManageActivity] + `activity_arrange_book.xml`
class BookshelfArrangePage extends StatelessWidget {
  const BookshelfArrangePage({
    super.key,
    this.groupFilter,
    this.groupLabel = '全部',
    this.gridLayout = false,
    this.preferences,
    this.groupStore,
    this.groupCommands,
    this.deleteCommands,
    this.snapshot,
    this.sourceController,
  });

  /// `null` = 全部；`''` = 未分组；其它 = 分组名
  final String? groupFilter;
  final String groupLabel;

  /// 保留入参兼容；管理页固定列表（对齐 Jingshiro LinearLayoutManager）
  final bool gridLayout;

  /// Storage boundary for page-local preferences.
  final BookshelfArrangePort? preferences;

  /// 书架分组目录边界；测试宿主可显式注入 fake。
  final BookGroupStorePort? groupStore;

  /// 分组命令边界；生产由组合根注入 Provider 回调适配器。
  final BookshelfArrangeGroupCommandPort? groupCommands;

  /// 删除命令边界；生产由组合根注入 Provider 回调适配器。
  final BookshelfArrangeDeleteCommandPort? deleteCommands;

  /// 当前完整书架快照边界；生产由组合根注入，测试宿主可显式提供。
  final BookshelfArrangeSnapshotPort? snapshot;
  final SourceController? sourceController;

  @override
  Widget build(BuildContext context) {
    final body = _BookshelfArrangePageBody(
      groupFilter: groupFilter,
      groupLabel: groupLabel,
      gridLayout: gridLayout,
      preferences: preferences,
      groupStore: groupStore,
      groupCommands: groupCommands,
      deleteCommands: deleteCommands,
      snapshot: snapshot,
    );
    final controller = sourceController;
    if (controller == null) return body;
    return riverpod.ProviderScope(
      overrides: [sourceControllerProvider.overrideWithValue(controller)],
      child: body,
    );
  }
}

class _BookshelfArrangePageBody extends riverpod.ConsumerStatefulWidget {
  const _BookshelfArrangePageBody({
    this.groupFilter,
    this.groupLabel = '全部',
    this.gridLayout = false,
    this.preferences,
    this.groupStore,
    this.groupCommands,
    this.deleteCommands,
    this.snapshot,
  });

  final String? groupFilter;
  final String groupLabel;
  final bool gridLayout;
  final BookshelfArrangePort? preferences;
  final BookGroupStorePort? groupStore;
  final BookshelfArrangeGroupCommandPort? groupCommands;
  final BookshelfArrangeDeleteCommandPort? deleteCommands;
  final BookshelfArrangeSnapshotPort? snapshot;

  @override
  riverpod.ConsumerState<_BookshelfArrangePageBody> createState() =>
      _BookshelfArrangePageState();
}

class _BookshelfArrangePageState
    extends riverpod.ConsumerState<_BookshelfArrangePageBody> {
  static const _filterAll = '__all__';
  static const _filterLocal = '__local__';
  static const _filterUngrouped = '__ungrouped__';

  final _searchCtrl = TextEditingController();
  final _selected = <String>{};
  final _selectBarKey = GlobalKey();
  List<Book> _books = [];
  List<String> _cachedOrder = [];
  bool _dragEnabled = true;
  bool _dirty = false;
  bool _openInfoByTitle = false;
  late final BookshelfArrangePort _preferences;
  late final BookGroupStorePort _groupStore;
  late final BookshelfArrangeGroupCommandPort _groupCommands;
  late final BookshelfArrangeDeleteCommandPort _deleteCommands;
  late final BookshelfArrangeSnapshotPort _snapshot;

  /// 当前筛选：全部 / 本地 / 未分组 / 自定义分组名
  late String _filterKey;
  late String _groupLabel;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences ?? context.read<BookshelfArrangePort>();
    _groupStore = widget.groupStore ?? context.read<BookGroupStorePort>();
    _groupCommands =
        widget.groupCommands ??
        context.read<BookshelfArrangeGroupCommandPort>();
    _deleteCommands =
        widget.deleteCommands ??
        context.read<BookshelfArrangeDeleteCommandPort>();
    _snapshot =
        widget.snapshot ??
        context.read<BookshelfArrangeSnapshotPort?>() ??
        const EmptyBookshelfArrangeSnapshotPort();
    _filterKey = _filterKeyFromWidget(widget.groupFilter);
    _groupLabel = widget.groupLabel;
    _loadSortMode();
    _loadOpenInfoPref();
    _loadOrderAndBooks();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _filterKeyFromWidget(String? groupFilter) {
    if (groupFilter == null) return _filterAll;
    if (groupFilter.isEmpty) return _filterUngrouped;
    return groupFilter;
  }

  Future<void> _loadSortMode() async {
    final mode = await _preferences.loadSortMode();
    if (!mounted) return;
    setState(() => _dragEnabled = mode == 3);
  }

  Future<void> _loadOpenInfoPref() async {
    final value = await _preferences.loadOpenBookInfoByTitle();
    if (!mounted) return;
    setState(() => _openInfoByTitle = value);
  }

  Future<void> _setOpenInfoByTitle(bool v) async {
    await _preferences.saveOpenBookInfoByTitle(v);
    if (!mounted) return;
    setState(() => _openInfoByTitle = v);
  }

  void _reloadBooks([List<Book>? snapshot]) {
    var all = snapshot ?? _snapshot.books;
    all = _applyGroupFilter(all);
    _books = BookshelfArrangeOrderPolicy.apply(all, _cachedOrder, (b) => b.id);
    _selected.removeWhere((id) => !_books.any((b) => b.id == id));
  }

  List<Book> _applyGroupFilter(List<Book> all) {
    switch (_filterKey) {
      case _filterAll:
      case '${BookGroup.idAll}':
        return all;
      case _filterLocal:
      case '${BookGroup.idLocal}':
        return all.where((b) => b.type == 'local').toList();
      case _filterUngrouped:
        return all.where((b) => b.group.isEmpty).toList();
      case '${BookGroup.idNetNone}':
        return all.where((b) => b.type != 'local' && b.group.isEmpty).toList();
      case '${BookGroup.idLocalNone}':
        return all.where((b) => b.type == 'local' && b.group.isEmpty).toList();
      case '${BookGroup.idAudio}':
      case '${BookGroup.idVideo}':
      case '${BookGroup.idError}':
        // 音频/视频/更新失败：Flutter 暂无对应类型标记，显示空列表
        return const [];
      default:
        return all.where((b) => b.group == _filterKey).toList();
    }
  }

  Future<void> _loadOrderAndBooks() async {
    _cachedOrder = await _preferences.loadBookOrder();
    if (!mounted) return;
    final books = _snapshot.books;
    await _groupStore.syncNamesFromBooks(
      books.map((b) => b.group).where((g) => g.isNotEmpty),
    );
    if (!mounted) return;
    setState(_reloadBooks);
  }

  List<Book> get _visibleBooks {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _books;
    return _books.where((b) {
      return b.name.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.group.toLowerCase().contains(q) ||
          _originLabel(b).toLowerCase().contains(q);
    }).toList();
  }

  String _originLabel(Book book) {
    if (book.type == 'local' || book.bookSourceUrl.isEmpty) {
      return '本地书籍';
    }
    final src = ref
        .read(sourceNotifierProvider.notifier)
        .findSourceForBook(book);
    return src?.bookSourceName ?? book.bookSourceUrl;
  }

  Future<void> _persistOrder() async {
    await _preferences.saveBookOrder(_books.map((b) => b.id).toList());
    await _preferences.saveSortMode(3);
    _dirty = false;
  }

  Future<bool> _onWillPop() async {
    if (_dirty) await _persistOrder();
    return true;
  }

  void _setGroupFilter(String key, String label) {
    setState(() {
      _filterKey = key;
      _groupLabel = label;
      _reloadBooks();
      _selected.clear();
    });
  }

  void _toggleAll(bool selectAll) {
    setState(() {
      if (selectAll) {
        _selected.addAll(_visibleBooks.map((b) => b.id));
      } else {
        _selected.clear();
      }
    });
  }

  void _invertSelection() {
    setState(() {
      for (final b in _visibleBooks) {
        if (_selected.contains(b.id)) {
          _selected.remove(b.id);
        } else {
          _selected.add(b.id);
        }
      }
    });
  }

  void _selectInterval() {
    final visible = _visibleBooks;
    if (visible.isEmpty) return;
    final indices = <int>[];
    for (var i = 0; i < visible.length; i++) {
      if (_selected.contains(visible[i].id)) indices.add(i);
    }
    if (indices.length < 2) return;
    final min = indices.reduce((a, b) => a < b ? a : b);
    final max = indices.reduce((a, b) => a > b ? a : b);
    setState(() {
      for (var i = min; i <= max; i++) {
        _selected.add(visible[i].id);
      }
    });
  }

  void _toggleBook(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    if (!_dragEnabled) return;
    setState(() {
      final item = _books.removeAt(oldIndex);
      _books.insert(newIndex, item);
      _dirty = true;
    });
  }

  /// 移入分组 — 对齐 [BookshelfManageActivity.onClickSelectBarMainAction]
  Future<void> _moveSelectedToGroup() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    final chosen = await _pickGroup();
    if (chosen == null || !mounted) return;
    final books = await _groupCommands.updateBooksGroup(ids, chosen);
    if (!mounted) return;
    setState(() {
      _reloadBooks(books);
      _selected.clear();
    });
  }

  /// 行内「分组」— 对齐 adapter 单本 [GroupSelectDialog]
  Future<void> _moveOneToGroup(Book book) async {
    final chosen = await _pickGroup(current: book.group);
    if (chosen == null || !mounted) return;
    final books = await _groupCommands.updateBookGroup(book.id, chosen);
    if (!mounted) return;
    setState(() => _reloadBooks(books));
  }

  /// 加入分组（字符串模型下等同设为目标分组）
  Future<void> _addSelectedToGroup() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    final chosen = await _pickGroup();
    if (chosen == null || !mounted) return;
    final books = await _groupCommands.updateBooksGroup(ids, chosen);
    if (!mounted) return;
    setState(() {
      _reloadBooks(books);
      _selected.clear();
    });
  }

  /// 移除分组：选中目标分组后，匹配该书分组则清空
  Future<void> _removeSelectedFromGroup() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    final chosen = await _pickGroup();
    if (chosen == null || !mounted) return;
    final books = await _groupCommands.clearBooksGroup(
      ids,
      onlyWhenGroupEquals: chosen.isEmpty ? null : chosen,
    );
    if (!mounted) return;
    setState(() {
      _reloadBooks(books);
      _selected.clear();
    });
  }

  /// 对齐 [GroupSelectDialog]；返回目标分组名（空=未分组）
  Future<String?> _pickGroup({String? current}) async {
    final result = await showBookGroupSelectDialog(
      context,
      currentGroupName: current,
    );
    if (result == null) return null;
    return result.primaryName;
  }

  Future<void> _showGroupManage() async {
    await showBookGroupManageDialog(context);
    if (!mounted) return;
    setState(_reloadBooks);
  }

  Future<void> _deleteSelected() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除'),
        content: Text('确定删除选中的 ${ids.length} 本书？'),
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
    await _deleteCommands.removeBooks(ids);
    setState(() {
      _books.removeWhere((b) => ids.contains(b.id));
      _selected.removeWhere((id) => ids.contains(id));
      _dirty = true;
    });
    await _persistOrder();
  }

  Future<void> _deleteOne(Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(book.name),
        content: const Text('从书架移除？'),
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
    await _deleteCommands.removeBook(book.id);
    setState(() {
      _books.removeWhere((b) => b.id == book.id);
      _selected.remove(book.id);
      _dirty = true;
    });
    await _persistOrder();
  }

  Future<void> _exportAllUseBookSource() async {
    final sources = ref.read(sourceNotifierProvider.notifier);
    final used = <String, dynamic>{};
    for (final book in _snapshot.books) {
      final src = sources.findSourceForBook(book);
      if (src == null) continue;
      used[src.bookSourceUrl] = src.toJson();
    }
    if (used.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('书架书籍没有可用书源')));
      return;
    }
    final json = const JsonEncoder.withIndent(
      '  ',
    ).convert(used.values.toList());
    await Share.share(json, subject: 'bookSource.json');
  }

  void _openBookInfo(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookInfoPage(book: book)),
    );
  }

  void _onGroupMenu(String value) {
    switch (value) {
      case 'manage':
        _showGroupManage();
      default:
        if (value.startsWith('gid:')) {
          final id = int.tryParse(value.substring(4));
          if (id == null) return;
          BookGroup? g;
          for (final x in _groupStore.cached) {
            if (x.groupId == id) {
              g = x;
              break;
            }
          }
          if (g == null) return;
          if (g.groupId == BookGroup.idAll) {
            _setGroupFilter(_filterAll, g.groupName);
          } else if (g.groupId == BookGroup.idLocal) {
            _setGroupFilter(_filterLocal, g.groupName);
          } else if (g.isCustom) {
            _setGroupFilter(g.groupName, g.groupName);
          } else {
            _setGroupFilter('${g.groupId}', g.groupName);
          }
        }
    }
  }

  void _onOverflow(String value) {
    switch (value) {
      case 'export_sources':
        _exportAllUseBookSource();
      case 'open_info':
        _setOpenInfoByTitle(!_openInfoByTitle);
    }
  }

  void _onBottomMore(String value) {
    switch (value) {
      case 'delete':
        _deleteSelected();
      case 'add_group':
        _addSelectedToGroup();
      case 'remove_group':
        _removeSelectedFromGroup();
      case 'interval':
        _selectInterval();
      case 'update_enable':
      case 'update_disable':
      case 'change_source':
      case 'clear_cache':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('该功能尚未接入')));
    }
  }

  Widget _buildSearchField(ColorScheme scheme) {
    final onBar = scheme.onPrimary;
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(color: onBar, fontSize: 15),
        cursorColor: onBar,
        decoration: InputDecoration(
          hintText: '筛选 • $_groupLabel',
          hintStyle: TextStyle(
            color: onBar.withValues(alpha: 0.72),
            fontSize: 15,
          ),
          isDense: true,
          filled: true,
          fillColor: onBar.withValues(alpha: 0.10),
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
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: onBar.withValues(alpha: 0.85),
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: onBar.withValues(alpha: 0.10),
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: onBar.withValues(alpha: 0.22),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _selectBarButtonStyle(ColorScheme scheme) {
    return OutlinedButton.styleFrom(
      foregroundColor: scheme.onSurface,
      side: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// 对齐 `view_select_action_bar.xml`：全选 / 反选 / 移入分组 / 更多
  Widget _buildSelectActionBar(ColorScheme scheme, List<Book> visible) {
    final total = visible.length;
    final selectedCount = visible.where((b) => _selected.contains(b.id)).length;
    final allSelected = total > 0 && selectedCount == total;
    final hasSelection = selectedCount > 0;
    final bottomBg =
        Theme.of(context).bottomAppBarTheme.color ?? scheme.surface;

    return Material(
      key: _selectBarKey,
      elevation: 2,
      color: bottomBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Checkbox(
                value: allSelected ? true : (selectedCount > 0 ? null : false),
                tristate: true,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: total == 0 ? null : (_) => _toggleAll(!allSelected),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: total == 0 ? null : () => _toggleAll(!allSelected),
                  child: Text(
                    '全选 ($selectedCount/$total)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: scheme.onSurface),
                  ),
                ),
              ),
              OutlinedButton(
                style: _selectBarButtonStyle(scheme),
                onPressed: total == 0 ? null : _invertSelection,
                child: Text('反选', style: TextStyle(color: scheme.onSurface)),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                style: _selectBarButtonStyle(scheme),
                onPressed: hasSelection ? _moveSelectedToGroup : null,
                child: Text(
                  '移入分组',
                  style: TextStyle(
                    color: hasSelection
                        ? scheme.onSurface
                        : scheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ),
              LegadoBottomBarPopupButton<String>(
                barKey: _selectBarKey,
                enabled: hasSelection,
                onSelected: _onBottomMore,
                icon: Icon(
                  Icons.more_vert,
                  color: hasSelection
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.38),
                  size: 22,
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('删除')),
                  PopupMenuItem(value: 'update_enable', child: Text('允许更新')),
                  PopupMenuItem(value: 'update_disable', child: Text('禁用更新')),
                  PopupMenuItem(value: 'add_group', child: Text('加入分组')),
                  PopupMenuItem(value: 'remove_group', child: Text('移除分组')),
                  PopupMenuItem(value: 'change_source', child: Text('批量换源')),
                  PopupMenuItem(value: 'clear_cache', child: Text('清除缓存')),
                  PopupMenuItem(value: 'interval', child: Text('选中所选区间')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sourceNotifierProvider);
    final visible = _visibleBooks;
    final scheme = Theme.of(context).colorScheme;
    final menuGroups = _groupStore.cached.where((g) => g.show).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _onWillPop() && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _buildSearchField(scheme),
          ),
          actions: [
            PopupMenuButton<String>(
              offset: legadoAppBarPopupOffset(context),
              tooltip: '分组',
              icon: const Icon(Icons.account_tree_outlined),
              onSelected: _onGroupMenu,
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'manage', child: Text('分组管理')),
                ...menuGroups.map(
                  (g) => PopupMenuItem(
                    value: 'gid:${g.groupId}',
                    child: Text(g.groupName),
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              offset: legadoAppBarPopupOffset(context),
              tooltip: '更多',
              icon: const Icon(Icons.more_vert),
              onSelected: _onOverflow,
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'export_sources',
                  child: Text('导出所有书的书源'),
                ),
                CheckedPopupMenuItem(
                  value: 'open_info',
                  checked: _openInfoByTitle,
                  child: const Text('点击书名打开详情'),
                ),
              ],
            ),
          ],
        ),
        body: visible.isEmpty
            ? Center(
                child: Text(
                  '没有书籍',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              )
            : _buildListBody(visible),
        bottomNavigationBar: _buildSelectActionBar(scheme, visible),
      ),
    );
  }

  Widget _buildListBody(List<Book> visible) {
    final filtering = _searchCtrl.text.trim().isNotEmpty;
    if (filtering) {
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const Divider(height: 1, thickness: 0.5),
        itemBuilder: (context, index) {
          final book = visible[index];
          return _ArrangeListTile(
            key: ValueKey(book.id),
            book: book,
            origin: _originLabel(book),
            checked: _selected.contains(book.id),
            dragEnabled: false,
            openInfoByTitle: _openInfoByTitle,
            onToggle: () => _toggleBook(book.id),
            onTitleTap: () => _openBookInfo(book),
            onDelete: () => _deleteOne(book),
            onGroup: () => _moveOneToGroup(book),
          );
        },
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      buildDefaultDragHandles: false,
      onReorderItem: _reorder,
      itemCount: _books.length,
      proxyDecorator: (child, index, animation) =>
          Material(elevation: 2, child: child),
      itemBuilder: (context, index) {
        final book = _books[index];
        return Column(
          key: ValueKey(book.id),
          mainAxisSize: MainAxisSize.min,
          children: [
            _ArrangeListTile(
              book: book,
              origin: _originLabel(book),
              checked: _selected.contains(book.id),
              dragEnabled: _dragEnabled,
              openInfoByTitle: _openInfoByTitle,
              onToggle: () => _toggleBook(book.id),
              onTitleTap: () => _openBookInfo(book),
              onDelete: () => _deleteOne(book),
              onGroup: () => _moveOneToGroup(book),
              onReorder: _dragEnabled
                  ? ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
            ),
            const Divider(height: 1, thickness: 0.5),
          ],
        );
      },
    );
  }
}

/// 列表项 — 对齐 `item_arrange_book.xml`
class _ArrangeListTile extends StatelessWidget {
  const _ArrangeListTile({
    super.key,
    required this.book,
    required this.origin,
    required this.checked,
    required this.dragEnabled,
    required this.openInfoByTitle,
    required this.onToggle,
    required this.onTitleTap,
    required this.onDelete,
    required this.onGroup,
    this.onReorder,
  });

  final Book book;
  final String origin;
  final bool checked;
  final bool dragEnabled;
  final bool openInfoByTitle;
  final VoidCallback onToggle;
  final VoidCallback onTitleTap;
  final VoidCallback onDelete;
  final VoidCallback onGroup;
  final Widget? onReorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);

    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(value: checked, onChanged: (_) => onToggle()),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: openInfoByTitle
                                ? () {
                                    onTitleTap();
                                  }
                                : onToggle,
                            child: Text(
                              book.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        if (book.author.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              book.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: muted),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          origin,
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            book.group.isNotEmpty ? book.group : '未分组',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onGroup,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('分组', style: TextStyle(color: muted, fontSize: 13)),
              ),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('删除', style: TextStyle(color: muted, fontSize: 13)),
              ),
              if (dragEnabled && onReorder != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: onReorder,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
