import 'package:flutter/material.dart';

import '../../help/book_help.dart';
import '../../help/bookmark_hint.dart';
import '../../models/chapter.dart';
import '../../services/note_service.dart';
import '../../src/rust/api.dart' as rust_api;

/// 选中章节；[pageIndex]/[chapterPos] 为书签回跳参数。
typedef TocChapterTap = void Function(
  Chapter chapter, {
  int? pageIndex,
  int? chapterPos,
});

/// 章节目录页 — 对齐 Legado `ChapterList` / `activity_chapter_list`
/// （顶栏返回+目录/书签 Tab+搜索+菜单；缓存字数 / 未缓存云标；底栏进度+顶底跳转）
class TocSheet extends StatefulWidget {
  final List<Chapter> chapters;
  final String? currentChapter;
  final String? currentChapterId;
  final String? bookId;
  final TocChapterTap onChapterTap;

  const TocSheet({
    super.key,
    required this.chapters,
    this.currentChapter,
    this.currentChapterId,
    this.bookId,
    required this.onChapterTap,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Chapter> chapters,
    String? currentChapter,
    String? currentChapterId,
    String? bookId,
    required TocChapterTap onChapterTap,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TocSheet(
          chapters: chapters,
          currentChapter: currentChapter,
          currentChapterId: currentChapterId,
          bookId: bookId,
          onChapterTap: onChapterTap,
        ),
      ),
    );
  }

  @override
  State<TocSheet> createState() => _TocSheetState();
}

