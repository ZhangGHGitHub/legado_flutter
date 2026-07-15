import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../help/book_help.dart';
import '../../help/content_processor.dart';
import '../../models/chapter.dart';
import '../../providers/replace_provider.dart';
import '../../services/search_content_prefs.dart';
import 'search_content_result.dart';

/// 全文搜索（对齐 `activity_search_content.xml` + SearchContentActivity）
///
/// 范围：当前章始终可搜；其余章仅搜已文件缓存的正文（网络书未缓存章跳过，对齐 legado）。
class SearchContentPage extends StatefulWidget {
  final String bookId;
  final String bookName;
  final List<Chapter> chapters;
  final int durChapterIndex;
  final String currentChapterContent;
  final String? initialQuery;
  final List<SearchContentResult>? initialResults;
  final int initialResultIndex;

  const SearchContentPage({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.chapters,
    required this.durChapterIndex,
    required this.currentChapterContent,
    this.initialQuery,
    this.initialResults,
    this.initialResultIndex = 0,
  });

  static Future<SearchContentNavigate?> open(
    BuildContext context, {
    required String bookId,
    required String bookName,
    required List<Chapter> chapters,
    required int durChapterIndex,
    required String currentChapterContent,
    String? initialQuery,
    List<SearchContentResult>? initialResults,
    int initialResultIndex = 0,
  }) {
    return Navigator.push<SearchContentNavigate>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchContentPage(
          bookId: bookId,
          bookName: bookName,
          chapters: chapters,
          durChapterIndex: durChapterIndex,
          currentChapterContent: currentChapterContent,
          initialQuery: initialQuery,
          initialResults: initialResults,
          initialResultIndex: initialResultIndex,
        ),
      ),
    );
  }

  @override
  State<SearchContentPage> createState() => _SearchContentPageState();
}

