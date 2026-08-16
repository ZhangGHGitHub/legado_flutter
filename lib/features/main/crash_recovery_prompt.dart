import 'package:flutter/material.dart';

import '../../domain/crash/crash_report.dart';

Future<void> showCrashRecoveryPrompt(
  BuildContext context,
  CrashReport report,
) async {
  final openLog = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('提示'),
      content: const Text('检测到应用上次运行发生崩溃，是否打开崩溃日志以便报告问题？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('暂不'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('打开日志'),
        ),
      ],
    ),
  );
  if (openLog != true || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      return AlertDialog(
        title: const Text('崩溃日志'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: size.height * 0.65,
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              report.displayText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      );
    },
  );
}
