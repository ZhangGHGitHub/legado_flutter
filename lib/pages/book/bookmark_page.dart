import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/note_service.dart';
import '../../src/rust/api.dart' as rust_api;
import '../../widgets/empty_state.dart';
import '../../widgets/note_editor_sheet.dart';
import '../../widgets/note_share_card.dart';
import '../obsidian/obsidian_export_dialog.dart';

bool _isBookmarkNote(rust_api.NoteDto n) => n.noteContent.startsWith('书签');

/// 书签与想法 — 对齐 AllBookmarkActivity：书签 / 想法分 Tab
class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<rust_api.NoteDto> _all = [];
  bool _loading = true;
  final _shareKeys = <String, GlobalKey>{};

  List<rust_api.NoteDto> get _bookmarks =>
      _all.where(_isBookmarkNote).toList(growable: false);

  List<rust_api.NoteDto> get _thoughts =>
      _all.where((n) => !_isBookmarkNote(n)).toList(growable: false);

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
    if (!mounted) return;
    setState(() {
      _all = notes;
      _loading = false;
      _shareKeys
        ..clear()
        ..addEntries(notes.map((n) => MapEntry(n.id, GlobalKey())));
    });
  }

  Future<void> _exportObsidian() async {
    await ObsidianExportDialog.show(context);
  }

  Future<void> _shareNote(rust_api.NoteDto note) async {
    final key = _shareKeys[note.id];
    if (key == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await shareNoteAsImage(repaintKey: key, fileName: 'note_${note.id}');
  }

  Future<void> _deleteNote(rust_api.NoteDto note) async {
    final isBm = _isBookmarkNote(note);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBm ? '删除书签' : '删除想法'),
        content: Text(isBm ? '确定删除这条书签吗？' : '确定删除这条想法吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    NoteService.delete(note.id);
    await _load();
  }

  Book _bookFromNote(rust_api.NoteDto note) {
    return Book(id: note.bookId, name: note.bookId);
  }

  Widget _buildList({
    required List<rust_api.NoteDto> items,
    required bool bookmarks,
  }) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return EmptyState(
        icon: bookmarks ? Icons.bookmark_border : Icons.lightbulb_outline,
        title: bookmarks ? '暂无书签' : '暂无想法',
        subtitle: bookmarks
            ? '阅读中可在菜单添加书签'
            : '在阅读器中长按选中文本，点击「写想法」即可记录',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final note = items[index];
          return Card(
            child: ListTile(
              leading: Icon(
                bookmarks ? Icons.bookmark : Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                note.chapterTitle.isEmpty ? '未命名章节' : note.chapterTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    bookmarks
                        ? (note.noteContent.isEmpty
                            ? note.selectedText
                            : note.noteContent)
                        : note.selectedText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!bookmarks && note.noteContent.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      note.noteContent,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${note.bookId} · ${note.createdAt}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: bookmarks
                  ? null
                  : () async {
                      await showNoteEditorSheet(
                        context,
                        book: _bookFromNote(note),
                        chapterTitle: note.chapterTitle,
                        selectedText: note.selectedText,
                        position: note.position,
                        existing: note,
                      );
                      await _load();
                    },
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'share':
                      await _shareNote(note);
                    case 'delete':
                      await _deleteNote(note);
                  }
                },
                itemBuilder: (ctx) => [
                  if (!bookmarks)
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
                  for (final note in _all)
                    RepaintBoundary(
                      key: _shareKeys[note.id],
                      child: NoteShareCard(note: note, bookName: note.bookId),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
