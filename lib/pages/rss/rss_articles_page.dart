import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/rss_article.dart';
import '../../models/rss_source.dart';
import '../../services/rss_service.dart';
import 'rss_read_page.dart';

/// RSS 文章列表 — 对齐 Jingshiro RssSortActivity / RssArticlesFragment。
class RssArticlesPage extends StatefulWidget {
  const RssArticlesPage({super.key, required this.source});

  final RssSource source;

  @override
  State<RssArticlesPage> createState() => _RssArticlesPageState();
}

class _RssArticlesPageState extends State<RssArticlesPage> {
  final _articles = <RssArticle>[];
  final _readLinks = <String>{};
  var _loading = true;
  var _loadingMore = false;
  String? _error;
  String? _nextUrl;
  var _page = 1;

  RssSource get source => widget.source;

  @override
  void initState() {
    super.initState();
    _loadRead();
    _refresh();
  }

  Future<void> _loadRead() async {
    final p = await SharedPreferences.getInstance();
    final key = 'rss_read_${Uri.encodeComponent(source.sourceUrl)}';
    final list = p.getStringList(key) ?? const [];
    if (mounted) setState(() => _readLinks.addAll(list));
  }

  Future<void> _markRead(RssArticle a) async {
    _readLinks.add(a.link);
    final p = await SharedPreferences.getInstance();
    final key = 'rss_read_${Uri.encodeComponent(source.sourceUrl)}';
    await p.setStringList(key, _readLinks.toList());
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
    });
    try {
      final sortUrl = source.sortUrl.isNotEmpty ? source.sortUrl : source.sourceUrl;
      final r = await RssService.getArticles(
        source: source,
        sortName: source.sourceName,
        sortUrl: sortUrl,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _articles
          ..clear()
          ..addAll(r.articles);
        _nextUrl = r.nextUrl;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _nextUrl == null || _nextUrl!.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final r = await RssService.getArticles(
        source: source,
        sortName: source.sourceName,
        sortUrl: _nextUrl!,
        page: ++_page,
      );
      if (!mounted) return;
      setState(() {
        _articles.addAll(r.articles);
        _nextUrl = r.nextUrl;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载更多失败: $e')),
      );
    }
  }

  Future<void> _openArticle(RssArticle article) async {
    await _markRead(article);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RssReadPage(source: source, article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(source.sourceName),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _refresh, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (_articles.isEmpty) {
      return const Center(child: Text('暂无文章'));
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
            _loadMore();
          }
          return false;
        },
        child: ListView.separated(
          itemCount: _articles.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (_, index) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            if (i >= _articles.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final a = _articles[i];
            final read = _readLinks.contains(a.link);
            return ListTile(
              leading: a.image != null && a.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        a.image!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.article_outlined, size: 40),
                      ),
                    )
                  : const Icon(Icons.article_outlined, size: 40),
              title: Text(
                a.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: read ? FontWeight.normal : FontWeight.w600,
                  color: read
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
              subtitle: Text(
                [
                  if (a.pubDate != null && a.pubDate!.isNotEmpty) a.pubDate!,
                  if (a.description != null && a.description!.isNotEmpty)
                    a.description!.replaceAll(RegExp(r'<[^>]+>'), ' ').trim(),
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _openArticle(a),
            );
          },
        ),
      ),
    );
  }
}
