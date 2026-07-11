import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/note_export_service.dart';
import '../../services/note_service.dart';
import '../../src/rust/api.dart' as rust_api;
import '../../widgets/empty_state.dart';
import '../../widgets/note_editor_sheet.dart';
import '../../widgets/note_share_card.dart';

/// 书签与想法 — Phase 4.5
class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  List<rust_api.NoteDto> _notes = [];
  bool _loading = true;
  final _shareKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final notes = NoteService.list();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
      _shareKeys
        ..clear()
        ..addEntries(notes.map((n) => MapEntry(n.id, GlobalKey())));
    });
  }

  Future<void> _exportObsidian() async {
    final path = await NoteExportService.exportToLocalFiles();
    if (!mounted) return;
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无想法可导出')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已导出到 $path')),
    );
  }

  Future<void> _shareNote(rust_api.NoteDto note) async {
    final key = _shareKeys[note.id];
    if (key == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await shareNoteAsImage(repaintKey: key, fileName: 'note_${note.id}');
  }

  Future<void> _deleteNote(rust_api.NoteDto note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除想法'),
        content: const Text('确定删除这条想法吗？'),
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

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _notes.isEmpty
              ? const EmptyState(
                  icon: Icons.lightbulb_outline,
                  title: '暂无想法',
                  subtitle: '在阅读器中长按选中文本，点击「写想法」即可记录',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return Card(
                        child: ListTile(
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
                                note.selectedText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (note.noteContent.isNotEmpty) ...[
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
                                note.createdAt,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () async {
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
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(value: 'share', child: Text('分享卡片')),
                              PopupMenuItem(value: 'delete', child: Text('删除')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          if (_notes.isNotEmpty)
            Offstage(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final note in _notes)
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
