import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import '../reader/reader_page.dart';

/// 书架页面
class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  bool _showSearch = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> _filterBooks(List<Book> books) {
    if (_searchQuery.isEmpty) return books;
    final q = _searchQuery.toLowerCase();
    return books.where((b) =>
      b.name.toLowerCase().contains(q) ||
      b.author.toLowerCase().contains(q)
    ).toList();
  }

  void _showMenuAction(String action) {
    switch (action) {
      case 'add_local':
        _addLocalBook();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_menuLabel(action)}（待实现）')),
        );
    }
  }

  String _menuLabel(String action) {
    switch (action) {
      case 'update_toc': return '更新目录';
      case 'add_local': return '添加本地';
      case 'remote_books': return '远程书籍';
      case 'add_url': return '添加网址';
      case 'shelf_mgmt': return '书架管理';
      case 'cache_export': return '缓存/导出';
      case 'group_mgmt': return '分组管理';
      case 'shelf_layout': return '书架布局';
      case 'export_list': return '导出书单';
      case 'import_list': return '导入书单';
      case 'logs': return '日志';
      default: return action;
    }
  }

  Future<void> _addLocalBook() async {
    final provider = context.read<BookProvider>();
    final book = await provider.importLocalBook();
    if (book != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导入: ${book.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索书架中的书...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('书架', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: !_showSearch,
        actions: [
          if (_showSearch)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _showSearch = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: '搜索书架',
              onPressed: () => setState(() => _showSearch = true),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: '更多',
              onSelected: _showMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'update_toc', child: _MenuTile(icon: Icons.update, title: '更新目录')),
                const PopupMenuItem(value: 'add_local', child: _MenuTile(icon: Icons.file_open, title: '添加本地')),
                const PopupMenuItem(value: 'remote_books', child: _MenuTile(icon: Icons.cloud_download, title: '远程书籍')),
                const PopupMenuItem(value: 'add_url', child: _MenuTile(icon: Icons.link, title: '添加网址')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'shelf_mgmt', child: _MenuTile(icon: Icons.shelves, title: '书架管理')),
                const PopupMenuItem(value: 'cache_export', child: _MenuTile(icon: Icons.cached, title: '缓存/导出')),
                const PopupMenuItem(value: 'group_mgmt', child: _MenuTile(icon: Icons.folder, title: '分组管理')),
                const PopupMenuItem(value: 'shelf_layout', child: _MenuTile(icon: Icons.grid_view, title: '书架布局')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'export_list', child: _MenuTile(icon: Icons.file_upload_outlined, title: '导出书单')),
                const PopupMenuItem(value: 'import_list', child: _MenuTile(icon: Icons.file_download_outlined, title: '导入书单')),
                const PopupMenuItem(value: 'logs', child: _MenuTile(icon: Icons.terminal, title: '日志')),
              ],
            ),
          ],
        ],
      ),

      body: Consumer<BookProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBooks = provider.books;
          final books = _filterBooks(allBooks);

          if (allBooks.isEmpty) {
            return _buildEmptyState();
          }

          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('未找到 "$_searchQuery"',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return _buildBookList(books);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('书架空空如也', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('去「发现」搜索添加书籍吧',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('去搜书'),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(List<Book> books) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: books.length,
      itemBuilder: (context, index) => _buildBookTile(books[index]),
    );
  }

  Widget _buildBookTile(Book book) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _openBook(book),
      onLongPress: () => _confirmRemove(book),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 左侧封面 ──
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 48,
                height: 64,
                child: book.coverUrl.isNotEmpty
                    ? Image.network(
                        book.coverUrl,
                        width: 48,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _coverPlaceholder(theme),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return _coverPlaceholder(theme);
                        },
                      )
                    : _coverPlaceholder(theme),
              ),
            ),
            const SizedBox(width: 14),
            // ── 右侧文字信息 ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 书名
                  Text(
                    book.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 作者
                  Text(
                    book.author.isNotEmpty ? book.author : '未知作者',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 阅读进度章节
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded,
                          size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          book.currentChapter ?? '尚未开始阅读',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // 最新章节
                  Row(
                    children: [
                      Icon(Icons.update,
                          size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          book.lastChapter?.isNotEmpty == true
                              ? book.lastChapter!
                              : '暂无更新',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 阅读进度圆环指示
            if (book.progress > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: book.progress,
                        strokeWidth: 3,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: theme.colorScheme.primary,
                      ),
                      Text(
                        '${(book.progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder(ThemeData theme) {
    return Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.book, size: 24, color: theme.colorScheme.primary),
    );
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
    );
  }

  void _confirmRemove(Book book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(book.name),
        content: const Text('从书架移除？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
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

/// 三点菜单的图标+文字瓦片
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _MenuTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
