import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

/// 书签与想法占位 — 对齐 bookmark 模块
class BookmarkPage extends StatelessWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('书签与想法')),
      body: const EmptyState(
        icon: Icons.bookmark_outline,
        title: '书签与想法开发中',
        subtitle: '将支持阅读批注、想法记录与导出',
      ),
    );
  }
}
