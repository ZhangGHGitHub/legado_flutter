import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../models/book_source.dart';
import '../../services/book_source_service.dart';
import '../../widgets/book_list_tile.dart';
import '../book/book_info_page.dart';

/// 发现分类书籍列表 — 对齐 book/explore
class ExploreListPage extends StatefulWidget {
  final BookSource source;
  final String exploreUrl;
  final String title;

  const ExploreListPage({
    super.key,
    required this.source,
    required this.exploreUrl,
    required this.title,
  });

  @override
  State<ExploreListPage> createState() => _ExploreListPageState();
}

class _ExploreListPageState extends State<ExploreListPage> {
  final _service = BookSourceService();
  List<Book> _books = [];
  bool _loading = true;
  String? _error;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _books = [];
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await _service.explore(
        widget.source,
        widget.exploreUrl,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _books = _service.resultsToBooks(results, widget.source.bookSourceUrl);
        _loading = false;
        if (_books.isEmpty) _error = '此分类暂无书籍';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '加载失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              widget.source.bookSourceName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                    onPressed: () => _load(refresh: true),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _load(refresh: true),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _books.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final book = _books[i];
                  return BookListTile(
                    book: book,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BookInfoPage(book: book)),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
