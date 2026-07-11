import 'package:flutter/material.dart';

import '../models/source_validation_result.dart';

/// 书源校验结果展示
class SourceValidationSheet extends StatelessWidget {
  final String sourceName;
  final SourceValidationResult result;

  const SourceValidationSheet({
    super.key,
    required this.sourceName,
    required this.result,
  });

  static Future<void> show(
    BuildContext context, {
    required String sourceName,
    required SourceValidationResult result,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SourceValidationSheet(
        sourceName: sourceName,
        result: result,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              sourceName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.allOk ? '校验通过' : '校验未完全通过',
              style: TextStyle(
                color: result.allOk ? Colors.green[700] : Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (result.searchTimeMs > 0) ...[
              const SizedBox(height: 4),
              Text(
                '搜索耗时 ${result.searchTimeMs} ms',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _StepRow(label: '搜索', ok: result.searchOk),
            _StepRow(label: '发现', ok: result.discoveryOk),
            _StepRow(label: '目录', ok: result.tocOk),
            _StepRow(label: '正文', ok: result.contentOk),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('错误详情', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              ...result.errors.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $e',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final bool ok;

  const _StepRow({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: ok ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            ok ? '通过' : '失败',
            style: TextStyle(
              color: ok ? Colors.green[700] : Colors.red[700],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// 列表行上的小校验状态图标
class SourceValidationBadge extends StatelessWidget {
  final SourceValidationResult? result;

  const SourceValidationBadge({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();
    final ok = result!.pipelineOk;
    return Icon(
      ok ? Icons.verified_outlined : Icons.error_outline,
      size: 16,
      color: ok ? Colors.green[600] : Colors.orange[700],
    );
  }
}
