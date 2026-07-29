import 'package:flutter/material.dart';

import '../domain/annotation/bookmark_snapshot.dart';
import 'package:legado_flutter/domain/book/book.dart';
import '../services/bookmark_service.dart';

/// 对齐原版 BookmarkDialog：确认后才创建或更新书签。
Future<bool?> showBookmarkEditorSheet(
  BuildContext context, {
  required Book book,
  BookmarkSnapshot? existing,
  String chapterTitle = '',
  int chapterIndex = 0,
  int chapterPos = -1,
  String bookText = '',
  String content = '',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _BookmarkEditorSheet(
          book: book,
          time: existing?.time,
          chapterTitle: existing?.chapterName ?? chapterTitle,
          chapterIndex: existing?.chapterIndex ?? chapterIndex,
          chapterPos: existing?.chapterPos ?? chapterPos,
          bookText: existing?.bookText ?? bookText,
          content: existing?.content ?? content,
        ),
      );
    },
  );
}

class _BookmarkEditorSheet extends StatefulWidget {
  final Book book;
  final int? time;
  final String chapterTitle;
  final int chapterIndex;
  final int chapterPos;
  final String bookText;
  final String content;

  const _BookmarkEditorSheet({
    required this.book,
    required this.time,
    required this.chapterTitle,
    required this.chapterIndex,
    required this.chapterPos,
    required this.bookText,
    required this.content,
  });

  @override
  State<_BookmarkEditorSheet> createState() => _BookmarkEditorSheetState();
}

class _BookmarkEditorSheetState extends State<_BookmarkEditorSheet> {
  late final TextEditingController _bookTextCtrl;
  late final TextEditingController _contentCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bookTextCtrl = TextEditingController(text: widget.bookText);
    _contentCtrl = TextEditingController(text: widget.content);
  }

  @override
  void dispose() {
    _bookTextCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!BookmarkService.isReady) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('引擎未就绪，无法保存书签')));
      }
      return;
    }
    setState(() => _saving = true);
    final time = BookmarkService.save(
      time: widget.time,
      bookId: widget.book.id,
      bookName: widget.book.name,
      bookAuthor: widget.book.author,
      chapterIndex: widget.chapterIndex,
      chapterPos: widget.chapterPos,
      chapterName: widget.chapterTitle,
      bookText: _bookTextCtrl.text,
      content: _contentCtrl.text,
    );
    if (!mounted) return;
    if (time == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存书签失败')));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.62;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('书签', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                widget.chapterTitle.isEmpty ? '未命名章节' : widget.chapterTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _bookTextCtrl,
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: '正文片段',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _contentCtrl,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: '备注',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? '保存中…' : '保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
