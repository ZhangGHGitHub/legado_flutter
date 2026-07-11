import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

/// 订阅 Tab 占位（对齐 RssFragment）
class RssTabPage extends StatelessWidget {
  const RssTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订阅')),
      body: const EmptyState(
        icon: Icons.subscriptions_outlined,
        title: 'RSS 订阅即将推出',
        subtitle: '对齐 Jingshiro Legado ui/rss 模块',
      ),
    );
  }
}
