import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book_source.dart';
import '../providers/source_provider.dart';

enum BookSourceImportKind { newSource, update, same }

/// 按 URL 与现库比对导入项状态（新增 / 更新 / 相同）
BookSourceImportKind classifyBookSourceImport(
  BookSource candidate,
  BookSource? existing,
) {
  if (existing == null) return BookSourceImportKind.newSource;

  final localT = existing.lastUpdateTime;
  final remoteT = candidate.lastUpdateTime;
  if (remoteT > 0 && localT > 0) {
    return remoteT > localT
        ? BookSourceImportKind.update
        : BookSourceImportKind.same;
  }

  final localJson = jsonEncode(existing.toJson());
  final remoteJson = jsonEncode(candidate.toJson());
  return localJson == remoteJson
      ? BookSourceImportKind.same
      : BookSourceImportKind.update;
}

String bookSourceImportKindLabel(BookSourceImportKind kind) => switch (kind) {
      BookSourceImportKind.newSource => '新增',
      BookSourceImportKind.update => '更新',
      BookSourceImportKind.same => '相同',
    };

/// 书源导入预览 — 对齐 Jingshiro ImportBookSourceDialog / 规则订阅勾选 UX
class ImportBookSourceDialog extends StatefulWidget {
  const ImportBookSourceDialog({
    super.key,
    required this.candidates,
    required this.existingByUrl,
  });

  final List<BookSource> candidates;
  final Map<String, BookSource> existingByUrl;

  @override
  State<ImportBookSourceDialog> createState() => _ImportBookSourceDialogState();
}

class _ImportBookSourceDialogState extends State<ImportBookSourceDialog> {
  late List<bool> _selected;
  late List<BookSourceImportKind> _kinds;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.candidates.length, true);
    _kinds = [
      for (final c in widget.candidates)
        classifyBookSourceImport(
          c,
          widget.existingByUrl[c.bookSourceUrl],
        ),
    ];
  }

  Future<void> _import() async {
    final selected = [
      for (var i = 0; i < _selected.length; i++)
        if (_selected[i]) widget.candidates[i],
    ];
    if (selected.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final ok =
        await context.read<SourceProvider>().importParsedSources(selected);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '已导入 ${selected.length} 个书源' : '导入失败'),
        backgroundColor: ok ? null : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('导入书源 (${widget.candidates.length})'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.candidates.length,
          itemBuilder: (_, i) {
            final source = widget.candidates[i];
            final kind = _kinds[i];
            final label = bookSourceImportKindLabel(kind);
            final badgeColor = switch (kind) {
              BookSourceImportKind.newSource => Colors.green,
              BookSourceImportKind.update => Colors.orange,
              BookSourceImportKind.same => theme.colorScheme.outline,
            };
            return CheckboxListTile(
              dense: true,
              value: _selected[i],
              title: Text(
                source.bookSourceName.isNotEmpty
                    ? source.bookSourceName
                    : source.bookSourceUrl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: source.bookSourceName.isNotEmpty
                  ? Text(
                      source.bookSourceUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    )
                  : null,
              secondary: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: badgeColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(color: badgeColor),
                ),
              ),
              onChanged: (v) => setState(() => _selected[i] = v ?? false),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              final all = _selected.every((e) => e);
              _selected = List.filled(_selected.length, !all);
            });
          },
          child: const Text('全选'),
        ),
        FilledButton(
          onPressed: _import,
          child: const Text('导入'),
        ),
      ],
    );
  }
}
