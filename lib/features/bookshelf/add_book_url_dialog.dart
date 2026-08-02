import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import '../../application/diagnostics/app_log_port.dart';
import '../../application/platform/clipboard_port.dart';
import '../../application/source_management/source_notifier.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';

/// 添加书籍网址 — 对齐 Jingshiro「添加网址」：多行 URL → 匹配书源 → **直接加入书架**。
class AddBookUrlDialog extends StatelessWidget {
  const AddBookUrlDialog({super.key, this.clipboard});

  final ClipboardPort? clipboard;

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const AddBookUrlDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceProvider = context.read<SourceProvider>();
    return riverpod.ProviderScope(
      overrides: [
        sourceControllerProvider.overrideWithValue(sourceProvider.controller),
      ],
      child: _AddBookUrlDialogBody(clipboard: clipboard),
    );
  }
}

class _AddBookUrlDialogBody extends riverpod.ConsumerStatefulWidget {
  const _AddBookUrlDialogBody({this.clipboard});

  final ClipboardPort? clipboard;

  @override
  riverpod.ConsumerState<_AddBookUrlDialogBody> createState() =>
      _AddBookUrlDialogState();
}

class _AddBookUrlDialogState
    extends riverpod.ConsumerState<_AddBookUrlDialogBody> {
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
    final clipboard = widget.clipboard ?? context.read<ClipboardPort>();
    final text = (await clipboard.pasteText())?.trim() ?? '';
    if (text.isNotEmpty) {
      setState(() => _controller.text = text);
    }
  }

  Future<void> _submit() async {
    final appLog = context.read<AppLogPort>();
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = '请输入书籍详情页网址（支持多行）');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _progress = '准备添加…';
    });

    try {
      final sources = ref.read(sourceNotifierProvider).sources;
      final books = context.read<BookProvider>();
      final result = await books.addBooksByUrls(
        text,
        sources: sources,
        onProgress: (i, total, url) {
          if (!mounted) return;
          setState(() => _progress = '添加中 $i/$total');
        },
      );
      await appLog.i('添加网址: 成功 ${result.success}，失败 ${result.fail}');
      if (!mounted) return;
      Navigator.pop(context);
      final msg = result.fail == 0
          ? (result.success > 0 ? '成功' : '没有可添加的网址')
          : '成功 ${result.success}，失败 ${result.fail}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: result.success == 0 ? Colors.red : null,
        ),
      );
    } catch (e) {
      await appLog.e('添加网址失败: $e');
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
      title: const Text('添加网址'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            enabled: !_busy,
            autofocus: true,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: '每行一个详情页 URL\n可附带 ,{"origin":"书源URL"}',
              border: OutlineInputBorder(),
            ),
            minLines: 3,
            maxLines: 8,
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
