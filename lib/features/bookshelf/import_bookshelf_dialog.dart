import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/ports/public_text_fetch_port.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/app_log.dart';
import '../../services/bookshelf_list_io.dart';

/// 导入书单 — 对齐 Jingshiro：粘贴 url/json +「选文件」，按 name/author 精准搜索入库。
class ImportBookshelfDialog extends StatefulWidget {
  const ImportBookshelfDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const ImportBookshelfDialog(),
    );
  }

  @override
  State<ImportBookshelfDialog> createState() => _ImportBookshelfDialogState();
}

class _ImportBookshelfDialogState extends State<ImportBookshelfDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _progress;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      setState(() => _controller.text = text);
    }
  }

  Future<void> _pickFile() async {
    try {
      final text = await BookshelfListIo.pickFileText();
      if (text == null || text.isEmpty) return;
      setState(() {
        _controller.text = text;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _submit() async {
    final books = context.read<BookProvider>();
    final sources = context.read<SourceProvider>().sources;
    setState(() {
      _busy = true;
      _error = null;
      _progress = '解析书单…';
    });
    try {
      final raw = await BookshelfListIo.resolveInput(
        _controller.text,
        fetchPort: context.read<PublicTextFetchPort>(),
      );
      final entries = BookshelfListIo.parseEntries(raw);
      if (entries.isEmpty) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _progress = null;
          _error = '书单为空';
        });
        return;
      }

      final result = await books.importBookshelfEntries(
        entries,
        sources: sources,
        onProgress: (i, total, status) {
          if (!mounted) return;
          setState(() => _progress = '$status ($i/$total)');
        },
      );
      await AppLog.i(
        '导入书单: 新增 ${result.added}，跳过 ${result.skipped}，失败 ${result.failed}',
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '导入完成：新增 ${result.added}，跳过 ${result.skipped}，失败 ${result.failed}',
          ),
        ),
      );
    } catch (e) {
      await AppLog.e('导入书单失败: $e');
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入书单'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            enabled: !_busy,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'url / json',
              border: OutlineInputBorder(),
            ),
            minLines: 4,
            maxLines: 10,
          ),
          if (_progress != null) ...[
            const SizedBox(height: 8),
            Text(_progress!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _busy ? null : _paste, child: const Text('粘贴')),
        TextButton(
          onPressed: _busy ? null : _pickFile,
          child: const Text('选文件'),
        ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('确定'),
        ),
      ],
    );
  }
}
