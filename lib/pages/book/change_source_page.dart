import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../widgets/empty_state.dart';

/// 换源页占位 — 对齐 changeSource
class ChangeSourcePage extends StatelessWidget {
  final Book book;

  const ChangeSourcePage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('换源')),
      body: EmptyState(
        icon: Icons.swap_horiz,
        title: '换源功能开发中',
        subtitle: '《${book.name}》\n后端换源校验将在后续版本接入',
        actionLabel: '返回',
        onAction: () => Navigator.pop(context),
      ),
    );
  }
}
