import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/bookshelf/bookshelf_membership_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import '../../application/book/book_source_result_mapper.dart';
import '../../application/source_management/source_notifier.dart';
import '../../domain/ports/book_source_explore_port.dart';
import '../../providers/source_provider.dart';
import '../../widgets/book_list_tile.dart';
import '../../widgets/empty_state.dart';
import '../book/book_info_page.dart';

/// 发现分类书籍列表 — 对齐 book/explore
///
/// 已在书架的书从「可加入」结果中过滤掉；书架端口变化时即时刷新。
class ExploreListPage extends StatelessWidget {
  final BookSource source;
  final String exploreUrl;
  final String title;
  final BookshelfMembershipPort? membershipPort;

  const ExploreListPage({
    super.key,
    required this.source,
    required this.exploreUrl,
    required this.title,
    this.membershipPort,
  });

  @override
  Widget build(BuildContext context) {
    final sourceProvider = context.read<SourceProvider>();
    return riverpod.ProviderScope(
      overrides: [
        sourceControllerProvider.overrideWithValue(sourceProvider.controller),
      ],
      child: _ExploreListPageBody(
        source: source,
        exploreUrl: exploreUrl,
        title: title,
        membershipPort: membershipPort,
      ),
    );
  }
}

class _ExploreListPageBody extends riverpod.ConsumerStatefulWidget {
  const _ExploreListPageBody({
    required this.source,
    required this.exploreUrl,
    required this.title,
    this.membershipPort,
  });

  final BookSource source;
  final String exploreUrl;
  final String title;
  final BookshelfMembershipPort? membershipPort;

  @override
  riverpod.ConsumerState<_ExploreListPageBody> createState() =>
      _ExploreListPageState();
}

class _ExploreListPageState
    extends riverpod.ConsumerState<_ExploreListPageBody> {
  late final BookSourceExplorePort _explorePort;
  late final BookshelfMembershipPort _membershipPort;
  List<Book> _books = [];
  bool _loading = true;
  String? _error;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _explorePort = context.read<BookSourceExplorePort>();
    _membershipPort =
        widget.membershipPort ??
        Provider.of<BookshelfMembershipPort?>(context, listen: false) ??
        const EmptyBookshelfMembershipPort();
    _load();
  }

  BookSource _currentSource(List<BookSource> sources) {
    for (final source in sources) {
      if (source.bookSourceUrl == widget.source.bookSourceUrl) {
        return source;
      }
    }
    return widget.source;
  }

  /// 与详情页 `_isInShelf` 一致：先比 sourceUrl，再比书名。
  bool _isInShelf(Book book, List<Book> shelf) {
    for (final b in shelf) {
      if (book.sourceUrl.isNotEmpty &&
          b.sourceUrl.isNotEmpty &&
          b.sourceUrl == book.sourceUrl) {
        return true;
      }
      if (b.name == book.name) return true;
    }
    return false;
  }

  List<Book> _notInShelf(List<Book> shelf) =>
      _books.where((b) => !_isInShelf(b, shelf)).toList();

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _books = [];
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final source = _currentSource(ref.read(sourceNotifierProvider).sources);
    try {
      final results = await _explorePort.explore(
        source,
        widget.exploreUrl,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _books = mapBookSourceResults(results, source.bookSourceUrl);
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
    final source = _currentSource(
      ref.watch(sourceNotifierProvider.select((state) => state.sources)),
    );
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              source.bookSourceName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
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
          : ListenableBuilder(
              listenable: _membershipPort,
              builder: (context, _) {
                final visible = _notInShelf(_membershipPort.books);
                if (visible.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => _load(refresh: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.library_add_check_outlined,
                          title: '本页书籍均已在书架',
                          subtitle: '下拉可刷新发现列表',
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => _load(refresh: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      final book = visible[i];
                      return BookListTile(
                        book: book,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookInfoPage(book: book),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
