import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

/// AI 助手占位 — 对齐 AiChatActivity
class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key, this.isStandalone = true});

  /// true=从我的页进入；false=从阅读器进入
  final bool isStandalone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 助手'),
        leading: isStandalone ? null : const BackButton(),
      ),
      body: EmptyState(
        icon: Icons.smart_toy_outlined,
        title: 'AI 助手开发中',
        subtitle: isStandalone
            ? '独立模式：从我的页进入\n将对接大模型 API 与阅读上下文'
            : '阅读模式：从阅读器进入\n将支持选中段落智能问答',
        actionLabel: '返回',
        onAction: () => Navigator.pop(context),
      ),
    );
  }
}
