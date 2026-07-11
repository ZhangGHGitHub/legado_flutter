import 'package:flutter/material.dart';

import '../theme/legado_tokens.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LegadoTokens.spacingSm,
        LegadoTokens.spacingSm,
        LegadoTokens.spacingSm,
        LegadoTokens.spacingXs,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
