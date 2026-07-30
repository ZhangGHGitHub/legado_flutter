import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/reader/reader_font_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import '../../../domain/ports/application_http_request_port.dart';
import '../../../theme/legado_tokens.dart';
import '../../../widgets/remote_binary_image.dart';

/// 订阅源网格卡片 — 对齐 Jingshiro `item_rss.xml`（12dp 卡片 / 50dp 图标 / 13sp 双行名）
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
    final font = context.read<ReaderFontPort>();
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: LegadoTokens.cardRadius,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(LegadoTokens.spacingMd),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildIcon(scheme),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
                    fontFamily: font.platformSansFamily(),
                    fontFamilyFallback: font.cjkFallbackFamilies(),
                  ),
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
        child: RemoteBinaryImage(
          url: url,
          policy: ApplicationHttpPolicy.localNetwork,
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
