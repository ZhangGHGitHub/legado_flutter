import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../help/book_help.dart';
import '../../model/read_book.dart';
import '../../models/chapter.dart';

/// 内容编辑 — 对齐 Jingshiro `ContentEditDialog`
class ContentEditDialog extends StatefulWidget {
  final String bookId;
  final Chapter chapter;
  final String initialContent;
  final Future<String> Function({bool reset}) loadRawContent;
  final Future<void> Function(String content) onSaved;

  const ContentEditDialog({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.initialContent,
    required this.loadRawContent,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String bookId,
    required Chapter chapter,
    required String initialContent,
    required Future<String> Function({bool reset}) loadRawContent,
    required Future<void> Function(String content) onSaved,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ContentEditDialog(
        bookId: bookId,
        chapter: chapter,
        initialContent: initialContent,
        loadRawContent: loadRawContent,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<ContentEditDialog> createState() => _ContentEditDialogState();
}

class _ContentEditDialogState extends State<ContentEditDialog> {
  late final TextEditingController _controller;
  bool _loading = false;
  late String _title;

  @override
  void initState() {
    super.initState();
    _title = widget.chapter.title.replaceAll(RegExp(r'<[^>]+>'), '');
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _controller.text;
    await BookHelp.saveContent(widget.bookId, widget.chapter.id, content);
    await ReadBook.instance.invalidateChapterCache(
      widget.chapter.id,
      bookId: widget.bookId,
    );
    // 重新填充内存：保存原文后再经会话处理由调用方 reload
    await widget.onSaved(content);
  }

  Future<void> _reset() async {
    setState(() => _loading = true);
    try {
      final content = await widget.loadRawContent(reset: true);
      if (!mounted) return;
      _controller.text = content;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(
      ClipboardData(text: '$_title\n${_controller.text}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制')),
    );
  }

  Future<void> _close() async {
    final nav = Navigator.of(context);
    await _save();
    if (mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _close,
          ),
          actions: [
            IconButton(
              tooltip: '保存',
              icon: const Icon(Icons.save_outlined),
              onPressed: () async {
                final nav = Navigator.of(context);
                await _save();
                if (!mounted) return;
                nav.pop();
              },
            ),
            IconButton(
              tooltip: '重置',
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _reset,
            ),
            IconButton(
              tooltip: '拷贝全部',
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: _copyAll,
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '章节内容',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
            if (_loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x44000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
