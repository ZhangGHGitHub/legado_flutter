import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../reader/reader_page.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});
  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  bool _showSearch = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGroup = '__all__';
  bool _showGrouped = false;

  @override
  void initState() { super.initState(); _loadPreferences(); }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _showGrouped = prefs.getBool('shelf_show_grouped') ?? false);
  }

  Future<void> _saveGrouped(bool v) async {
    (await SharedPreferences.getInstance()).setBool('shelf_show_grouped', v);
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  List<Book> _processBooks(List<Book> books) {
    var result = books;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((b) => b.name.toLowerCase().contains(q) || b.author.toLowerCase().contains(q)).toList();
    }
    if (_selectedGroup != '__all__') result = result.where((b) => b.group == _selectedGroup).toList();
    return result;
  }

  Set<String> _getAllGroups(List<Book> books) => books.map((b) => b.group).where((g) => g.isNotEmpty).toSet();

  void _showGroupManagement() {
    final books = context.read<BookProvider>().books;
    final groups = _getAllGroups(books);
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => _GroupSheet(books: books, groups: groups.toList()..sort(), currentGroup: _selectedGroup,
        showGrouped: _showGrouped, onGroupSelected: (g) { setState(() => _selectedGroup = g); Navigator.pop(context); },
        onToggleGrouped: (v) { setState(() { _showGrouped = v; _saveGrouped(v); }); },
        onBookGroupChanged: (id, ng) async => context.read<BookProvider>().updateBookGroup(id, ng),
      ),
    );
  }

  void _addLocalBook() async {
    final b = await context.read<BookProvider>().importLocalBook();
    if (b != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导入: ${b.name}')));
  }

  void _cacheAllBooks() async {
    final provider = context.read<BookProvider>();
    final sources = context.read<SourceProvider>();
    final books = provider.books.where((b) => b.bookSourceUrl.isNotEmpty).toList();
    if (books.isEmpty) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没有需要缓存的书籍'))); return; }
    int c = 0;
    for (final book in books) {
      final s = sources.findSourceForBook(book);
      if (s == null) continue;
      try { await provider.loadChapters(book, source: s); await provider.downloadAllChapters(book.id, provider.currentChapters, s); c++; } catch (_) {}
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('缓存完成: $c/${books.length} 本书')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(controller: _searchController, autofocus: true,
                decoration: const InputDecoration(hintText: '搜索', border: InputBorder.none), onChanged: (v) => setState(() => _searchQuery = v))
            : null,
        actions: [
          if (_showSearch)
            IconButton(icon: const Icon(Icons.close), onPressed: () { setState(() { _showSearch = false; _searchQuery = ''; _searchController.clear(); }); })
          else ...[
            IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _showSearch = true)),
            PopupMenuButton<String>(icon: const Icon(Icons.more_vert), onSelected: (a) {
              if (a == 'add_local') _addLocalBook();
              if (a == 'cache_all') _cacheAllBooks();
              if (a == 'group_mgmt') _showGroupManagement();
            }, itemBuilder: (_) => [
              const PopupMenuItem(value: 'add_local', child: _MenuRow(Icons.file_open, '添加本地')),
              const PopupMenuItem(value: 'cache_all', child: _MenuRow(Icons.download, '缓存全部')),
              const PopupMenuItem(value: 'group_mgmt', child: _MenuRow(Icons.folder, '分组管理')),
            ]),
          ],
        ],
      ),
      body: Consumer<BookProvider>(builder: (context, provider, _) {
        if (provider.isLoading && provider.books.isEmpty) return const Center(child: CircularProgressIndicator());
        final books = _processBooks(provider.books);
        if (provider.books.isEmpty) return _buildEmpty();
        if (books.isEmpty) return Center(child: Text(_selectedGroup != '__all__' ? '此分组没有书籍' : '未找到 "$_searchQuery"', style: TextStyle(color: Colors.grey[600])));
        return RefreshIndicator(
          onRefresh: () => provider.loadBooks(),
          child: _showGrouped && _selectedGroup == '__all__' ? _buildGrouped(books) : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: books.length,
            itemBuilder: (_, i) => _BookItem(book: books[i], onTap: () => _openBook(books[i]), onLongPress: () => _confirmRemove(books[i])),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.small(onPressed: _addLocalBook, child: const Icon(Icons.add)),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[300]),
    const SizedBox(height: 16), const Text('书架空空如也', style: TextStyle(fontSize: 16)),
    const SizedBox(height: 8), Text('点击右下角 + 添加本地书籍', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
  ]));

  Widget _buildGrouped(List<Book> books) {
    final groups = <String, List<Book>>{};
    for (final b in books) groups.putIfAbsent(b.group.isNotEmpty ? b.group : '未分组', () => []).add(b);
    final sorted = groups.keys.toList()..sort((a, b) => a == '未分组' ? 1 : b == '未分组' ? -1 : a.compareTo(b));
    return ListView(children: sorted.map((g) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(g, style: const TextStyle(fontWeight: FontWeight.w600))),
      ...groups[g]!.map((b) => _BookItem(book: b, onTap: () => _openBook(b), onLongPress: () => _confirmRemove(b))),
    ])).toList());
  }

  void _openBook(Book book) => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(book: book)));

  void _confirmRemove(Book book) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(book.name), content: const Text('从书架移除？'),
      actions: [ TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { Navigator.pop(ctx); context.read<BookProvider>().removeBook(book.id); }, style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('移除')) ]));
  }
}

