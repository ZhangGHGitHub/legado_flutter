import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/book.dart';
import '../services/note_service.dart';
import '../src/rust/api.dart' as rust_api;

/// 半屏想法编辑器（Phase 4.5）
Future<bool?> showNoteEditorSheet(
  BuildContext context, {
  required Book book,
  required String chapterTitle,
  required String selectedText,
  int position = 0,
  rust_api.NoteDto? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _NoteEditorSheet(
          book: book,
          chapterTitle: chapterTitle,
          selectedText: selectedText,
          position: position,
          existing: existing,
        ),
      );
    },
  );
}

class _NoteEditorSheet extends StatefulWidget {
  final Book book;
  final String chapterTitle;
  final String selectedText;
  final int position;
  final rust_api.NoteDto? existing;

  const _NoteEditorSheet({
    required this.book,
    required this.chapterTitle,
    required this.selectedText,
    required this.position,
    this.existing,
  });

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _contentCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: widget.existing?.noteContent ?? '');
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!NoteService.isReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('引擎未就绪，无法保存想法')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    final id = widget.existing?.id ?? const Uuid().v4();
    NoteService.save(
      id: id,
      bookId: widget.book.id,
      chapterTitle: widget.chapterTitle,
      selectedText: widget.selectedText,
      noteContent: _contentCtrl.text.trim(),
      position: widget.position,
    );
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.52;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '写想法',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.chapterTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.selectedText.isEmpty ? '（未选中文本）' : widget.selectedText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _contentCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: '记录你的想法…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '保存中…' : '保存想法'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
