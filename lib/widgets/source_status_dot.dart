import 'package:flutter/material.dart';

import '../models/book_source.dart';
import '../models/source_validation_result.dart';
import '../theme/legado_tokens.dart';

/// 书源校验状态点 — 绿=通过 / 红=失败 / 灰=未校验（对齐 Jingshiro）
class SourceStatusDot extends StatelessWidget {
  final BookSource source;
  final SourceValidationResult? validation;

  const SourceStatusDot({
    super.key,
    required this.source,
    this.validation,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (validation != null) {
      color = validation!.pipelineOk
          ? LegadoTokens.sourceDotGreen
          : LegadoTokens.sourceDotRed;
    } else {
      // 未校验：灰点；无发现规则时略淡，仍占位对齐列表
      color = LegadoTokens.sourceDotGray.withValues(
        alpha: source.enabled ? 1 : 0.45,
      );
    }

    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
