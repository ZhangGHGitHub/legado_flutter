import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 本地帮助文档弹窗 — 覆盖原版帮助资产使用的 Markdown 子集。
class SourceManageHelpDialog extends StatelessWidget {
  const SourceManageHelpDialog({
    super.key,
    required this.content,
    this.title = '书源管理帮助',
  });

  static const assetPath = 'assets/help/SourceMBookHelp.md';
  static final Map<String, String> _contentByAsset = {};

  static Future<void> show(
    BuildContext context, {
    String assetPath = SourceManageHelpDialog.assetPath,
    String title = '书源管理帮助',
  }) async {
    final cached = _contentByAsset[assetPath];
    final content = cached ?? await rootBundle.loadString(assetPath);
    _contentByAsset[assetPath] = content;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => SourceManageHelpDialog(content: content, title: title),
    );
  }

  final String content;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _parseLines(content, theme),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('确定'),
        ),
      ],
    );
  }

  static List<Widget> _parseLines(String md, ThemeData theme) {
    final widgets = <Widget>[];
    for (final raw in md.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      final heading = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (heading != null) {
        final level = heading.group(1)!.length;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              heading.group(2)!,
              style:
                  (level == 1
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.titleMedium)
                      ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        );
        continue;
      }
      final indent = line.length - line.trimLeft().length;
      if (line.trimLeft().startsWith('* ')) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: indent == 0 ? 8 : 24, bottom: 4),
            child: _richText(
              indent == 0
                  ? '• ${line.trimLeft().substring(2)}'
                  : '◦ ${line.trimLeft().substring(2)}',
              theme,
              small: indent > 0,
            ),
          ),
        );
        continue;
      }
      final ordered = RegExp(r'^\s*(\d+)\.\s+(.+)$').firstMatch(line);
      if (ordered != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: _richText('${ordered.group(1)}. ${ordered.group(2)}', theme),
          ),
        );
        continue;
      }
      final quote = line.trimLeft();
      if (quote.startsWith('> ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: _richText(quote.substring(2), theme, quote: true),
          ),
        );
        continue;
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _richText(line, theme),
        ),
      );
    }
    return widgets;
  }

  static Widget _richText(
    String text,
    ThemeData theme, {
    bool small = false,
    bool quote = false,
  }) {
    return Text.rich(
      TextSpan(
        style: (small ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
            ?.copyWith(fontStyle: quote ? FontStyle.italic : null),
        children: _inlineSpans(text, theme),
      ),
    );
  }

  static List<InlineSpan> _inlineSpans(String text, ThemeData theme) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'\*\*([^*]+)\*\*|\[([^\]]+)\]\((https?://[^)]+)\)|(https?://\S+)',
    );
    var cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final bold = match.group(1);
      final linkLabel = match.group(2);
      final linkUrl = match.group(3) ?? match.group(4);
      if (bold != null) {
        spans.add(
          TextSpan(
            text: bold,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else if (linkUrl != null) {
        final label = linkLabel ?? linkUrl;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: InkWell(
              onTap: () {
                final uri = Uri.tryParse(linkUrl);
                if (uri != null) unawaited(launchUrl(uri));
              },
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        );
      }
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return spans;
  }
}
