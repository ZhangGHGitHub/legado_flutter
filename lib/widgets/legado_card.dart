import 'package:flutter/material.dart';

import '../theme/legado_tokens.dart';

/// 统一圆角卡片（对齐 Jingshiro MD3 卡片）
class LegadoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const LegadoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(LegadoTokens.spacingSm),
        child: child,
      ),
    );
  }
}
