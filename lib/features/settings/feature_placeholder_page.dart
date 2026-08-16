import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

/// 通用功能占位页
class FeaturePlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const FeaturePlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(icon: icon, title: '$title开发中', subtitle: subtitle),
    );
  }
}
