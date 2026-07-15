import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/legado_tokens.dart';

/// 欢迎/启动页 — 1:1 对齐 Jingshiro [activity_welcome.xml] + [WelcomeActivity]
///
/// 纯启动闪屏：竖排「阅读 / 享受美好时光」、[icon_read_book]、底栏「品读万千故事」。
/// 默认 [welcomeShowTimeMs] 后进入主页（对齐 `PreferKey.welcomeShowTime` 默认 500）。
/// 无功能简介、无隐私按钮（隐私在 [MainShell] Dialog，对齐 MainActivity）。
class WelcomePage extends StatefulWidget {
  const WelcomePage({
    super.key,
    this.onFinished,
    this.showDuration = const Duration(milliseconds: welcomeShowTimeMs),
  });

  /// 对齐 Android `getPrefInt(PreferKey.welcomeShowTime, 500)`。
  static const welcomeShowTimeMs = 500;

  /// 历史 key：回访用户跳过曾写入的「只展一次」引导；启动闪屏每冷启均展示。
  static const welcomeCompletedKey = 'legado_welcome_completed';

  /// 与 [MainShell] 隐私 Dialog 同源 key。
  static const privacyAcceptedKey = 'legado_privacy_accepted';

  final VoidCallback? onFinished;

  /// 测试可注入较短时长；`Duration.zero` 时下一帧即进入（对齐 welcomeShowTime==0）。
  final Duration showDuration;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final d = widget.showDuration;
    if (d <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _timer = Timer(d, _finish);
    }
  }

  void _finish() {
    if (!mounted) return;
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    // 全屏、无 AppBar / Material 额外 chrome — 对齐 WelcomeActivity.fullScreen()
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          const bookSize = LegadoTokens.welcomeBookSize;
          const gapBookGzh = LegadoTokens.welcomeBookGzhGap;
          const gapBottom = LegadoTokens.welcomeBottomMargin;
          // 16sp 单行约占字号高度（letterSpacing 不计高度）
          const gzhHeight = LegadoTokens.welcomeGzhFontSize * 1.2;

          final bookBottom = gapBottom + gzhHeight + gapBookGzh;
          final bookTop = h - bookBottom - bookSize;

          return Stack(
            children: [
              // tv_legado：Top→parent、Bottom→iv_book、vertical_bias=0.4
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: bookTop.clamp(0.0, h),
                child: Align(
                  alignment: const Alignment(0, -0.2), // bias 0.4 → Align y = 2*0.4-1 = -0.2
                  child: _BrandBlock(accent: accent),
                ),
              ),
              // iv_book：120dp，marginBottom 32dp → tv_gzh
              Positioned(
                left: 0,
                right: 0,
                bottom: bookBottom,
                child: Center(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                    child: Image.asset(
                      'assets/welcome/icon_read_book.png',
                      width: bookSize,
                      height: bookSize,
                      fit: BoxFit.contain,
                      semanticLabel: '欢迎',
                    ),
                  ),
                ),
              ),
              // tv_gzh：底边距 32dp
              Positioned(
                left: 0,
                right: 0,
                bottom: gapBottom,
                child: Text(
                  '品读万千故事',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: LegadoTokens.welcomeGzhFontSize,
                    color: accent,
                    // Android letterSpacing 0.1em → 0.1 * 16sp
                    letterSpacing:
                        LegadoTokens.welcomeGzhFontSize *
                            LegadoTokens.welcomeGzhLetterSpacingEm,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    // ems=1 竖排 + 左侧 6dp 强调色竖线（等高 tv_title）+ 副标题 marginTop 60dp
    const titleSize = LegadoTokens.welcomeTitleFontSize;
    const titleHeight = titleSize * 2 * 1.05;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: LegadoTokens.welcomeTitleLineWidth,
          height: titleHeight,
          color: accent,
        ),
        const SizedBox(width: LegadoTokens.welcomeTitleGap),
        _VerticalAccentText(
          text: '阅读',
          fontSize: titleSize,
          color: accent,
        ),
        const SizedBox(width: LegadoTokens.welcomeTitleGap),
        Padding(
          padding: const EdgeInsets.only(top: LegadoTokens.welcomeSubtitleTop),
          child: _VerticalAccentText(
            text: '享受美好时光',
            fontSize: LegadoTokens.welcomeSubtitleFontSize,
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
    this.color,
  });

  final String text;
  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.primary;
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
