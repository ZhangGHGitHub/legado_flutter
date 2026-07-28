import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/annotation/note_snapshot.dart';
import '../../domain/annotation/bookmark_snapshot.dart';
import '../../help/bookmark_hint.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/bookmark_service.dart';
import '../../services/bookmark_migration_service.dart';
import '../../services/bookmark_sync_service.dart';
import '../../services/note_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/bookmark_editor_sheet.dart';
import '../../widgets/note_editor_sheet.dart';
import '../../widgets/note_share_card.dart';
import '../obsidian/obsidian_export_dialog.dart';
import '../../features/reader/reader_page.dart';

bool _isBookmarkNote(NoteSnapshot n) => n.noteContent.startsWith('书签');

String _bookmarkSignature({
  required String bookId,
  required int chapterIndex,
  required int chapterPos,
  required String chapterName,
  required String bookText,
}) =>
    '$bookId\u0000$chapterIndex\u0000$chapterPos\u0000$chapterName\u0000$bookText';

class _MarkItem {
  final BookmarkSnapshot? bookmark;
  final NoteSnapshot? thought;
  final bool isLegacyBookmark;

  const _MarkItem.bookmark(this.bookmark)
    : thought = null,
      isLegacyBookmark = false;

  const _MarkItem.thought(this.thought)
    : bookmark = null,
      isLegacyBookmark = false;

  const _MarkItem.legacyBookmark(this.thought)
    : bookmark = null,
      isLegacyBookmark = true;

  bool get isBookmark => bookmark != null || isLegacyBookmark;
  String get id =>
      bookmark != null ? 'bookmark:${bookmark!.time}' : 'note:${thought!.id}';
  String get bookId => bookmark?.bookId ?? thought!.bookId;
  String get bookName => bookmark?.bookName ?? thought!.bookId;
  String get bookAuthor => bookmark?.bookAuthor ?? '';
  String get chapterTitle => bookmark?.chapterName ?? thought!.chapterTitle;
  String get selectedText => bookmark?.bookText ?? thought!.selectedText;
  String get noteContent => bookmark?.content ?? thought!.noteContent;
  int get position => bookmark?.chapterIndex ?? thought!.position;
  int get chapterPos => bookmark?.chapterPos ?? thought!.chapterPos;
  String get createdAt => bookmark == null
      ? thought!.createdAt
      : DateTime.fromMillisecondsSinceEpoch(bookmark!.time).toIso8601String();
}

