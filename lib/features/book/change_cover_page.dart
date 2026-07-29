import 'package:flutter/material.dart';

import 'package:legado_flutter/domain/book/book.dart';
import '../../widgets/empty_state.dart';

/// 换封面页占位 — 对齐 changeCover
class ChangeCoverPage extends StatelessWidget {
  final Book book;

  const ChangeCoverPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('换封面')),
      body: EmptyState(
        icon: Icons.image_outlined,
        title: '换封面功能开发中',
        subtitle: '《${book.name}》',
        actionLabel: '返回',
        onAction: () => Navigator.pop(context),
      ),
    );
  }
}
