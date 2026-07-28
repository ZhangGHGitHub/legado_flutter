import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/book_group_store.dart';
import '../../services/bookshelf_prefs.dart';
import '../../services/local_book_service.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/book_group_manage_dialog.dart';
import '../../widgets/error_view.dart';
import '../../widgets/legado_refresh_indicator.dart';
import '../../widgets/legado_popup_menu.dart';
import '../../features/book/book_info_page.dart';
import '../../pages/cache/cache_book_page.dart';
import '../../pages/search/search_page.dart';
import 'bookshelf_arrange_page.dart';
import 'bookshelf_books_view.dart';
import 'bookshelf_config_dialog.dart';
import 'bookshelf_menu_actions.dart';
import 'bookshelf_overflow_menu.dart';

/// 书架 style2 — Folder（Drawer）chrome；body 随 bookshelfLayout 变化
class BookshelfStyle2Page extends StatefulWidget {
  const BookshelfStyle2Page({
    super.key,
    this.scrollController,
    required this.config,
    this.onConfigChanged,
  });

  final ScrollController? scrollController;
  final BookshelfConfig config;
  final ValueChanged<BookshelfConfig>? onConfigChanged;

  @override
  State<BookshelfStyle2Page> createState() => _BookshelfStyle2PageState();
}

class _BookshelfStyle2PageState extends State<BookshelfStyle2Page> {
  String _selectedGroup = '__all__';
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<String> _shelfOrder = [];

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final order = await BookshelfPrefs.loadBookOrder();
    if (!mounted) return;
    setState(() => _shelfOrder = order);
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
      pinnedIds: const {},
    );
  }

  Set<String> _getAllGroups(List<Book> books) =>
      books.map((b) => b.group).where((g) => g.isNotEmpty).toSet();

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
    await _loadOrder();
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
    unawaited(
      provider.refreshShelfToc(
        books,
        resolveSource: sources.findSourceForBook,
        onlyUpdateRead: widget.config.onlyUpdateRead,
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('正在更新目录…')));
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
          MaterialPageRoute(builder: (_) => const CacheBookPage()),
        );
      case BookshelfOverflowMenu.groupMgmt:
        _showGroupManagement();
      case BookshelfOverflowMenu.layout:
        _openLayoutConfig();
      default:
        _showStub(a);
    }
  }

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

  Future<void> _openLayoutConfig() async {
    final next = await BookshelfConfigDialog.show(
      context,
      initial: widget.config,
    );
    if (next != null) widget.onConfigChanged?.call(next);
  }

  void _openBook(Book book) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BookInfoPage(book: book, openReaderImmediately: true),
    ),
  );

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

  Widget _buildDrawer(List<Book> allBooks) {
    final groups = _getAllGroups(allBooks).toList()..sort();
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Text('书架分组', style: TextStyle(fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('全部书籍'),
              selected: _selectedGroup == '__all__',
              onTap: () {
                setState(() => _selectedGroup = '__all__');
                Navigator.pop(context);
              },
            ),
            ...groups.map(
              (g) => ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(g),
                selected: _selectedGroup == g,
                trailing: Text(
                  '${allBooks.where((b) => b.group == g).length}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                onTap: () {
                  setState(() => _selectedGroup = g);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Consumer<BookProvider>(
        builder: (context, provider, _) => _buildDrawer(provider.books),
      ),
      appBar: AppBar(
        title: Text(_selectedGroup == '__all__' ? '书架' : _selectedGroup),
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
            itemBuilder: (ctx) => BookshelfOverflowMenu.items(ctx),
          ),
        ],
      ),
      body: Consumer<BookProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadError != null && provider.books.isEmpty) {
            return ErrorView(
              message: provider.loadError!,
              onRetry: () => provider.loadBooks(),
            );
          }
          if (provider.books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: LegadoTokens.spacingMd),
                  const Text('书架空空如也'),
                ],
              ),
            );
          }

          final books = _processBooks(provider.books);
          if (books.isEmpty) {
            return Center(
              child: Text('此分组没有书籍', style: TextStyle(color: Colors.grey[600])),
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
                  onlyUpdateRead: widget.config.onlyUpdateRead,
                ),
              );
            },
            child: ScrollConfiguration(
              behavior: LegadoScrollBehavior(
                overscrollColor: Theme.of(context).colorScheme.primary,
              ).copyWith(scrollbars: false),
              child: BookshelfBooksView(
                config: widget.config,
                books: books,
                pinnedIds: const {},
                scrollController: widget.scrollController,
                isUpdating: provider.isBookShelfUpdating,
                onTap: _openBook,
                onLongPress: _confirmRemove,
              ),
            ),
          );
        },
      ),
    );
  }
}
