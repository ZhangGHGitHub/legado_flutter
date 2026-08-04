import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import '../../domain/ports/chapter_content_cache_port.dart';
import '../../application/bookshelf/book_group_store_port.dart';
import '../../application/bookshelf/bookshelf_arrange_delete_command_port.dart';
import '../../application/bookshelf/bookshelf_display_port.dart';
import '../../application/bookshelf/bookshelf_display_state_port.dart';
import '../../application/bookshelf/bookshelf_local_book_port.dart';
import '../../application/bookshelf/bookshelf_toc_refresh_port.dart';
import '../../application/bookshelf/bookshelf_notifier.dart';
import '../../application/source_management/source_notifier.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/book_group_manage_dialog.dart';
import '../../widgets/error_view.dart';
import '../../widgets/legado_refresh_indicator.dart';
import '../../widgets/legado_popup_menu.dart';
import '../../features/book/book_info_page.dart';
import '../cache/cache_book_page.dart';
import '../search/search_page.dart';
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
    this.displayPort,
    this.displayStatePort,
    this.groupStorePort,
    this.localBookPort,
    this.tocRefreshPort,
  });

  final ScrollController? scrollController;
  final BookshelfConfig config;
  final ValueChanged<BookshelfConfig>? onConfigChanged;
  final BookshelfDisplayPort? displayPort;
  final BookshelfDisplayStatePort? displayStatePort;
  final BookGroupStorePort? groupStorePort;
  final BookshelfLocalBookPort? localBookPort;
  final BookshelfTocRefreshPort? tocRefreshPort;

  @override
  State<BookshelfStyle2Page> createState() => _BookshelfStyle2PageState();
}

class _BookshelfStyle2PageState extends State<BookshelfStyle2Page> {
  String _selectedGroup = '__all__';
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<String> _shelfOrder = [];
  late final BookshelfDisplayPort _displayPort;
  late final BookshelfDisplayStatePort _displayStatePort;
  late final BookGroupStorePort _groupStorePort;
  late final BookshelfLocalBookPort _localBookPort;
  late final BookshelfTocRefreshPort _tocRefreshPort;

  @override
  void initState() {
    super.initState();
    _displayPort =
        widget.displayPort ??
        Provider.of<BookshelfDisplayPort?>(context, listen: false) ??
        const InMemoryBookshelfDisplayPort();
    _displayStatePort =
        widget.displayStatePort ??
        Provider.of<BookshelfDisplayStatePort?>(context, listen: false) ??
        const EmptyBookshelfDisplayStatePort();
    _groupStorePort =
        widget.groupStorePort ?? context.read<BookGroupStorePort>();
    _localBookPort =
        widget.localBookPort ?? context.read<BookshelfLocalBookPort>();
    _tocRefreshPort =
        widget.tocRefreshPort ??
        Provider.of<BookshelfTocRefreshPort?>(context, listen: false) ??
        const EmptyBookshelfTocRefreshPort();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final order = await _displayPort.loadBookOrder();
    if (!mounted) return;
    setState(() => _shelfOrder = order);
  }

  List<Book> _processBooks(List<Book> books) {
    var result = books;
    if (_selectedGroup != '__all__') {
      result = result.where((b) => b.group == _selectedGroup).toList();
    }
    return _displayPort.sortBooks(
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
      final b = await _localBookPort.importLocalBook();
      if (b != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已导入: ${b.name}')));
      }
    } on BookshelfLocalBookImportException catch (e) {
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

  void _updateToc(List<Book> bookshelfBooks, SourceNotifier sourceNotifier) {
    final books = _processBooks(bookshelfBooks);
    if (books.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有可更新的书籍')));
      return;
    }
    unawaited(_runTocUpdate(books, sourceNotifier.findSourceForBook));
  }

  Future<void> _runTocUpdate(
    List<Book> books,
    BookSource? Function(Book book) resolveSource,
  ) async {
    if (_tocRefreshPort.isRunning) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('正在更新目录…')));
    final result = await _tocRefreshPort.refresh(
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

  void _onOverflowSelected(
    String a,
    SourceNotifier sourceNotifier,
    List<Book> bookshelfBooks,
  ) async {
    if (await BookshelfMenuActions.handle(context, a)) return;
    if (!mounted) return;
    switch (a) {
      case BookshelfOverflowMenu.updateToc:
        _updateToc(bookshelfBooks, sourceNotifier);
      case BookshelfOverflowMenu.addLocal:
        _addLocalBook();
      case BookshelfOverflowMenu.arrange:
        _openArrange();
      case BookshelfOverflowMenu.cacheExport:
        final contentCache = Provider.of<ChapterContentCachePort?>(
          context,
          listen: false,
        );
        if (contentCache == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('缓存引擎不可用')));
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CacheBookPage(contentCache: contentCache),
          ),
        );
      case BookshelfOverflowMenu.groupMgmt:
        _showGroupManagement(bookshelfBooks);
      case BookshelfOverflowMenu.layout:
        _openLayoutConfig();
      default:
        _showStub(a);
    }
  }

  Future<void> _showGroupManagement(List<Book> books) async {
    await _groupStorePort.syncNamesFromBooks(
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
              unawaited(
                context.read<BookshelfArrangeDeleteCommandPort>().removeBook(
                  book.id,
                ),
              );
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
    return riverpod.Consumer(
      builder: (context, ref, _) {
        final sourceNotifier = ref.read(sourceNotifierProvider.notifier);
        final bookshelfState = ref.watch(bookshelfNotifierProvider);
        final bookshelfBooks = bookshelfState.books;
        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(bookshelfBooks),
          appBar: AppBar(
            title: Text(_selectedGroup == '__all__' ? '书架' : _selectedGroup),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '刷新',
                onPressed: () => _updateToc(bookshelfBooks, sourceNotifier),
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
                onSelected: (value) =>
                    _onOverflowSelected(value, sourceNotifier, bookshelfBooks),
                itemBuilder: (ctx) => BookshelfOverflowMenu.items(ctx),
              ),
            ],
          ),
          body: ListenableBuilder(
            listenable: _displayStatePort,
            builder: (context, _) {
              if ((bookshelfState.isInitialLoading ||
                      _displayStatePort.isLoading) &&
                  bookshelfBooks.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (bookshelfState.hasError && bookshelfBooks.isEmpty) {
                return ErrorView(
                  message: bookshelfState.error?.toString() ?? '加载书架失败',
                  onRetry: _displayStatePort.reload,
                );
              }
              if (bookshelfBooks.isEmpty) {
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

              final books = _processBooks(bookshelfBooks);
              if (books.isEmpty) {
                return Center(
                  child: Text(
                    '此分组没有书籍',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return LegadoRefreshIndicator(
                enabled: books.isNotEmpty,
                onRefreshTriggered: () {
                  unawaited(
                    _runTocUpdate(books, sourceNotifier.findSourceForBook),
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
                    isUpdating: _displayStatePort.isBookUpdating,
                    onTap: _openBook,
                    onLongPress: _confirmRemove,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