class _TocSheetState extends State<TocSheet>
    with SingleTickerProviderStateMixin {
  static const double _rowCached = 64;
  static const double _rowPlain = 52;

  bool _reversed = false;
  bool _searching = false;
  String _query = '';
  int _tabIndex = 0;
  late final TabController _tabController;
  late final TextEditingController _searchController;
  late final ScrollController _chapterScroll;
  late final ScrollController _bookmarkScroll;
  List<rust_api.NoteDto> _bookmarks = [];
  Map<String, int> _wordCounts = {};
  Set<String> _cachedIds = {};
  bool _didScrollToCurrent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController = TextEditingController();
    _chapterScroll = ScrollController();
    _bookmarkScroll = ScrollController();
    _loadBookmarks();
    _loadCacheMeta();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabIndex != _tabController.index) {
      setState(() => _tabIndex = _tabController.index);
      if (_tabIndex == 0) {
        _didScrollToCurrent = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _chapterScroll.dispose();
    _bookmarkScroll.dispose();
    super.dispose();
  }

  void _loadBookmarks() {
    final bookId = widget.bookId;
    if (bookId == null || bookId.isEmpty || !NoteService.isReady) {
      _bookmarks = [];
      return;
    }
    _bookmarks = NoteService.list(bookId: bookId)
        .where((n) => n.noteContent.startsWith('书签'))
        .toList();
  }

  Future<void> _loadCacheMeta() async {
    final bookId = widget.bookId;
    if (bookId == null || bookId.isEmpty) return;
    final ids = await BookHelp.listCachedChapterIds(bookId);
    final counts = await BookHelp.mapCachedWordCounts(bookId);
    if (!mounted) return;
    setState(() {
      _cachedIds = ids;
      _wordCounts = counts;
    });
  }

  bool _isCurrent(Chapter chapter) {
    if (widget.currentChapterId != null &&
        widget.currentChapterId!.isNotEmpty) {
      return chapter.id == widget.currentChapterId;
    }
    if (widget.currentChapter == null || widget.currentChapter!.isEmpty) {
      return false;
    }
    return chapter.title == widget.currentChapter;
  }

  int? _wordCountOf(Chapter chapter) {
    final fromCache = _wordCounts[BookHelp.sanitizeId(chapter.id)];
    if (fromCache != null && fromCache > 0) return fromCache;
    final content = chapter.content;
    if (content != null && content.isNotEmpty) return content.length;
    return null;
  }

  bool _hasCacheVisual(Chapter chapter) {
    if (chapter.isDownloaded) return true;
    final sid = BookHelp.sanitizeId(chapter.id);
    return _cachedIds.contains(sid) || _wordCounts.containsKey(sid);
  }

  List<Chapter> get _filteredChapters {
    final q = _query.trim().toLowerCase();
    Iterable<Chapter> list = widget.chapters;
    if (q.isNotEmpty) {
      list = list.where((c) => c.title.toLowerCase().contains(q));
    }
    final result = list.toList();
    if (_reversed) return result.reversed.toList();
    return result;
  }

  double _rowHeight(Chapter chapter) {
    final words = _wordCountOf(chapter);
    if (_hasCacheVisual(chapter) && words != null) return _rowCached;
    return _rowPlain;
  }

  void _scrollToCurrent() {
    if (_didScrollToCurrent || !mounted || _tabIndex != 0) return;
    if (!_chapterScroll.hasClients) return;
    final chapters = _filteredChapters;
    final idx = chapters.indexWhere(_isCurrent);
    if (idx < 0) return;
    _didScrollToCurrent = true;
    var offset = 0.0;
    for (var i = 0; i < idx; i++) {
      offset += _rowHeight(chapters[i]);
    }
    _chapterScroll.jumpTo(offset.clamp(0.0, _chapterScroll.position.maxScrollExtent));
  }

  int _displayNumber(Chapter chapter) {
    if (chapter.index >= 0 && chapter.index < widget.chapters.length * 2) {
      return chapter.index + 1;
    }
    final i = widget.chapters.indexWhere((c) => c.id == chapter.id);
    return (i >= 0 ? i : 0) + 1;
  }

  Chapter? get _currentChapter {
    for (final c in widget.chapters) {
      if (_isCurrent(c)) return c;
    }
    return null;
  }

  String get _footerProgressText {
    final cur = _currentChapter;
    final total = widget.chapters.length;
    if (cur == null) {
      return total == 0 ? '暂无章节' : '(0/$total)';
    }
    final n = _displayNumber(cur);
    return '${cur.title}($n/$total)';
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _query = '';
        _didScrollToCurrent = false;
      }
    });
    if (!_searching) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    }
  }

  void _jumpChapterList(bool toTop) {
    if (!_chapterScroll.hasClients) return;
    _chapterScroll.jumpTo(
      toTop ? 0 : _chapterScroll.position.maxScrollExtent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final appBarBg = theme.appBarTheme.backgroundColor ??
        theme.colorScheme.surfaceContainerHigh;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        // Compact TabBar + centerTitle：目录/书签居于返回键与右侧操作之间（对齐 Legado）
        title: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelColor: theme.colorScheme.onSurface,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          indicatorColor: accent,
          indicatorSize: TabBarIndicatorSize.label,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: const [
            Tab(text: '目录'),
            Tab(text: '书签'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _searching ? '关闭搜索' : '搜索',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: _tabIndex == 0
                ? _toggleSearch
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请切换到目录 Tab 搜索')),
                    );
                  },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'reverse') {
                setState(() {
                  _reversed = !_reversed;
                  _didScrollToCurrent = false;
                });
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToCurrent());
              } else if (v == 'locate') {
                _didScrollToCurrent = false;
                _scrollToCurrent();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'reverse',
                child: Text(_reversed ? '正序' : '倒序'),
              ),
              const PopupMenuItem(
                value: 'locate',
                child: Text('定位当前章节'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searching && _tabIndex == 0)
            Material(
              color: appBarBg,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '搜索章节',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                                _didScrollToCurrent = false;
                              });
                            },
                          ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (v) => setState(() {
                    _query = v;
                    _didScrollToCurrent = false;
                  }),
                ),
              ),
            ),
          Expanded(
            child: _tabIndex == 0
                ? _buildChapterTab(accent)
                : _buildBookmarkTab(accent),
          ),
          if (_tabIndex == 0) _buildFooter(theme, appBarBg),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, Color bg) {
    final onSurface = theme.colorScheme.onSurface;
    return Material(
      color: bg,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    _didScrollToCurrent = false;
                    _scrollToCurrent();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _footerProgressText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: '顶部',
                icon: Icon(Icons.arrow_drop_up, color: onSurface),
                onPressed: () => _jumpChapterList(true),
              ),
              IconButton(
                tooltip: '底部',
                icon: Icon(Icons.arrow_drop_down, color: onSurface),
                onPressed: () => _jumpChapterList(false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterTab(Color accent) {
    final chapters = _filteredChapters;
    final theme = Theme.of(context);
    final titleColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final dividerColor = theme.dividerColor.withValues(alpha: 0.35);

    if (chapters.isEmpty) {
      return Center(
        child: Text(
          _query.isEmpty ? '暂无章节' : '未找到匹配章节',
          style: TextStyle(color: theme.hintColor),
        ),
      );
    }

    return ListView.separated(
      controller: _chapterScroll,
      itemCount: chapters.length,
      separatorBuilder: (_, _) => Divider(height: 1, thickness: 0.5, color: dividerColor),
      itemBuilder: (_, i) {
        final chapter = chapters[i];
        final isCurrent = _isCurrent(chapter);
        final cached = _hasCacheVisual(chapter);
        final words = _wordCountOf(chapter);
        final showWordCount = cached && words != null;

        return InkWell(
          onTap: () {
            Navigator.pop(context);
            widget.onChapterTap(chapter);
          },
          child: Container(
            constraints: BoxConstraints(
              minHeight: showWordCount ? _rowCached : _rowPlain,
            ),
            color: isCurrent ? accent.withValues(alpha: 0.12) : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.25,
                          color: isCurrent ? accent : titleColor,
                          fontWeight:
                              isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (showWordCount) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$words字',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!cached)
                  Icon(
                    Icons.cloud_outlined,
                    size: 20,
                    color: subtitleColor,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookmarkTab(Color accent) {
    final theme = Theme.of(context);
    if (_bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, size: 40, color: theme.hintColor),
            const SizedBox(height: 12),
            Text('暂无书签', style: TextStyle(color: theme.hintColor)),
            const SizedBox(height: 4),
            Text(
              '阅读中可在菜单添加书签',
              style: TextStyle(
                fontSize: 12,
                color: theme.hintColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _bookmarkScroll,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _bookmarks.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
      itemBuilder: (_, i) {
        final bm = _bookmarks[i];
        Chapter? chapter;
        if (bm.position >= 0 && bm.position < widget.chapters.length) {
          chapter = widget.chapters[bm.position];
        } else {
          final byTitle = widget.chapters
              .where((c) => c.title == bm.chapterTitle)
              .toList();
          if (byTitle.isNotEmpty) chapter = byTitle.first;
        }
        return ListTile(
          dense: true,
          leading: Icon(Icons.bookmark, size: 20, color: accent),
          title: Text(
            bm.chapterTitle.isEmpty ? '未命名章节' : bm.chapterTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            bm.selectedText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: theme.hintColor),
          ),
          onTap: chapter == null
              ? null
              : () {
                  final target = chapter!;
                  final chapterPos =
                      bm.chapterPos >= 0 ? bm.chapterPos : null;
                  final pageIndex = chapterPos == null
                      ? bookmarkPageIndexFromNote(bm.noteContent)
                      : null;
                  Navigator.pop(context);
                  widget.onChapterTap(
                    target,
                    pageIndex: pageIndex,
                    chapterPos: chapterPos,
                  );
                },
        );
      },
    );
  }
}
