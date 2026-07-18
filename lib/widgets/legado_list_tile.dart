import 'package:flutter/material.dart';

/// 我的 / 设置列表行 — 对齐 `fragment_my_config.xml` 设置项
/// （行高 56dp、图标 24、标题 16sp、副标题 12sp）
class LegadoListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const LegadoListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasSub = subtitle != null && subtitle!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 24, color: scheme.onSurfaceVariant),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.2,
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (hasSub) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.15,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing case final t?) t,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LegadoListDivider extends StatelessWidget {
  const LegadoListDivider({super.key});

  @override
  Widget build(BuildContext context) {
    // Jingshiro 设置列表无分割线，保留零高度以兼容旧调用
    return const SizedBox.shrink();
  }
}