class _SearchContentPageState extends State<SearchContentPage> {
  late final TextEditingController _queryCtrl;
  final ScrollController _scrollCtrl = ScrollController();
  final List<SearchContentResult> _results = [];
  bool _searching = false;
  bool _cancelled = false;
  int _resultCount = 0;
  SearchContentPrefs _prefs = SearchContentPrefs();

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.initialQuery ?? '');
    _loadPrefs();
    if (widget.initialResults != null && widget.initialResults!.isNotEmpty) {
      _results.addAll(widget.initialResults!);
      _resultCount = _results.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final i = widget.initialResultIndex.clamp(0, _results.length - 1);
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.jumpTo((i * 72.0).clamp(0.0, _scrollCtrl.position.maxScrollExtent));
        }
      });
    } else if ((widget.initialQuery ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startSearch(widget.initialQuery!.trim());
      });
    }
  }

  Future<void> _loadPrefs() async {
    _prefs = await SearchContentPrefs.load();
    if (mounted) setState(() {});
    if (!mounted) return;
    await context.read<ReplaceProvider>().loadRules();
  }

  Future<void> _toggleReplace(bool value) async {
    setState(() => _prefs.enableReplace = value);
    await _prefs.save();
    if (_queryCtrl.text.trim().isNotEmpty) {
      _startSearch(_queryCtrl.text.trim());
    }
  }

  Future<void> _toggleRegex(bool value) async {
    setState(() => _prefs.enableRegex = value);
    await _prefs.save();
    if (_queryCtrl.text.trim().isNotEmpty) {
      _startSearch(_queryCtrl.text.trim());
    }
  }

  String _prepareContent(String raw) {
    if (!_prefs.enableReplace) return raw;
    return ContentProcessor.instance.getContent(raw);
  }

  @override
  void dispose() {
    _cancelled = true;
    _queryCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _cancelled = false;
      _results.clear();
      _resultCount = 0;
    });

    final cachedIds = await BookHelp.listCachedChapterIds(widget.bookId);
    if (!mounted || _cancelled) return;

    for (var i = 0; i < widget.chapters.length; i++) {
      if (_cancelled || !mounted) break;
      final ch = widget.chapters[i];
      String? content;
      if (i == widget.durChapterIndex) {
        content = widget.currentChapterContent;
      } else {
        final san = BookHelp.sanitizeId(ch.id);
        if (!cachedIds.contains(san)) continue;
        content = await BookHelp.getCachedContent(widget.bookId, ch.id);
      }
      if (content == null || content.isEmpty) continue;
      if (content.startsWith('⚠️') || content.contains('（加载失败')) continue;

      content = _prepareContent(content);

      final hits = _searchInChapter(
        content: content,
        query: query,
        chapterTitle: ch.title,
        chapterIndex: i,
        useRegex: _prefs.enableRegex,
      );
      if (hits.isEmpty) continue;
      if (!mounted || _cancelled) break;
      setState(() {
        _results.addAll(hits);
        _resultCount = _results.length;
      });
      // 让 UI 有机会刷新
      await Future<void>.delayed(Duration.zero);
    }

    if (!mounted) return;
    if (_results.isEmpty && !_cancelled) {
      setState(() {
        _results.add(
          SearchContentResult(
            chapterTitle: '',
            query: '',
            resultText: '搜索内容为空，请检查净化或简繁设置',
            chapterIndex: -1,
            queryIndexInChapter: 0,
          ),
        );
      });
    }
    setState(() => _searching = false);
  }

  List<SearchContentResult> _searchInChapter({
    required String content,
    required String query,
    required String chapterTitle,
    required int chapterIndex,
    required bool useRegex,
  }) {
    final out = <SearchContentResult>[];
    if (useRegex) {
      RegExp? re;
      try {
        re = RegExp(query, multiLine: true);
      } catch (_) {
        return out;
      }
      var within = 0;
      for (final m in re.allMatches(content)) {
        final idx = m.start;
        final len = m.end - m.start;
        if (len <= 0) continue;
        out.add(
          SearchContentResult(
            chapterTitle: chapterTitle,
            query: m.group(0) ?? query,
            resultText: _snippet(content, idx, len),
            chapterIndex: chapterIndex,
            queryIndexInChapter: idx,
            resultCountWithinChapter: within,
          ),
        );
        within++;
      }
      return out;
    }

    var from = 0;
    var within = 0;
    while (true) {
      final idx = content.indexOf(query, from);
      if (idx < 0) break;
      out.add(
        SearchContentResult(
          chapterTitle: chapterTitle,
          query: query,
          resultText: _snippet(content, idx, query.length),
          chapterIndex: chapterIndex,
          queryIndexInChapter: idx,
          resultCountWithinChapter: within,
        ),
      );
      within++;
      from = idx + query.length;
    }
    return out;
  }

  String _snippet(String content, int index, int queryLen) {
    const length = 20;
    var po1 = index - length;
    var po2 = index + queryLen + length;
    if (po1 < 0) po1 = 0;
    if (po2 > content.length) po2 = content.length;
    return content.substring(po1, po2).replaceAll('\n', ' ');
  }

  void _openResult(SearchContentResult r, int index) {
    if (r.query.isEmpty || r.chapterIndex < 0) return;
    final list = _results.where((e) => e.query.isNotEmpty).toList();
    final i = list.indexWhere(
      (e) =>
          e.chapterIndex == r.chapterIndex &&
          e.queryIndexInChapter == r.queryIndexInChapter,
    );
    Navigator.pop(
      context,
      SearchContentNavigate(
        results: list,
        index: i >= 0 ? i : 0,
      ),
    );
  }

  InlineSpan _highlightSpan(SearchContentResult r, Color accent, Color text) {
    if (r.query.isEmpty) {
      return TextSpan(text: r.resultText, style: TextStyle(color: text, fontSize: 14));
    }
    final q = r.query;
    final t = r.resultText;
    var at = t.indexOf(q, 20);
    if (at < 0) at = t.indexOf(q);
    if (at < 0) {
      return TextSpan(
        children: [
          if (r.chapterTitle.isNotEmpty)
            TextSpan(
              text: '${r.chapterTitle} ',
              style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          TextSpan(text: t, style: TextStyle(color: text, fontSize: 14)),
        ],
      );
    }
    return TextSpan(
      children: [
        if (r.chapterTitle.isNotEmpty)
          TextSpan(
            text: '${r.chapterTitle} ',
            style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        TextSpan(text: t.substring(0, at), style: TextStyle(color: text, fontSize: 14)),
        TextSpan(
          text: q,
          style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        TextSpan(text: t.substring(at + q.length), style: TextStyle(color: text, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _queryCtrl,
          autofocus: widget.initialResults == null,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '搜索',
            border: InputBorder.none,
            isDense: true,
          ),
          onSubmitted: (v) => _startSearch(v.trim()),
        ),
        actions: [
          IconButton(
            tooltip: '搜索',
            icon: const Icon(Icons.search),
            onPressed: () => _startSearch(_queryCtrl.text.trim()),
          ),
          PopupMenuButton<String>(
            tooltip: '更多',
            onSelected: (v) {
              if (v == 'replace') {
                _toggleReplace(!_prefs.enableReplace);
              } else if (v == 'regex') {
                _toggleRegex(!_prefs.enableRegex);
              }
            },
            itemBuilder: (ctx) => [
              CheckedPopupMenuItem<String>(
                value: 'replace',
                checked: _prefs.enableReplace,
                child: const Text('净化'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'regex',
                checked: _prefs.enableRegex,
                child: const Text('正则'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView.separated(
              controller: _scrollCtrl,
              itemCount: _results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final r = _results[i];
                final isDur = r.chapterIndex == widget.durChapterIndex;
                return ListTile(
                  dense: true,
                  title: Text.rich(
                    _highlightSpan(r, accent, textColor),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: isDur && r.query.isNotEmpty,
                  onTap: () => _openResult(r, i),
                );
              },
            ),
          ),
          Material(
            elevation: 4,
            color: theme.colorScheme.surfaceContainerHigh,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '顶部',
                      icon: const Icon(Icons.arrow_drop_up),
                      onPressed: () {
                        if (_scrollCtrl.hasClients) {
                          _scrollCtrl.jumpTo(0);
                        }
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // 对齐：点击信息区弹出键盘
                          FocusScope.of(context).requestFocus(FocusNode());
                          // ignore: prefer_foreach — reopen keyboard via Search bar
                        },
                        child: Text(
                          '搜索结果: $_resultCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '底部',
                      icon: const Icon(Icons.arrow_drop_down),
                      onPressed: () {
                        if (_scrollCtrl.hasClients) {
                          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _searching
          ? FloatingActionButton.small(
              tooltip: '停止',
              onPressed: () {
                _cancelled = true;
                setState(() => _searching = false);
              },
              child: const Icon(Icons.stop),
            )
          : null,
    );
  }
}
