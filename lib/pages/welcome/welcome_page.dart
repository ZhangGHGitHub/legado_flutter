import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/legado_tokens.dart';

/// 欢迎页 — 对齐 Jingshiro/legado [activity_welcome.xml] + [WelcomeActivity]
///
/// 视觉：竖排「阅读 / 享受美好时光」、书本图标、「品读万千故事」。
/// 行为：仅首次启动展示功能简介 + 隐私确认；完成后写入 SharedPreferences，回访用户直达主页。
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, this.onFinished});

  /// 与 [MainShell] 隐私 Dialog 同源 key，避免重复弹窗。
  static const privacyAcceptedKey = 'legado_privacy_accepted';

  /// 欢迎引导已完成（含跳过）；为 true 时不再展示本页。
  static const welcomeCompletedKey = 'legado_welcome_completed';

  final VoidCallback? onFinished;

  /// 是否应展示欢迎页。已同意隐私的老用户自动标记完成，不阻断回访。
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(welcomeCompletedKey) == true) return false;
    if (prefs.getBool(privacyAcceptedKey) == true) {
      await prefs.setBool(welcomeCompletedKey, true);
      return false;
    }
    return true;
  }

  Future<void> _complete(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(privacyAcceptedKey, true);
    await prefs.setBool(welcomeCompletedKey, true);
    onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LegadoTokens.spacingLg,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _BrandBlock(accent: accent),
              const SizedBox(height: LegadoTokens.spacingLg),
              Icon(
                Icons.menu_book_rounded,
                size: 120,
                color: accent,
                semanticLabel: '欢迎',
              ),
              const SizedBox(height: LegadoTokens.spacingMd),
              Text(
                '品读万千故事',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: LegadoTokens.spacingLg),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '功能简介',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: LegadoTokens.spacingSm),
                      _IntroLine(
                        icon: Icons.library_books_outlined,
                        text: '书架管理本地与网络书籍，随时续读',
                        color: muted,
                      ),
                      _IntroLine(
                        icon: Icons.search,
                        text: '多书源搜索发现，按源分组浏览结果',
                        color: muted,
                      ),
                      _IntroLine(
                        icon: Icons.chrome_reader_mode_outlined,
                        text: '沉浸阅读：翻页、主题、TTS、缓存',
                        color: muted,
                      ),
                      _IntroLine(
                        icon: Icons.hub_outlined,
                        text: '书源与订阅规则由你导入与管理',
                        color: muted,
                      ),
                      const SizedBox(height: LegadoTokens.spacingMd),
                      Text(
                        '隐私政策与用户协议',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: LegadoTokens.spacingSm),
                      Text(
                        '欢迎使用 Legado Flutter（对齐 Jingshiro/Legado 的 Flutter 复刻版）。\n'
                        '• 本应用为本地阅读工具，书源规则由用户自行导入。\n'
                        '• 搜索、发现、阅读等功能需访问网络，数据仅用于获取书籍内容。\n'
                        '• 书架、书源、阅读进度等数据默认保存在本机。\n'
                        '继续即表示您同意上述说明。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: LegadoTokens.spacingMd),
              Row(
                children: [
                  TextButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: const Text('拒绝并退出'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _complete(context),
                    child: const Text('跳过'),
                  ),
                  const SizedBox(width: LegadoTokens.spacingSm),
                  FilledButton(
                    onPressed: () => _complete(context),
                    child: const Text('同意并进入'),
                  ),
                ],
              ),
              const SizedBox(height: LegadoTokens.spacingMd),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    // 对齐 activity_welcome：ems=1 竖排标题 + 左侧强调色竖线 + 副标题下移 60dp
    const titleSize = 49.0;
    const titleHeight = titleSize * 2 * 1.05;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: titleHeight,
          color: accent,
        ),
        const SizedBox(width: 6),
        _VerticalAccentText(
          text: '阅读',
          fontSize: titleSize,
          color: accent,
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: _VerticalAccentText(
            text: '享受美好时光',
            fontSize: 16,
            color: accent,
          ),
        ),
      ],
    );
  }
}

class _VerticalAccentText extends StatelessWidget {
  const _VerticalAccentText({
    required this.text,
    required this.fontSize,
    required this.color,
  });

  final String text;
  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? Theme.of(context).colorScheme.primary;
    return Text(
      text.split('').join('\n'),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        color: resolved,
        height: 1.05,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _IntroLine extends StatelessWidget {
  const _IntroLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LegadoTokens.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: LegadoTokens.spacingSm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
