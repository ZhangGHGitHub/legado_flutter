import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/book.dart';
import '../../models/book_source.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/bookshelf_prefs.dart';
import '../../services/book_group_store.dart';
import '../../services/local_book_service.dart';
import '../../theme/legado_chrome.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/book_group_manage_dialog.dart';
import '../../widgets/error_view.dart';
import '../../widgets/legado_refresh_indicator.dart';
import '../../widgets/legado_popup_menu.dart';
import '../../features/book/book_info_page.dart';
import '../cache/cache_book_page.dart';
import '../../pages/search/search_page.dart';
import 'bookshelf_arrange_page.dart';
import 'bookshelf_books_view.dart';
import 'bookshelf_config_dialog.dart';
import 'bookshelf_menu_actions.dart';
import 'bookshelf_overflow_menu.dart';

class BookshelfStyle1Page extends StatefulWidget {
  const BookshelfStyle1Page({
    super.key,
    this.scrollController,
    required this.config,
    this.onConfigChanged,
  });

  final ScrollController? scrollController;
  final BookshelfConfig config;
  final ValueChanged<BookshelfConfig>? onConfigChanged;

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
    var result = books;
    if (_selectedGroup != '__all__') {
      result = result.where((b) => b.group == _selectedGroup).toList();
    }
    return BookshelfPrefs.sortBooks(
      result,
      sortMode: widget.config.bookshelfSort,
      orderIds: _shelfOrder,
      pinnedIds: _pinnedIds,
    );
  }

  Set<String> _getAllGroups(List<Book> books) =>
      books.map((b) => b.group).where((g) => g.isNotEmpty).toSet();

  Future<void> _showGroupManagement() async {
    final books = context.read<BookProvider>().books;
    await BookGroupStore.syncNamesFromBooks(
      books.map((b) => b.group).where((g) => g.isNotEmpty),
    );
    if (!mounted) return;
    await showBookGroupManageDialog(context);
    if (!mounted) return;
    setState(() {});
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
          gridLayout: widget.config.isGrid,
        ),
      ),
    );
    final order = await BookshelfPrefs.loadBookOrder();
    if (!mounted) return;
    setState(() => _shelfOrder = order);
  }

  void _addLocalBook() async {
    try {
      final b = await context.read<BookProvider>().importLocalBook();
      if (b != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已导入: ${b.name}')));
      }
    } on LocalBookImportException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _updateToc() {
    final provider = context.read<BookProvider>();
    final sources = context.read<SourceProvider>();
    final books = _processBooks(provider.books);
    if (books.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有可更新的书籍')));
      return;
    }
    unawaited(_runTocUpdate(provider, books, sources.findSourceForBook));
  }

  Future<void> _runTocUpdate(
    BookProvider provider,
    List<Book> books,
    BookSource? Function(Book book) resolveSource,
  ) async {
    if (provider.isShelfUpdateRunning) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('正在更新目录…')));
    final result = await provider.refreshShelfToc(
      books,
      resolveSource: resolveSource,
      onlyUpdateRead: widget.config.onlyUpdateRead,
    );
    if (!mounted) return;
    final message =
        '目录更新完成：成功 ${result.updated}，失败 ${result.failed}，跳过 ${result.skipped}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: result.failed > 0 ? Colors.red : null,
      ),
    );
  }

  void _showStub(String action) {
    final label = BookshelfOverflowMenu.stubLabel(action);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('「$label」暂未实现')));
  }

  void _onOverflowSelected(String a) async {
    if (await BookshelfMenuActions.handle(context, a)) return;
    if (!mounted) return;
    switch (a) {
      case BookshelfOverflowMenu.updateToc:
        _updateToc();
      case BookshelfOverflowMenu.addLocal:
        _addLocalBook();
      case BookshelfOverflowMenu.arrange:
        _openArrange();
      case BookshelfOverflowMenu.cacheExport:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CacheBookPage(
              contentCache: context.read<BookProvider>().contentCache,
            ),
          ),
        );
      case BookshelfOverflowMenu.groupMgmt:
        _showGroupManagement();
      case BookshelfOverflowMenu.layout:
        _openLayoutConfig();
      case 'show_grouped':
        setState(() {
          _showGrouped = !_showGrouped;
          _saveGrouped(_showGrouped);
        });
      default:
        _showStub(a);
    }
  }

  Future<void> _openLayoutConfig() async {
    final next = await BookshelfConfigDialog.show(
      context,
      initial: widget.config,
    );
    if (next != null) widget.onConfigChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: LegadoChrome.appBarTitleStartPaddingOf(context),
            title: _buildGroupTabs(provider.books),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '刷新',
                onPressed: _updateToc,
              ),
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: '联合搜索',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                ),
              ),
              PopupMenuButton<String>(
                offset: legadoAppBarPopupOffset(context),
                icon: const Icon(Icons.more_vert),
                onSelected: _onOverflowSelected,
                itemBuilder: (ctx) => [
                  ...BookshelfOverflowMenu.items(ctx),
                  CheckedPopupMenuItem(
                    value: 'show_grouped',
                    checked: _showGrouped,
                    child: const Text('按分组显示'),
                  ),
                ],
              ),
            ],
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(BookProvider provider) {
    if (provider.isLoading && provider.books.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.loadError != null && provider.books.isEmpty) {
      return ErrorView(
        message: provider.loadError!,
        onRetry: () => provider.loadBooks(),
      );
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
        unawaited(_runTocUpdate(provider, books, sources.findSourceForBook));
      },
      child: ScrollConfiguration(
        behavior: LegadoScrollBehavior(
          overscrollColor: Theme.of(context).colorScheme.primary,
        ).copyWith(scrollbars: false),
        child: _showGrouped && _selectedGroup == '__all__'
            ? _buildGrouped(books, provider)
            : BookshelfBooksView(
                config: widget.config,
                books: books,
                pinnedIds: _pinnedIds,
                scrollController: widget.scrollController,
                isUpdating: provider.isBookShelfUpdating,
                onTap: _openBook,
                onLongPress: _showBookActions,
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
    final fg = scheme.onPrimary;
    final scale = LegadoChrome.toolbarScaleOf(context);
    final titleH = LegadoChrome.toolbarHeightOf(context);
    final fontSize = 16.0 * scale;
    // 与 AppBar.titleSpacing 叠加后再略留内边距
    final startPad = LegadoTokens.spacingSm;

    return SizedBox(
      height: titleH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: startPad, right: LegadoTokens.spacingXs),
        itemCount: entries.length,
        separatorBuilder: (_, _) =>
            SizedBox(width: LegadoTokens.spacingXs * scale.clamp(1.0, 1.5)),
        itemBuilder: (_, i) {
          final (id, label) = entries[i];
          final selected = _selectedGroup == id;
          return InkWell(
            onTap: () => setState(() => _selectedGroup = id),
            borderRadius: BorderRadius.circular(LegadoTokens.radiusSmall),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: 10 * scale.clamp(1.0, 1.4),
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? fg : Colors.transparent,
                    width: 2.5 * scale.clamp(1.0, 1.3),
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
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
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: scheme.outlineVariant,
          ),
          const SizedBox(height: LegadoTokens.spacingMd),
          Text(
            '书架空空如也',
            style: TextStyle(fontSize: 16, color: scheme.onSurface),
          ),
          const SizedBox(height: LegadoTokens.spacingSm),
          Text(
            '右上角菜单可「添加本地」，或搜索添加网络书籍',
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
    final cfg = widget.config;
    final margin = cfg.bookshelfMargin.toDouble();
    final slivers = <Widget>[];
    for (final g in sorted) {
      final list = groups[g]!;
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              margin > 0 ? margin : LegadoTokens.pageHorizontal,
              12,
              margin > 0 ? margin : LegadoTokens.pageHorizontal,
              LegadoTokens.spacingXs,
            ),
            child: Text(g, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      );
      if (cfg.isGrid) {
        final showName = cfg.showBookname != 1;
        final overlay = cfg.showBookname == 2;
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              margin > 0 ? margin : LegadoDimens.pageVertical,
              0,
              margin > 0 ? margin : LegadoDimens.pageVertical,
              8,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cfg.gridColumns,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: showName && !overlay ? 0.52 : 0.68,
              ),
              delegate: SliverChildBuilderDelegate((_, i) {
                final b = list[i];
                return BookshelfGridTile(
                  book: b,
                  config: cfg,
                  isUpdating: provider.isBookShelfUpdating(b.id),
                  onTap: () => _openBook(b),
                  onLongPress: () => _showBookActions(b),
                );
              }, childCount: list.length),
            ),
          ),
        );
      } else {
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: margin),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
                final b = list[i];
                return BookshelfListTile(
                  book: b,
                  config: cfg,
                  isPinned: _pinnedIds.contains(b.id),
                  isUpdating: provider.isBookShelfUpdating(b.id),
                  compact: cfg.isCompactList,
                  onTap: () => _openBook(b),
                  onLongPress: () => _showBookActions(b),
                );
              }, childCount: list.length),
            ),
          ),
        );
      }
    }
    final scrollView = CustomScrollView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: slivers,
    );
    if (!cfg.showBookshelfFastScroller) return scrollView;
    return Scrollbar(
      controller: widget.scrollController,
      thumbVisibility: true,
      child: scrollView,
    );
  }

  void _openBook(Book book) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BookInfoPage(book: book, openReaderImmediately: true),
    ),
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LegadoTokens.radiusCard),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LegadoTokens.pageHorizontal,
                14,
                LegadoTokens.pageHorizontal,
                LegadoTokens.spacingSm,
              ),
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LegadoTokens.radiusCard),
        ),
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
