import 'package:flutter/material.dart';

import '../domain/ports/book_source_debug_port.dart';

/// 书源调试结果面板（请求 / 步骤 / 结果）
class SourceDebugPanel extends StatelessWidget {
  final BookSourceDebugSnapshot? result;

  const SourceDebugPanel({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();
    final r = result!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('请求', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            SelectableText(
              '${r.requestMethod} ${r.requestUrl}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
            if (r.responseStatus.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'HTTP ${r.responseStatus} · ${r.responseCharset} · ${r.responseSize} bytes',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Text('规则步骤', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            ...r.ruleSteps.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      s.ok ? Icons.check_circle : Icons.error,
                      size: 14,
                      color: s.ok ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.step} · ${s.rule}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            s.result,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (r.results.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '匹配结果 (${r.results.length})',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...r.results
                  .take(5)
                  .map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: item.bookUrl.isNotEmpty
                          ? Text(
                              item.bookUrl,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
