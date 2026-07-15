import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/legado_refresh_indicator.dart';
import '../../widgets/read_badge.dart';
import '../book/book_info_page.dart';
import '../search/search_page.dart';

/// 书架 style2 — 3 列网格 + 分组 Drawer
class BookshelfStyle2Page extends StatefulWidget {
  const BookshelfStyle2Page({
    super.key,
    this.scrollController,
    this.onSwitchToList,
  });

  final ScrollController? scrollController;
  final VoidCallback? onSwitchToList;

  @override
  State<BookshelfStyle2Page> createState() => _BookshelfStyle2PageState();
}

class _BookshelfStyle2PageState extends State<BookshelfStyle2Page> {
  String _selectedGroup = '__all__';
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Book> _processBooks(List<Book> books) {
    if (_selectedGroup == '__all__') return books;
    return books.where((b) => b.group == _selectedGroup).toList();
  }

  Set<String> _getAllGroups(List<Book> books) =>
      books.map((b) => b.group).where((g) => g.isNotEmpty).toSet();

  void _addLocalBook() async {
    final b = await context.read<BookProvider>().importLocalBook();
    if (b != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已导入: ${b.name}')));
    }
  }

  void _openBook(Book book) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => BookInfoPage(book: book)),
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
            icon: const Icon(Icons.search),
            tooltip: '联合搜索',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (a) {
              if (a == 'add_local') _addLocalBook();
              if (a == 'list_layout') widget.onSwitchToList?.call();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'add_local',
                child: _MenuRow(Icons.file_open, '添加本地'),
              ),
              const PopupMenuItem(
                value: 'list_layout',
                child: _MenuRow(Icons.view_list, '列表布局'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<BookProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.books.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('书架空空如也'),
                ],
              ),
            );
          }

          final books = _processBooks(provider.books);
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
              child: GridView.builder(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: LegadoTokens.bookshelfGridCols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.52,
                ),
                itemCount: books.length,
                itemBuilder: (_, i) {
                  final book = books[i];
                  final updating = provider.isBookShelfUpdating(book.id);
                  return InkWell(
                    onTap: () => _openBook(book),
                    onLongPress: () => _confirmRemove(book),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              BookCover(
                                coverUrl: book.coverUrl,
                                author: book.author,
                                width: double.infinity,
                                radius: LegadoTokens.radiusCover,
                              ),
                              if (updating)
                                const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: LegadoShelfUpdatingIndicator(size: 22),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (book.author.isNotEmpty)
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        if (!updating) ReadBadge.fromBook(book),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _addLocalBook,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  const _MenuRow(this.icon, this.title);

  @override
  Widget build(BuildContext context) => Row(
    children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(title)],
  );
}
