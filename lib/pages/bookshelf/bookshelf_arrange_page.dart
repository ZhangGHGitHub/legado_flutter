import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/bookshelf_prefs.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/book_cover.dart';

/// 书架整理 — 对齐 legado [BookshelfManageActivity] + `activity_arrange_book.xml`
class BookshelfArrangePage extends StatefulWidget {
  const BookshelfArrangePage({
    super.key,
    this.groupFilter,
    this.groupLabel = '全部',
    this.gridLayout = false,
  });

  /// 空 = 全部书籍；否则仅显示该分组
  final String? groupFilter;
  final String groupLabel;

  /// 与当前书架布局一致：false=列表整理，true=网格整理
  final bool gridLayout;

  @override
  State<BookshelfArrangePage> createState() => _BookshelfArrangePageState();
}

class _BookshelfArrangePageState extends State<BookshelfArrangePage> {
  final _searchCtrl = TextEditingController();
  final _selected = <String>{};
  List<Book> _books = [];
  bool _gridLayout = false;
  bool _dragEnabled = true;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _gridLayout = widget.gridLayout;
    _loadSortMode();
    _loadOrderAndBooks();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSortMode() async {
    final mode = await BookshelfPrefs.loadSortMode();
    if (!mounted) return;
    setState(() => _dragEnabled = mode == 3);
  }

  void _initBooks() {
    var all = context.read<BookProvider>().books;
    if (widget.groupFilter != null && widget.groupFilter!.isNotEmpty) {
      all = all.where((b) => b.group == widget.groupFilter).toList();
    } else if (widget.groupFilter == '') {
      all = all.where((b) => b.group.isEmpty).toList();
    }
    _books = BookshelfPrefs.applyBookOrder(all, _cachedOrder, (b) => b.id);
    _selected
      ..clear()
      ..addAll(_books.map((b) => b.id));
  }

  List<String> _cachedOrder = [];

  Future<void> _loadOrderAndBooks() async {
    _cachedOrder = await BookshelfPrefs.loadBookOrder();
    if (!mounted) return;
    setState(_initBooks);
  }

  List<Book> get _visibleBooks {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _books;
    return _books.where((b) {
      return b.name.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.group.toLowerCase().contains(q);
    }).toList();
  }

  String _originLabel(Book book) {
    if (book.type == 'local' || book.bookSourceUrl.isEmpty) {
      return '本地书籍';
    }
    final src = context.read<SourceProvider>().findSourceForBook(book);
    return src?.bookSourceName ?? book.bookSourceUrl;
  }

  Future<void> _persistOrder() async {
    await BookshelfPrefs.saveBookOrder(_books.map((b) => b.id).toList());
    await BookshelfPrefs.saveSortMode(3);
    _dirty = false;
  }

