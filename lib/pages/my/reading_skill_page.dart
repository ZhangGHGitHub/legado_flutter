import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

/// Reading Skill 占位 — 对齐 Jingshiro README
class ReadingSkillPage extends StatelessWidget {
  const ReadingSkillPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('阅读 Skill')),
      body: const EmptyState(
        icon: Icons.terminal,
        title: 'Reading Skill 开发中',
        subtitle: '将支持安装社区技能扩展，增强阅读器能力',
      ),
    );
  }
}
