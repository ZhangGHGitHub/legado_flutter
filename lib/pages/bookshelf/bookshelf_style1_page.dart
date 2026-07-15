import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/bookshelf_prefs.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/legado_refresh_indicator.dart';
import '../book/book_info_page.dart';
import '../search/search_page.dart';
import 'bookshelf_arrange_page.dart';

class BookshelfStyle1Page extends StatefulWidget {
  const BookshelfStyle1Page({
    super.key,
    this.scrollController,
    this.onSwitchToGrid,
  });

  final ScrollController? scrollController;
  final VoidCallback? onSwitchToGrid;

  @override
  State<BookshelfStyle1Page> createState() => _BookshelfStyle1PageState();
}

class _BookshelfStyle1PageState extends State<BookshelfStyle1Page> {
  String _selectedGroup = '__all__';
  bool _showGrouped = false;
  /// UI-7: 置顶书 ID（本地 prefs，不改引擎表结构）
  Set<String> _pinnedIds = {};
  List<String> _shelfOrder = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _showGrouped = prefs.getBool('shelf_show_grouped') ?? false;
      _pinnedIds = (prefs.getStringList('shelf_pinned_ids') ?? []).toSet();
    });
    final order = await BookshelfPrefs.loadBookOrder();
    if (!mounted) return;
    setState(() => _shelfOrder = order);
  }

  Future<void> _saveGrouped(bool v) async {
    (await SharedPreferences.getInstance()).setBool('shelf_show_grouped', v);
  }

  Future<void> _savePinned() async {
    (await SharedPreferences.getInstance()).setStringList(
      'shelf_pinned_ids',
      _pinnedIds.toList(),
    );
  }

  List<Book> _processBooks(List<Book> books) {
    var result = BookshelfPrefs.applyBookOrder(books, _shelfOrder, (b) => b.id);
    if (_selectedGroup != '__all__') {
      result = result.where((b) => b.group == _selectedGroup).toList();
    }
    // 置顶优先
    final pinned = <Book>[];
    final rest = <Book>[];
    for (final b in result) {
      if (_pinnedIds.contains(b.id)) {
        pinned.add(b);
      } else {
        rest.add(b);
      }
    }
    return [...pinned, ...rest];
  }

  Set<String> _getAllGroups(List<Book> books) =>
      books.map((b) => b.group).where((g) => g.isNotEmpty).toSet();

  void _showGroupManagement() {
    final books = context.read<BookProvider>().books;
    final groups = _getAllGroups(books);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _GroupSheet(
        books: books,
        groups: groups.toList()..sort(),
        currentGroup: _selectedGroup,
        showGrouped: _showGrouped,
        onGroupSelected: (g) {
          setState(() => _selectedGroup = g);
          Navigator.pop(context);
        },
        onToggleGrouped: (v) {
          setState(() {
            _showGrouped = v;
            _saveGrouped(v);
          });
        },
        onBookGroupChanged: (id, ng) async =>
            context.read<BookProvider>().updateBookGroup(id, ng),
      ),
    );
  }

  void _openArrange() async {
    final group = _selectedGroup == '__all__' ? null : _selectedGroup;
    final label = _selectedGroup == '__all__' ? '全部' : _selectedGroup;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookshelfArrangePage(
          groupFilter: group,
          groupLabel: label,
        ),
      ),
    );
    final order = await BookshelfPrefs.loadBookOrder();
    if (!mounted) return;
    setState(() => _shelfOrder = order);
  }

  void _addLocalBook() async {
    final b = await context.read<BookProvider>().importLocalBook();
    if (b != null && mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已导入: ${b.name}')));
  }

  void _cacheAllBooks() async {
    final provider = context.read<BookProvider>();
    final sources = context.read<SourceProvider>();
    final books = provider.books
        .where((b) => b.bookSourceUrl.isNotEmpty)
        .toList();
    if (books.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没有需要缓存的书籍')));
      return;
    }
    int c = 0;
    for (final book in books) {
      final s = sources.findSourceForBook(book);
      if (s == null) continue;
      try {
        await provider.loadChapters(book, source: s);
        await provider.downloadAllChapters(
          book.id,
          provider.currentChapters,
          s,
        );
        c++;
      } catch (_) {}
    }
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('缓存完成: $c/${books.length} 本书')));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 4,
            title: _buildGroupTabs(provider.books),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: '联合搜索',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (a) {
                  if (a == 'add_local') _addLocalBook();
                  if (a == 'cache_all') _cacheAllBooks();
                  if (a == 'group_mgmt') _showGroupManagement();
                  if (a == 'arrange') _openArrange();
                  if (a == 'grid_layout') widget.onSwitchToGrid?.call();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'add_local',
                    child: _MenuRow(Icons.file_open, '添加本地'),
                  ),
                  const PopupMenuItem(
                    value: 'cache_all',
                    child: _MenuRow(Icons.download, '缓存全部'),
                  ),
                  const PopupMenuItem(
                    value: 'group_mgmt',
                    child: _MenuRow(Icons.folder, '分组管理'),
                  ),
                  const PopupMenuItem(
                    value: 'arrange',
                    child: _MenuRow(Icons.tune, '书架管理'),
                  ),
                  const PopupMenuItem(
                    value: 'grid_layout',
                    child: _MenuRow(Icons.grid_view, '网格布局'),
                  ),
                ],
              ),
            ],
          ),
          body: _buildBody(provider),
          floatingActionButton: FloatingActionButton.small(
            onPressed: _addLocalBook,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(BookProvider provider) {
    if (provider.isLoading && provider.books.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final books = _processBooks(provider.books);
    if (provider.books.isEmpty) return _buildEmpty();
    if (books.isEmpty) {
      return Center(
        child: Text(
          _selectedGroup != '__all__' ? '此分组没有书籍' : '没有书籍',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return LegadoRefreshIndicator(
      enabled: books.isNotEmpty,
      onRefreshTriggered: () {
        final sources = context.read<SourceProvider>();
        unawaited(
          provider.refreshShelfToc(
            books,
            resolveSource: sources.findSourceForBook,
          ),
        );
      },
      child: ScrollConfiguration(
        behavior: LegadoScrollBehavior(
          overscrollColor: Theme.of(context).colorScheme.primary,
        ).copyWith(scrollbars: true),
        child: _showGrouped && _selectedGroup == '__all__'
            ? _buildGrouped(books, provider)
            : ListView.builder(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: books.length,
                itemBuilder: (_, i) => _BookItem(
                  book: books[i],
                  isPinned: _pinnedIds.contains(books[i].id),
                  isUpdating: provider.isBookShelfUpdating(books[i].id),
                  onTap: () => _openBook(books[i]),
                  onLongPress: () => _showBookActions(books[i]),
                ),
              ),
      ),
    );
  }

  /// 顶栏分组 Tab — 对齐 Jingshiro：左「全部」+ 自定义分组，选中态主题色下划线
  Widget _buildGroupTabs(List<Book> allBooks) {
    final groups = _getAllGroups(allBooks).toList()..sort();
    final entries = <(String id, String label)>[
      ('__all__', '全部'),
      ...groups.map((g) => (g, g)),
    ];
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onSurface;

    return SizedBox(
      height: kToolbarHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 8, right: 4),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final (id, label) = entries[i];
          final selected = _selectedGroup == id;
          return InkWell(
            onTap: () => setState(() => _selectedGroup = id),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? scheme.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? fg : fg.withValues(alpha: 0.72),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_outlined, size: 64, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            '书架空空如也',
            style: TextStyle(fontSize: 16, color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角 + 添加本地书籍',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildGrouped(List<Book> books, BookProvider provider) {
    final groups = <String, List<Book>>{};
    for (final b in books) {
      groups.putIfAbsent(b.group.isNotEmpty ? b.group : '未分组', () => []).add(b);
    }
    final sorted = groups.keys.toList()
      ..sort(
        (a, b) => a == '未分组'
            ? 1
            : b == '未分组'
            ? -1
            : a.compareTo(b),
      );
    return ListView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: sorted
          .map(
            (g) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    g,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                ...groups[g]!.map(
                  (b) => _BookItem(
                    book: b,
                    isPinned: _pinnedIds.contains(b.id),
                    isUpdating: provider.isBookShelfUpdating(b.id),
                    onTap: () => _openBook(b),
                    onLongPress: () => _showBookActions(b),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  void _openBook(Book book) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => BookInfoPage(book: book)),
  );

  Future<void> _togglePin(Book book) async {
    setState(() {
      if (_pinnedIds.contains(book.id)) {
        _pinnedIds.remove(book.id);
      } else {
        _pinnedIds.add(book.id);
      }
    });
    await _savePinned();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _pinnedIds.contains(book.id) ? '已置顶「${book.name}」' : '已取消置顶',
        ),
      ),
    );
  }

  Future<void> _moveBookGroup(Book book) async {
    final groups = _getAllGroups(context.read<BookProvider>().books).toList()
      ..sort();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '移动「${book.name}」到分组',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            ListTile(
              dense: true,
              title: const Text('未分组'),
              selected: book.group.isEmpty,
              onTap: () => Navigator.pop(ctx, ''),
            ),
            ...groups.map(
              (g) => ListTile(
                dense: true,
                title: Text(g),
                selected: book.group == g,
                onTap: () => Navigator.pop(ctx, g),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    await context.read<BookProvider>().updateBookGroup(book.id, chosen);
  }

  void _showBookActions(Book book) {
    final pinned = _pinnedIds.contains(book.id);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                book.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(pinned ? '取消置顶' : '置顶'),
              onTap: () {
                Navigator.pop(ctx);
                _togglePin(book);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('移动分组'),
              onTap: () {
                Navigator.pop(ctx);
                _moveBookGroup(book);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('详情'),
              onTap: () {
                Navigator.pop(ctx);
                _openBook(book);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('整理'),
              onTap: () {
                Navigator.pop(ctx);
                _openArrange();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('移除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmRemove(book);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(Book book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(book.name),
        content: const Text('从书架移除？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BookProvider>().removeBook(book.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }
}

// ── Book list item (对齐 Jingshiro 列表：封面 + 四行元数据 + 右侧未读角标) ──

class _BookItem extends StatelessWidget {
  final Book book;
  final bool isPinned;
  final bool isUpdating;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _BookItem({
    required this.book,
    this.isPinned = false,
    this.isUpdating = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    final mutedSoft = scheme.onSurface.withValues(alpha: 0.45);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(
              coverUrl: book.coverUrl,
              author: book.author,
              width: 64,
              height: 86,
              radius: 4,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isPinned) ...[
                        Icon(
                          Icons.push_pin,
                          size: 14,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          book.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _metaLine(
                    Icons.person_outline,
                    book.author.isNotEmpty ? book.author : '未知作者',
                    muted,
                  ),
                  const SizedBox(height: 4),
                  _metaLine(
                    Icons.access_time,
                    book.currentChapter?.isNotEmpty == true
                        ? book.currentChapter!
                        : '尚未开始阅读',
                    muted,
                  ),
                  const SizedBox(height: 4),
                  _metaLine(
                    Icons.explore_outlined,
                    book.lastChapter?.isNotEmpty == true
                        ? book.lastChapter!
                        : '暂无更新',
                    mutedSoft,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isUpdating
                ? const LegadoShelfUpdatingIndicator()
                : _UnreadBadge(book: book),
          ],
        ),
      ),
    );
  }

  Widget _metaLine(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }
}

/// 未读/更新角标 — 结构对齐 legado BadgeView；数量在无章节索引字段时尽力从章节名推算
class _UnreadBadge extends StatelessWidget {
  final Book book;
  const _UnreadBadge({required this.book});

  static final _numRe = RegExp(r'(\d{1,6})');

  static int? _chapterNum(String? s) {
    if (s == null || s.isEmpty) return null;
    final m = _numRe.firstMatch(s);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  @override
  Widget build(BuildContext context) {
    final last = book.lastChapter;
    final current = book.currentChapter;
    final lastNum = _chapterNum(last);
    final curNum = _chapterNum(current);
    final hasUpdate = last != null &&
        last.isNotEmpty &&
        last != current &&
        current != null &&
        current.isNotEmpty;

    int? unread;
    if (lastNum != null && curNum != null && lastNum > curNum) {
      unread = lastNum - curNum;
    } else if (hasUpdate) {
      unread = null; // 有更新但无法解析章节号时仍显示强调角标
    } else {
      return const SizedBox.shrink();
    }

    if (unread != null && unread <= 0 && !hasUpdate) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final highlight = hasUpdate;
    final bg = highlight
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.28);
    final fg = highlight ? scheme.onPrimary : scheme.onSurface;

    final label = unread != null && unread > 0
        ? (unread > 999 ? '999+' : '$unread')
        : '更新';

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ── Group management ──

class _GroupSheet extends StatefulWidget {
  final List<Book> books;
  final List<String> groups;
  final String currentGroup;
  final bool showGrouped;
  final ValueChanged<String> onGroupSelected;
  final ValueChanged<bool> onToggleGrouped;
  final Future<void> Function(String bookId, String newGroup)
  onBookGroupChanged;
  const _GroupSheet({
    required this.books,
    required this.groups,
    required this.currentGroup,
    required this.showGrouped,
    required this.onGroupSelected,
    required this.onToggleGrouped,
    required this.onBookGroupChanged,
  });
  @override
  State<_GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends State<_GroupSheet> {
  final _ctrl = TextEditingController();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => Container(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const Text(
                '分组管理',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('按分组显示'),
          value: widget.showGrouped,
          onChanged: widget.onToggleGrouped,
          dense: true,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            '选择分组',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView(
            children: [
              ListTile(
                dense: true,
                selected: widget.currentGroup == '__all__',
                title: const Text('全部书籍'),
                leading: const Icon(Icons.library_books, size: 20),
                onTap: () => widget.onGroupSelected('__all__'),
              ),
              ...widget.groups.map(
                (g) => ListTile(
                  dense: true,
                  selected: widget.currentGroup == g,
                  title: Text(g),
                  leading: const Icon(Icons.folder, size: 20),
                  onTap: () => widget.onGroupSelected(g),
                  trailing: Text(
                    '${widget.books.where((b) => b.group == g).length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: '新建分组',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () {
                  if (_ctrl.text.trim().isNotEmpty) {
                    widget.onGroupSelected(_ctrl.text.trim());
                    _ctrl.clear();
                  }
                },
                child: const Text('创建'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  const _MenuRow(this.icon, this.title);
  @override
  Widget build(BuildContext c) => Row(
    children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(title)],
  );
}