// ── Book list item (matches original Legado layout) ──

class _BookItem extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _BookItem({required this.book, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      clipBehavior: Clip.antiAlias,
      elevation: 0.5,
      child: InkWell(
        onTap: onTap, onLongPress: onLongPress,
        child: Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 10), child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cover 132x176 proportion scaled: ~72x96 on mobile
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: SizedBox(width: 72, height: 96,
              child: book.coverUrl.isNotEmpty
                  ? Image.network(book.coverUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _Placeholder())
                  : _Placeholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Book name
            Text(book.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            // Author
            Row(children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[500]), const SizedBox(width: 4),
              Text(book.author.isNotEmpty ? book.author : '未知作者', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ]),
            const SizedBox(height: 4),
            // Current chapter
            Row(children: [
              Icon(Icons.menu_book, size: 14, color: Colors.grey[500]), const SizedBox(width: 4),
              Expanded(child: Text(book.currentChapter ?? '尚未开始阅读', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
            ]),
            const SizedBox(height: 4),
            // Latest chapter
            Row(children: [
              Icon(Icons.bookmark_border, size: 14, color: Colors.grey[400]), const SizedBox(width: 4),
              Expanded(child: Text(book.lastChapter?.isNotEmpty == true ? book.lastChapter! : '暂无更新', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]))),
            ]),
          ])),
        ])),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Center(child: Icon(Icons.book, size: 28, color: Colors.grey)));
}

// ── Group management ──

class _GroupSheet extends StatefulWidget {
  final List<Book> books; final List<String> groups; final String currentGroup; final bool showGrouped;
  final ValueChanged<String> onGroupSelected; final ValueChanged<bool> onToggleGrouped;
  final Future<void> Function(String bookId, String newGroup) onBookGroupChanged;
  const _GroupSheet({required this.books, required this.groups, required this.currentGroup, required this.showGrouped,
    required this.onGroupSelected, required this.onToggleGrouped, required this.onBookGroupChanged});
  @override State<_GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends State<_GroupSheet> {
  final _ctrl = TextEditingController();
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext ctx) => Container(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 8),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Row(children: [
        const Text('分组管理', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)), const Spacer(),
        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
      ])),
      const Divider(),
      SwitchListTile(title: const Text('按分组显示'), value: widget.showGrouped, onChanged: widget.onToggleGrouped, dense: true),
      Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 4), child: Text('选择分组', style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
      SizedBox(height: 120, child: ListView(children: [
        ListTile(dense: true, selected: widget.currentGroup == '__all__', title: const Text('全部书籍'), leading: const Icon(Icons.library_books, size: 20), onTap: () => widget.onGroupSelected('__all__')),
        ...widget.groups.map((g) => ListTile(dense: true, selected: widget.currentGroup == g, title: Text(g),
            leading: const Icon(Icons.folder, size: 20), onTap: () => widget.onGroupSelected(g),
            trailing: Text('${widget.books.where((b) => b.group == g).length}', style: TextStyle(fontSize: 12, color: Colors.grey[500])))),
      ])),
      const Divider(),
      Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), child: Row(children: [
        Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: '新建分组', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true))),
        const SizedBox(width: 8),
        FilledButton.tonal(onPressed: () { if (_ctrl.text.trim().isNotEmpty) { widget.onGroupSelected(_ctrl.text.trim()); _ctrl.clear(); } }, child: const Text('创建')),
      ])),
    ]));
}

class _MenuRow extends StatelessWidget {
  final IconData icon; final String title;
  const _MenuRow(this.icon, this.title);
  @override Widget build(BuildContext c) => Row(children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(title)]);
}
