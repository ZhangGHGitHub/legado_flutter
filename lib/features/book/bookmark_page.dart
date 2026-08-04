import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import '../../application/bookmark/bookmark_page_port.dart';
import '../../application/bookmark/bookmark_reader_port.dart';
import '../../application/bookshelf/bookshelf_membership_port.dart';
import '../../application/source_management/source_notifier.dart';
import '../../help/bookmark_hint.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/bookmark_editor_sheet.dart';
import '../../widgets/note_editor_sheet.dart';
import '../../widgets/note_share_card.dart';
import '../obsidian/obsidian_export_dialog.dart';
import '../../features/reader/reader_page.dart';

/// 书签与想法 — 对齐 AllBookmarkActivity：书签 / 想法分 Tab
class BookmarkPage extends StatelessWidget {
  const BookmarkPage({
    super.key,
    this.port,
    this.membershipPort,
    this.readerPort,
  });

  final BookmarkPagePort? port;
  final BookshelfMembershipPort? membershipPort;
  final BookmarkReaderPort? readerPort;

  @override
  Widget build(BuildContext context) {
    return _BookmarkPageBody(
      port: port,
      membershipPort: membershipPort,
      readerPort: readerPort,
    );
  }
}

class _BookmarkPageBody extends riverpod.ConsumerStatefulWidget {
  const _BookmarkPageBody({this.port, this.membershipPort, this.readerPort});

  final BookmarkPagePort? port;
  final BookshelfMembershipPort? membershipPort;
  final BookmarkReaderPort? readerPort;

  @override
  riverpod.ConsumerState<_BookmarkPageBody> createState() =>
      _BookmarkPageState();
}

class _BookmarkPageState extends riverpod.ConsumerState<_BookmarkPageBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final BookmarkPagePort _port;
  late final BookshelfMembershipPort _membershipPort;
  late final BookmarkReaderPort _readerPort;
  List<BookmarkPageMark> _all = [];
  bool _loading = true;
  bool _syncing = false;
  final _shareKeys = <String, GlobalKey>{};

  List<BookmarkPageMark> get _bookmarks {
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

  List<BookmarkPageMark> get _thoughts =>
      _all.where((item) => !item.isBookmark).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _port =
        widget.port ??
        Provider.of<BookmarkPagePort?>(context, listen: false) ??
        const UnavailableBookmarkPagePort();
    _membershipPort =
        widget.membershipPort ??
        Provider.of<BookshelfMembershipPort?>(context, listen: false) ??
        const EmptyBookshelfMembershipPort();
    _readerPort =
        widget.readerPort ??
        Provider.of<BookmarkReaderPort?>(context, listen: false) ??
        const EmptyBookmarkReaderPort();
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
    final marks = _port.load(books: _membershipPort.books).marks;
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
      bytes: utf8.encode(_port.exportJson()),
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
      final imported = _port.importJson(await File(path).readAsString());
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
    if (_syncing || !_port.isAvailable) return;
    setState(() => _syncing = true);
    try {
      final count = upload
          ? await _port.uploadBookmarks()
          : await _port.downloadBookmarks();
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

  Future<void> _shareNote(BookmarkPageMark mark) async {
    final note = mark.thought;
    if (note == null) return;
    final key = _shareKeys[mark.id];
    if (key == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await shareNoteAsImage(repaintKey: key, fileName: 'note_${note.id}');
  }

  Future<void> _deleteNote(BookmarkPageMark mark) async {
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
      _port.deleteBookmark(mark.bookmark!.time);
    } else if (mark.thought != null) {
      _port.deleteNote(mark.thought!.id);
    }
    await _load();
  }

  Book _bookFromNote(BookmarkPageMark mark) {
    return Book(id: mark.bookId, name: mark.bookName, author: mark.bookAuthor);
  }

  /// 点击书签/想法：书架有书则打开 ReaderPage 并尽量定位章节，否则 SnackBar
  Future<void> _openNoteInReader(BookmarkPageMark mark) async {
    final book = _readerPort.findBookById(mark.bookId);
    if (book == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('该书不在书架中，无法跳转阅读')));
      return;
    }

    var chapters = <Chapter>[];
    if (_readerPort.currentChapters.isNotEmpty &&
        _readerPort.currentChapters.first.bookId == book.id) {
      chapters = List<Chapter>.from(_readerPort.currentChapters);
    } else {
      final source = ref
          .read(sourceNotifierProvider.notifier)
          .findSourceForBook(book);
      if (source != null) {
        try {
          await _readerPort.loadChapters(book, source: source);
          chapters = List<Chapter>.from(_readerPort.currentChapters);
        } catch (_) {}
      }
      if (chapters.isEmpty) {
        chapters = await _readerPort.getLocalChapters(book.id);
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

  Future<void> _editThought(BookmarkPageMark mark) async {
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

  Future<void> _editBookmark(BookmarkPageMark mark) async {
    final bookmark = mark.bookmark;
    if (bookmark == null) return;
    await showBookmarkEditorSheet(
      context,
      book: _bookFromNote(mark),
      existing: bookmark,
    );
    await _load();
  }

  Widget _buildList({
    required List<BookmarkPageMark> items,
    required bool bookmarks,
  }) {
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
            onPressed: _port.isAvailable ? _importBookmarks : null,
            icon: const Icon(Icons.file_open_outlined),
          ),
          IconButton(
            tooltip: '导出书签 JSON',
            onPressed: _port.isAvailable ? _exportBookmarks : null,
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: '上传书签到 WebDAV',
            onPressed: _port.isAvailable && !_syncing
                ? () => _syncBookmarks(upload: true)
                : null,
            icon: const Icon(Icons.cloud_upload_outlined),
          ),
          IconButton(
            tooltip: '从 WebDAV 合并书签',
            onPressed: _port.isAvailable && !_syncing
                ? () => _syncBookmarks(upload: false)
                : null,
            icon: const Icon(Icons.cloud_download_outlined),
          ),
          IconButton(
            tooltip: '导出 Obsidian Markdown',
            onPressed: _port.notesAvailable ? _exportObsidian : null,
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