/// 书签与想法 — 对齐 AllBookmarkActivity：书签 / 想法分 Tab
class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<_MarkItem> _all = [];
  bool _loading = true;
  bool _syncing = false;
  final _shareKeys = <String, GlobalKey>{};

  List<_MarkItem> get _bookmarks {
    final bookmarks = _all.where((item) => item.isBookmark).toList();
    bookmarks.sort((a, b) {
      final book = a.bookName.compareTo(b.bookName);
      if (book != 0) return book;
      final author = a.bookAuthor.compareTo(b.bookAuthor);
      if (author != 0) return author;
      final chapter = a.position.compareTo(b.position);
      if (chapter != 0) return chapter;
      final pos = a.chapterPos.compareTo(b.chapterPos);
      if (pos != 0) return pos;
      return a.id.compareTo(b.id);
    });
    return List.unmodifiable(bookmarks);
  }

  List<_MarkItem> get _thoughts =>
      _all.where((item) => !item.isBookmark).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final notes = NoteService.list();
    final provider = Provider.of<BookProvider?>(context, listen: false);
    BookmarkMigrationService.migrateLegacyNoteSnapshots(
      notes: notes,
      books: provider?.books ?? const <Book>[],
    );
    final bookmarks = BookmarkService.listSnapshots();
    final migratedKeys = bookmarks
        .map(
          (bookmark) => _bookmarkSignature(
            bookId: bookmark.bookId,
            chapterIndex: bookmark.chapterIndex,
            chapterPos: bookmark.chapterPos,
            chapterName: bookmark.chapterName,
            bookText: bookmark.bookText,
          ),
        )
        .toSet();
    final marks = <_MarkItem>[
      ...bookmarks.map(_MarkItem.bookmark),
      ...notes
          .where(_isBookmarkNote)
          .where(
            (note) => !migratedKeys.contains(
              _bookmarkSignature(
                bookId: note.bookId,
                chapterIndex: note.position,
                chapterPos: note.chapterPos >= 0 ? note.chapterPos : 0,
                chapterName: note.chapterTitle,
                bookText: note.selectedText,
              ),
            ),
          )
          .map(_MarkItem.legacyBookmark),
      ...notes.where((note) => !_isBookmarkNote(note)).map(_MarkItem.thought),
    ];
    if (!mounted) return;
    setState(() {
      _all = marks;
      _loading = false;
      _shareKeys
        ..clear()
        ..addEntries(marks.map((mark) => MapEntry(mark.id, GlobalKey())));
    });
  }

  Future<void> _exportObsidian() async {
    await ObsidianExportDialog.show(context);
  }

  Future<void> _exportBookmarks() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: '导出书签',
      fileName: 'bookmark.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: utf8.encode(BookmarkService.exportJson()),
    );
    if (!mounted || path == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已导出书签到 $path')));
  }

  Future<void> _importBookmarks() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      final imported = BookmarkService.importJson(
        await File(path).readAsString(),
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已导入 $imported 条书签')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('书签导入失败：$e')));
    }
  }

  Future<void> _syncBookmarks({required bool upload}) async {
    if (_syncing || !BookmarkService.isReady) return;
    setState(() => _syncing = true);
    try {
      final local = BookmarkService.list();
      final count = upload
          ? await BookmarkSyncService.uploadMerged(local: local)
          : await BookmarkSyncService.downloadAndMerge(
              local: local,
              apply: (json) async {
                BookmarkService.importJson(json);
              },
            );
      if (!upload) await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(upload ? '已上传并合并 $count 条书签' : '已合并 $count 条书签'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('WebDAV 书签同步失败：$e')));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _shareNote(_MarkItem mark) async {
    final note = mark.thought;
    if (note == null) return;
    final key = _shareKeys[mark.id];
    if (key == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await shareNoteAsImage(repaintKey: key, fileName: 'note_${note.id}');
  }

  Future<void> _deleteNote(_MarkItem mark) async {
    final isBm = mark.isBookmark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBm ? '删除书签' : '删除想法'),
        content: Text(isBm ? '确定删除这条书签吗？' : '确定删除这条想法吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (mark.bookmark != null) {
      BookmarkService.delete(mark.bookmark!.time);
    } else if (mark.thought != null) {
      NoteService.delete(mark.thought!.id);
    }
    await _load();
  }

  Book _bookFromNote(_MarkItem mark) {
    return Book(id: mark.bookId, name: mark.bookName, author: mark.bookAuthor);
  }

  /// 点击书签/想法：书架有书则打开 ReaderPage 并尽量定位章节，否则 SnackBar
  Future<void> _openNoteInReader(_MarkItem mark) async {
    final provider = context.read<BookProvider>();
    final book = provider.findBookById(mark.bookId);
    if (book == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('该书不在书架中，无法跳转阅读')));
      return;
    }

    var chapters = <Chapter>[];
    if (provider.currentChapters.isNotEmpty &&
        provider.currentChapters.first.bookId == book.id) {
      chapters = List<Chapter>.from(provider.currentChapters);
    } else {
      final source = context.read<SourceProvider>().findSourceForBook(book);
      if (source != null) {
        try {
          await provider.loadChapters(book, source: source);
          chapters = List<Chapter>.from(provider.currentChapters);
        } catch (_) {}
      }
      if (chapters.isEmpty) {
        chapters = await provider.getLocalChapters(book.id);
      }
    }

    if (!mounted) return;
    if (chapters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('「${book.name}」暂无章节，无法打开阅读器')));
      return;
    }

    var idx = mark.position;
    if (idx < 0 || idx >= chapters.length) {
      idx = chapters.indexWhere((c) => c.title == mark.chapterTitle);
    }
    if (idx < 0) idx = 0;

    final chapterPos = mark.chapterPos >= 0 ? mark.chapterPos : null;
    final pageIndex = chapterPos == null
        ? bookmarkPageIndexFromNote(mark.noteContent)
        : null;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          book: book,
          chapter: chapters[idx],
          allChapters: chapters,
          initialPageIndex: pageIndex,
          initialChapterPos: chapterPos,
        ),
      ),
    );
  }

  Future<void> _editThought(_MarkItem mark) async {
    final note = mark.thought;
    if (note == null || mark.isBookmark) return;
    await showNoteEditorSheet(
      context,
      book: _bookFromNote(mark),
      chapterTitle: note.chapterTitle,
      selectedText: note.selectedText,
      position: note.position,
      chapterPos: note.chapterPos,
      existing: note,
    );
    await _load();
  }

  Future<void> _editBookmark(_MarkItem mark) async {
    final bookmark = mark.bookmark;
    if (bookmark == null) return;
    await showBookmarkEditorSheet(
      context,
      book: _bookFromNote(mark),
      existing: bookmark,
    );
    await _load();
  }

  Widget _buildList({required List<_MarkItem> items, required bool bookmarks}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return EmptyState(
        icon: bookmarks ? Icons.bookmark_border : Icons.lightbulb_outline,
        title: bookmarks ? '暂无书签' : '暂无想法',
        subtitle: bookmarks ? '阅读中可在菜单添加书签' : '在阅读器中长按选中文本，点击「写想法」即可记录',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final mark = items[index];
          return Card(
            child: ListTile(
              leading: Icon(
                mark.isBookmark ? Icons.bookmark : Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                mark.chapterTitle.isEmpty ? '未命名章节' : mark.chapterTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    mark.isBookmark
                        ? (mark.noteContent.isEmpty
                              ? mark.selectedText
                              : mark.noteContent)
                        : mark.selectedText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!mark.isBookmark && mark.noteContent.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      mark.noteContent,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${mark.bookName} · ${mark.createdAt}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () => _openNoteInReader(mark),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'edit':
                      if (mark.isBookmark) {
                        await _editBookmark(mark);
                      } else {
                        await _editThought(mark);
                      }
                    case 'share':
                      await _shareNote(mark);
                    case 'delete':
                      await _deleteNote(mark);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('编辑')),
                  if (!mark.isBookmark)
                    const PopupMenuItem(value: 'share', child: Text('分享卡片')),
                  const PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bmCount = _bookmarks.length;
    final thCount = _thoughts.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('书签与想法'),
        actions: [
          IconButton(
            tooltip: '导入书签 JSON',
            onPressed: BookmarkService.isReady ? _importBookmarks : null,
            icon: const Icon(Icons.file_open_outlined),
          ),
          IconButton(
            tooltip: '导出书签 JSON',
            onPressed: BookmarkService.isReady ? _exportBookmarks : null,
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: '上传书签到 WebDAV',
            onPressed: BookmarkService.isReady && !_syncing
                ? () => _syncBookmarks(upload: true)
                : null,
            icon: const Icon(Icons.cloud_upload_outlined),
          ),
          IconButton(
            tooltip: '从 WebDAV 合并书签',
            onPressed: BookmarkService.isReady && !_syncing
                ? () => _syncBookmarks(upload: false)
                : null,
            icon: const Icon(Icons.cloud_download_outlined),
          ),
          IconButton(
            tooltip: '导出 Obsidian Markdown',
            onPressed: NoteService.isReady ? _exportObsidian : null,
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: bmCount == 0 ? '书签' : '书签($bmCount)'),
            Tab(text: thCount == 0 ? '想法' : '想法($thCount)'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabs,
            children: [
              _buildList(items: _bookmarks, bookmarks: true),
              _buildList(items: _thoughts, bookmarks: false),
            ],
          ),
          if (_all.isNotEmpty)
            Offstage(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final mark in _all)
                    if (mark.thought != null)
                      RepaintBoundary(
                        key: _shareKeys[mark.id],
                        child: NoteShareCard(
                          note: mark.thought!,
                          bookName: mark.bookName,
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
