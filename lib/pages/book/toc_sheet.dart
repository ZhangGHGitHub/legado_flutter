import 'package:flutter/material.dart';

import '../../models/chapter.dart';
import '../../services/note_service.dart';
import '../../src/rust/api.dart' as rust_api;

/// 章节目录 BottomSheet — 对齐 Legado ChapterList（正序/倒序、缓存标、当前章高亮、搜索、书签 Tab）
class TocSheet extends StatefulWidget {
  final List<Chapter> chapters;
  final String? currentChapter;
  final String? currentChapterId;
  final String? bookId;
  final ValueChanged<Chapter> onChapterTap;
  final ScrollController? scrollController;

  const TocSheet({
    super.key,
    required this.chapters,
    this.currentChapter,
    this.currentChapterId,
    this.bookId,
    required this.onChapterTap,
    this.scrollController,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Chapter> chapters,
    String? currentChapter,
    String? currentChapterId,
    String? bookId,
    required ValueChanged<Chapter> onChapterTap,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => TocSheet(
          chapters: chapters,
          currentChapter: currentChapter,
          currentChapterId: currentChapterId,
          bookId: bookId,
          onChapterTap: onChapterTap,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  State<TocSheet> createState() => _TocSheetState();
}

class _TocSheetState extends State<TocSheet>
    with SingleTickerProviderStateMixin {
  bool _reversed = false;
  String _query = '';
  int _tabIndex = 0;
  late final TabController _tabController;
  late final TextEditingController _searchController;
  List<rust_api.NoteDto> _bookmarks = [];
  bool _didScrollToCurrent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController = TextEditingController();
    _loadBookmarks();
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

  void _scrollToCurrent() {
    if (_didScrollToCurrent || !mounted || _tabIndex != 0) return;
    final sc = widget.scrollController;
    if (sc == null || !sc.hasClients) return;
    final chapters = _filteredChapters;
    final idx = chapters.indexWhere(_isCurrent);
    if (idx < 0) return;
    _didScrollToCurrent = true;
    final offset = idx * 48.0;
    sc.jumpTo(offset.clamp(0.0, sc.position.maxScrollExtent));
  }

  int _displayNumber(Chapter chapter) {
    // Chapter.index 多为 0-based；若与列表位置差太大，回退到列表序
    if (chapter.index >= 0 && chapter.index < widget.chapters.length * 2) {
      return chapter.index + 1;
    }
    final i = widget.chapters.indexWhere((c) => c.id == chapter.id);
    return (i >= 0 ? i : 0) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  tabs: [
                    Tab(text: '目录(${widget.chapters.length})'),
                    Tab(
                      text: _bookmarks.isEmpty
                          ? '书签'
                          : '书签(${_bookmarks.length})',
                    ),
                  ],
                ),
              ),
              if (_tabIndex == 0)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _reversed = !_reversed;
                      _didScrollToCurrent = false;
                    });
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _scrollToCurrent());
                  },
                  icon: Icon(
                    _reversed ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                  ),
                  label: Text(
                    _reversed ? '正序' : '倒序',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: _tabIndex == 0
              ? _buildChapterTab(accent)
              : _buildBookmarkTab(accent),
        ),
      ],
    );
  }

  Widget _buildChapterTab(Color accent) {
    final chapters = _filteredChapters;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _searchController,
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) => setState(() {
              _query = v;
              _didScrollToCurrent = false;
            }),
          ),
        ),
        Expanded(
          child: chapters.isEmpty
              ? ListView(
                  controller: widget.scrollController,
                  children: [
                    SizedBox(
                      height: 160,
                      child: Center(
                        child: Text(
                          _query.isEmpty ? '暂无章节' : '未找到匹配章节',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  controller: widget.scrollController,
                  itemCount: chapters.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 48),
                  itemBuilder: (_, i) {
                    final chapter = chapters[i];
                    final isCurrent = _isCurrent(chapter);
                    return ListTile(
                      dense: true,
                      selected: isCurrent,
                      selectedTileColor: accent.withValues(alpha: 0.12),
                      leading: Text(
                        '${_displayNumber(chapter)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isCurrent ? accent : Colors.grey[500],
                          fontWeight:
                              isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      title: Text(
                        chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent ? accent : null,
                          fontWeight:
                              isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: chapter.isDownloaded
                          ? Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green[400],
                            )
                          : Icon(
                              Icons.circle_outlined,
                              size: 16,
                              color: Colors.grey[300],
                            ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onChapterTap(chapter);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBookmarkTab(Color accent) {
    if (_bookmarks.isEmpty) {
      return ListView(
        controller: widget.scrollController,
        children: [
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('暂无书签', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(
                    '阅读中可在菜单添加书签',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: widget.scrollController,
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
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          onTap: chapter == null
              ? null
              : () {
                  final target = chapter!;
                  Navigator.pop(context);
                  widget.onChapterTap(target);
                },
        );
      },
    );
  }
}