  Future<bool> _onWillPop() async {
    if (_dirty) await _persistOrder();
    return true;
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
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _books.removeAt(oldIndex);
      _books.insert(newIndex, item);
      _dirty = true;
    });
  }

  Future<void> _moveSelectedToGroup() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    final chosen = await _pickGroup();
    if (chosen == null || !mounted) return;
    await context.read<BookProvider>().updateBooksGroup(ids, chosen);
    setState(_initBooks);
  }

  Future<void> _moveOneToGroup(Book book) async {
    final chosen = await _pickGroup(current: book.group);
    if (chosen == null || !mounted) return;
    await context.read<BookProvider>().updateBookGroup(book.id, chosen);
    setState(_initBooks);
  }

  Future<String?> _pickGroup({String? current}) async {
    final books = context.read<BookProvider>().books;
    final groups = books
        .map((b) => b.group)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '选择分组',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            ListTile(
              dense: true,
              title: const Text('未分组'),
              selected: current == null || current.isEmpty,
              onTap: () => Navigator.pop(ctx, ''),
            ),
            ...groups.map(
              (g) => ListTile(
                dense: true,
                title: Text(g),
                selected: current == g,
                onTap: () => Navigator.pop(ctx, g),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
    await context.read<BookProvider>().removeBooks(ids);
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
    await context.read<BookProvider>().removeBook(book.id);
    setState(() {
      _books.removeWhere((b) => b.id == book.id);
      _selected.remove(book.id);
      _dirty = true;
    });
    await _persistOrder();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleBooks;
    final scheme = Theme.of(context).colorScheme;

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
          title: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: '筛选 • ${widget.groupLabel}',
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.55),
                fontSize: 16,
              ),
              isDense: true,
            ),
            style: TextStyle(color: scheme.onSurface, fontSize: 16),
          ),
          actions: [
            IconButton(
              tooltip: _gridLayout ? '列表整理' : '网格整理',
              icon: Icon(_gridLayout ? Icons.view_list : Icons.grid_view),
              onPressed: () => setState(() => _gridLayout = !_gridLayout),
            ),
            PopupMenuButton<String>(
              tooltip: '选择',
              onSelected: (a) {
                if (a == 'all') _toggleAll(true);
                if (a == 'none') _toggleAll(false);
                if (a == 'invert') _invertSelection();
                if (a == 'interval') _selectInterval();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'all', child: Text('全选')),
                PopupMenuItem(value: 'none', child: Text('取消全选')),
                PopupMenuItem(value: 'invert', child: Text('反选')),
                PopupMenuItem(value: 'interval', child: Text('选择区间')),
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
            : _gridLayout
            ? _buildGridBody(visible)
            : _buildListBody(visible),
        bottomNavigationBar: _ArrangeActionBar(
          selectedCount: _selected.length,
          totalCount: visible.length,
          onMoveToGroup: _moveSelectedToGroup,
          onDelete: _deleteSelected,
        ),
      ),
    );
  }

  Widget _buildListBody(List<Book> visible) {
    final filtering = _searchCtrl.text.trim().isNotEmpty;
    if (filtering) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final book = visible[index];
          return _ArrangeListTile(
            key: ValueKey(book.id),
            book: book,
            origin: _originLabel(book),
            checked: _selected.contains(book.id),
            dragEnabled: false,
            onToggle: () => _toggleBook(book.id),
            onDelete: () => _deleteOne(book),
            onGroup: () => _moveOneToGroup(book),
          );
        },
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      buildDefaultDragHandles: false,
      onReorder: _reorder,
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        return _ArrangeListTile(
          key: ValueKey(book.id),
          book: book,
          origin: _originLabel(book),
          checked: _selected.contains(book.id),
          dragEnabled: _dragEnabled,
          onToggle: () => _toggleBook(book.id),
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
        );
      },
    );
  }

  Widget _buildGridBody(List<Book> visible) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: LegadoTokens.bookshelfGridCols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
        childAspectRatio: 0.58,
      ),
      itemCount: visible.length,
      itemBuilder: (_, index) {
        final book = visible[index];
        return _ArrangeGridTile(
          key: ValueKey(book.id),
          book: book,
          checked: _selected.contains(book.id),
          onToggle: () => _toggleBook(book.id),
          onLongPress: _dragEnabled
              ? () => _showGridMoveSheet(book)
              : null,
        );
      },
    );
  }

  void _showGridMoveSheet(Book book) {
    final idx = _books.indexWhere((b) => b.id == book.id);
    if (idx < 0) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(book.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: const Text('调整位置'),
            ),
            ListTile(
              leading: const Icon(Icons.vertical_align_top),
              title: const Text('移到最前'),
              onTap: () {
                Navigator.pop(ctx);
                _reorder(idx, 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('上移'),
              enabled: idx > 0,
              onTap: () {
                Navigator.pop(ctx);
                if (idx > 0) _reorder(idx, idx - 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('下移'),
              enabled: idx < _books.length - 1,
              onTap: () {
                Navigator.pop(ctx);
                if (idx < _books.length - 1) _reorder(idx, idx + 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.vertical_align_bottom),
              title: const Text('移到最后'),
              onTap: () {
                Navigator.pop(ctx);
                _reorder(idx, _books.length);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
    required this.onToggle,
    required this.onDelete,
    required this.onGroup,
    this.onReorder,
  });

  final Book book;
  final String origin;
  final bool checked;
  final bool dragEnabled;
  final VoidCallback onToggle;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: checked, onChanged: (_) => onToggle()),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
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
                        Text(origin, style: TextStyle(fontSize: 12, color: muted)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            book.group.isNotEmpty ? book.group : '无分组',
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
                child: Text('分组', style: TextStyle(color: muted, fontSize: 13)),
              ),
              TextButton(
                onPressed: onDelete,
                child: Text('删除', style: TextStyle(color: muted, fontSize: 13)),
              ),
              if (dragEnabled && onReorder != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 8),
                  child: onReorder,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrangeGridTile extends StatelessWidget {
  const _ArrangeGridTile({
    super.key,
    required this.book,
    required this.checked,
    required this.onToggle,
    this.onLongPress,
  });

  final Book book;
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: BookCover(
                  coverUrl: book.coverUrl,
                  author: book.author,
                  width: double.infinity,
                  radius: LegadoTokens.radiusCover,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Positioned(
            left: 2,
            top: 2,
            child: Material(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
              child: Checkbox(
                value: checked,
                onChanged: (_) => onToggle(),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 底栏 — 对齐 legado [SelectActionBar]
class _ArrangeActionBar extends StatelessWidget {
  const _ArrangeActionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.onMoveToGroup,
    required this.onDelete,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onMoveToGroup;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = selectedCount > 0;

    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Text(
                '$selectedCount / $totalCount',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: enabled ? onMoveToGroup : null,
                child: const Text('移动到分组'),
              ),
              PopupMenuButton<String>(
                enabled: enabled,
                onSelected: (a) {
                  if (a == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
