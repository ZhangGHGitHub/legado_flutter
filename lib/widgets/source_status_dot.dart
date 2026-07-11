import 'package:flutter/material.dart';

import '../pages/explore/explore_utils.dart';
import '../theme/legado_tokens.dart';
import '../models/book_source.dart';

/// 书源状态点 — 对齐 Jingshiro 绿/红点语义
class SourceStatusDot extends StatelessWidget {
  final BookSource source;

  const SourceStatusDot({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final hasExplore = exploreUrlOf(source).trim().isNotEmpty;
    if (!hasExplore) return const SizedBox(width: 10);

    final color = source.enabled
        ? LegadoTokens.sourceDotGreen
        : LegadoTokens.sourceDotRed;

    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
