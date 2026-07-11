import 'package:flutter/material.dart';

import '../../../models/rss_source.dart';
import '../../../theme/legado_tokens.dart';

/// 订阅源网格卡片 — 对齐 item_rss.xml
class RssSourceTile extends StatelessWidget {
  const RssSourceTile({
    super.key,
    required this.name,
    required this.icon,
    this.iconUrl,
    this.onTap,
    this.onLongPress,
  });

  final String name;
  final IconData icon;
  final String? iconUrl;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  factory RssSourceTile.fromSource(
    RssSource source, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return RssSourceTile(
      name: source.sourceName,
      icon: Icons.rss_feed,
      iconUrl: source.sourceIcon.isNotEmpty ? source.sourceIcon : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: LegadoTokens.cardRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(LegadoTokens.spacingMd),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(scheme),
              const SizedBox(height: LegadoTokens.spacingSm + 4),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.2,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme scheme) {
    final url = iconUrl;
    if (url != null && url.startsWith('http')) {
      return ClipRRect(
        borderRadius: LegadoTokens.cardRadius,
        child: Image.network(
          url,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackIcon(scheme),
        ),
      );
    }
    return _fallbackIcon(scheme);
  }

  Widget _fallbackIcon(ColorScheme scheme) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: LegadoTokens.cardRadius,
      ),
      child: Icon(icon, color: scheme.onPrimaryContainer, size: 28),
    );
  }
}
