import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/click_zone.dart';
import '../../models/read_style_config.dart';
import '../../models/theme_typography.dart';
import '../../services/read_style_prefs.dart';
import '../../services/reader_font_loader.dart';
import 'bg_text_config_panel.dart';

export '../../models/click_zone.dart' show ClickZoneAction, ClickZoneLayout;

/// 阅读器屏幕方向（UI-2 更多设置）
enum ScreenOrientationMode {
  system('跟随系统'),
  portrait('竖屏'),
  landscape('横屏');

  const ScreenOrientationMode(this.label);
  final String label;
}

/// 字重（对齐 legado textBold：0 正常 / 1 粗体 / 2 细体 · 「中/粗/细」）
enum ReaderFontWeight {
  normal(0, '正常'),
  bold(1, '粗体'),
  light(2, '细体');

  const ReaderFontWeight(this.code, this.label);
  final int code;
  final String label;

  FontWeight get flutterWeight => switch (this) {
        ReaderFontWeight.normal => FontWeight.w400,
        ReaderFontWeight.bold => FontWeight.w700,
        ReaderFontWeight.light => FontWeight.w300,
      };

  static ReaderFontWeight fromCode(int code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return ReaderFontWeight.normal;
  }
}

/// 简繁（对齐 chineseConverterType：0 关 / 1 繁→简 / 2 简→繁）
enum ChineseConvertMode {
  off(0, '关闭'),
  traditionalToSimplified(1, '繁体转简体'),
  simplifiedToTraditional(2, '简体转繁体');

  const ChineseConvertMode(this.code, this.label);
  final int code;
  final String label;

  static ChineseConvertMode fromCode(int code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return ChineseConvertMode.off;
  }
}

/// 屏幕超时（对齐 legado keepLight + arrays：默认 / 1 / 5 / 10 分钟 / 常亮）
/// 存值为秒；-1 = 常亮；0 = 系统默认。
enum ScreenTimeoutMode {
  system(0, '默认'),
  oneMinute(60, '1分钟'),
  fiveMinutes(300, '5分钟'),
  tenMinutes(600, '10分钟'),
  always(-1, '常亮');

  const ScreenTimeoutMode(this.seconds, this.label);
  final int seconds;
  final String label;

  static ScreenTimeoutMode fromSeconds(int seconds) {
    for (final v in values) {
      if (v.seconds == seconds) return v;
    }
    return ScreenTimeoutMode.system;
  }
}

/// 翻页动画（对齐 PageAnim：覆盖 / 滑动 / 仿真 / 滚动 / 无）
enum PageAnimMode {
  cover('cover', '覆盖'),
  slide('slide', '滑动'),
  simulation('simulation', '仿真'),
  scroll('scroll', '滚动'),
  none('none', '无');

  const PageAnimMode(this.id, this.label);
  final String id;
  final String label;

  bool get isHorizontalPaged =>
      this == cover || this == slide || this == simulation || this == none;

  static PageAnimMode fromId(String id) {
    for (final v in values) {
      if (v.id == id) return v;
    }
    return PageAnimMode.slide;
  }
}

/// 阅读器「界面」面板 — Phase F UI-2（对齐 dialog_read_bg_text / dialog_read_book_style）
class ReaderSettings {
  final double fontSize;
  final double lineHeight;
  final String themeName; // 'paper' | 'white' | 'dark' | 'green'
  /// 翻页动画 id：cover | slide | simulation | scroll | none
  final String pageMode;
  /// 空串 = 系统默认；其余为内置字体族名
  final String fontFamily;
  final double paddingHorizontal;
  final double paddingVertical;
  final bool showTime;
  final bool showBattery;
  final bool showPageInfo;
  final bool volumeKeyTurnPage;
  /// 朗读时音量键仍翻页（对齐 volumeKeyPageOnPlay；默认开）
  final bool volumeKeyPageOnPlay;
  /// 自动阅读翻页间隔（秒）
  final double autoReadIntervalSec;
  /// 九宫格点击区（对齐 clickActionTL…BR；默认见 ClickActionPrefs.defaults）
  final ClickZoneAction clickTL;
  final ClickZoneAction clickTC;
  final ClickZoneAction clickTR;
  final ClickZoneAction clickML;
  final ClickZoneAction clickMC;
  final ClickZoneAction clickMR;
  final ClickZoneAction clickBL;
  final ClickZoneAction clickBC;
  final ClickZoneAction clickBR;
  final ScreenOrientationMode screenOrientation;
  /// true = 不叠加阅读亮度遮罩
  final bool brightnessFollowSystem;
  /// 手动亮度 0.15–1.0（越低遮罩越暗）
  final double brightness;
  /// 屏幕超时（legado keepLight：默认/1/5/10/常亮）
  final ScreenTimeoutMode screenTimeout;
  /// 蓝牙翻页器常见键：PageUp/Down、媒体上一曲/下一曲
  final bool bluetoothPageKey;
  /// LogicalKeyboardKey.keyId 字符串；空=未设置
  final String? customPrevPageKey;
  final String? customNextPageKey;
  /// 字重
  final ReaderFontWeight fontWeight;
  /// 首行缩进字符数 0–4（全角空格，对齐 indent_*）
  final int paragraphIndent;
  /// 字距（Flutter letterSpacing）
  final double letterSpacing;
  /// 段距倍率（段落后额外空行系数，对齐 paragraphSpacing）
  final double paragraphSpacing;
  /// 简繁
  final ChineseConvertMode chineseConvert;
  /// 隐藏状态栏（阅读沉浸）
  final bool hideStatusBar;
  /// 隐藏导航栏
  final bool hideNavigationBar;
  /// 扩展到刘海（正文贴边，对齐 readBodyToLh）
  final bool expandIntoCutout;
  /// 文字两端对齐
  final bool textFullJustify;
  /// 文字底部对齐（对齐 textBottomJustify；分页时不足一页贴底）
  final bool textBottomJustify;
  /// 日间/夜间共用排版（对齐 ReadBookConfig.shareLayout；默认开）
  final bool shareLayout;
  /// 主题槽位颜色/背景图覆盖（主题名 → 覆盖）
  final Map<String, ReadStyleSlotOverride> themeOverrides;

  const ReaderSettings({
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
    this.themeName = 'paper',
    this.pageMode = 'slide',
    this.fontFamily = '',
    this.paddingHorizontal = 20.0,
    this.paddingVertical = 8.0,
    this.showTime = true,
    this.showBattery = false,
    this.showPageInfo = true,
    this.volumeKeyTurnPage = false,
    this.volumeKeyPageOnPlay = true,
    this.autoReadIntervalSec = 5.0,
    this.clickTL = ClickZoneAction.prevPage,
    this.clickTC = ClickZoneAction.prevPage,
    this.clickTR = ClickZoneAction.nextPage,
    this.clickML = ClickZoneAction.prevPage,
    this.clickMC = ClickZoneAction.menu,
    this.clickMR = ClickZoneAction.nextPage,
    this.clickBL = ClickZoneAction.prevPage,
    this.clickBC = ClickZoneAction.nextPage,
    this.clickBR = ClickZoneAction.nextPage,
    this.screenOrientation = ScreenOrientationMode.system,
    this.brightnessFollowSystem = true,
    this.brightness = 1.0,
    this.screenTimeout = ScreenTimeoutMode.system,
    this.bluetoothPageKey = false,
    this.customPrevPageKey,
    this.customNextPageKey,
    this.fontWeight = ReaderFontWeight.normal,
    this.paragraphIndent = 2,
    this.letterSpacing = 0.0,
    this.paragraphSpacing = 0.2,
    this.chineseConvert = ChineseConvertMode.off,
    this.hideStatusBar = true,
    this.hideNavigationBar = false,
    this.expandIntoCutout = false,
    this.textFullJustify = true,
    this.textBottomJustify = true,
    this.shareLayout = true,
    this.themeOverrides = const {},
  });

  PageAnimMode get pageAnim => PageAnimMode.fromId(pageMode);

  /// 兼容旧布尔：常亮档
  bool get keepScreenOn => screenTimeout == ScreenTimeoutMode.always;

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    String? themeName,
    String? pageMode,
    String? fontFamily,
    double? paddingHorizontal,
    double? paddingVertical,
    bool? showTime,
    bool? showBattery,
    bool? showPageInfo,
    bool? volumeKeyTurnPage,
    bool? volumeKeyPageOnPlay,
    double? autoReadIntervalSec,
    ClickZoneAction? clickTL,
    ClickZoneAction? clickTC,
    ClickZoneAction? clickTR,
    ClickZoneAction? clickML,
    ClickZoneAction? clickMC,
    ClickZoneAction? clickMR,
    ClickZoneAction? clickBL,
    ClickZoneAction? clickBC,
    ClickZoneAction? clickBR,
    ScreenOrientationMode? screenOrientation,
    bool? brightnessFollowSystem,
    double? brightness,
    ScreenTimeoutMode? screenTimeout,
    bool? keepScreenOn,
    bool? bluetoothPageKey,
    String? customPrevPageKey,
    String? customNextPageKey,
    bool clearCustomPrevPageKey = false,
    bool clearCustomNextPageKey = false,
    ReaderFontWeight? fontWeight,
    int? paragraphIndent,
    double? letterSpacing,
    double? paragraphSpacing,
    ChineseConvertMode? chineseConvert,
    bool? hideStatusBar,
    bool? hideNavigationBar,
    bool? expandIntoCutout,
    bool? textFullJustify,
    bool? textBottomJustify,
    bool? shareLayout,
    Map<String, ReadStyleSlotOverride>? themeOverrides,
  }) {
    var timeout = screenTimeout ?? this.screenTimeout;
    if (keepScreenOn != null) {
      timeout = keepScreenOn
          ? ScreenTimeoutMode.always
          : (timeout == ScreenTimeoutMode.always
              ? ScreenTimeoutMode.system
              : timeout);
    }
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      themeName: themeName ?? this.themeName,
      pageMode: pageMode ?? this.pageMode,
      fontFamily: fontFamily ?? this.fontFamily,
      paddingHorizontal: paddingHorizontal ?? this.paddingHorizontal,
      paddingVertical: paddingVertical ?? this.paddingVertical,
      showTime: showTime ?? this.showTime,
      showBattery: showBattery ?? this.showBattery,
      showPageInfo: showPageInfo ?? this.showPageInfo,
      volumeKeyTurnPage: volumeKeyTurnPage ?? this.volumeKeyTurnPage,
      volumeKeyPageOnPlay: volumeKeyPageOnPlay ?? this.volumeKeyPageOnPlay,
      autoReadIntervalSec: autoReadIntervalSec ?? this.autoReadIntervalSec,
      clickTL: clickTL ?? this.clickTL,
      clickTC: clickTC ?? this.clickTC,
      clickTR: clickTR ?? this.clickTR,
      clickML: clickML ?? this.clickML,
      clickMC: clickMC ?? this.clickMC,
      clickMR: clickMR ?? this.clickMR,
      clickBL: clickBL ?? this.clickBL,
      clickBC: clickBC ?? this.clickBC,
      clickBR: clickBR ?? this.clickBR,
      screenOrientation: screenOrientation ?? this.screenOrientation,
      brightnessFollowSystem:
          brightnessFollowSystem ?? this.brightnessFollowSystem,
      brightness: brightness ?? this.brightness,
      screenTimeout: timeout,
      bluetoothPageKey: bluetoothPageKey ?? this.bluetoothPageKey,
      customPrevPageKey: clearCustomPrevPageKey
          ? null
          : (customPrevPageKey ?? this.customPrevPageKey),
      customNextPageKey: clearCustomNextPageKey
          ? null
          : (customNextPageKey ?? this.customNextPageKey),
      fontWeight: fontWeight ?? this.fontWeight,
      paragraphIndent: paragraphIndent ?? this.paragraphIndent,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      chineseConvert: chineseConvert ?? this.chineseConvert,
      hideStatusBar: hideStatusBar ?? this.hideStatusBar,
      hideNavigationBar: hideNavigationBar ?? this.hideNavigationBar,
      expandIntoCutout: expandIntoCutout ?? this.expandIntoCutout,
      textFullJustify: textFullJustify ?? this.textFullJustify,
      textBottomJustify: textBottomJustify ?? this.textBottomJustify,
      shareLayout: shareLayout ?? this.shareLayout,
      themeOverrides: themeOverrides ?? this.themeOverrides,
    );
  }

  /// 解析当前主题（预设 + 槽位覆盖）
  ReaderTheme resolveTheme() {
    final base = ReaderTheme.themes[themeName] ?? ReaderTheme.themes['paper']!;
    final o = themeOverrides[themeName];
    if (o == null) return base;
    return ReaderTheme(
      background: o.background ?? base.background,
      text: o.text ?? base.text,
      appBar: base.appBar,
      progress: o.accent ?? base.progress,
      bgImagePath: o.bgImagePath,
    );
  }

  String get fontLabel => ReaderFontLoader.displayName(fontFamily);

  String get indentLabel {
    const labels = ['无缩进', '一字符缩进', '二字符缩进', '三字符缩进', '四字符缩进'];
    final i = paragraphIndent.clamp(0, 4);
    return labels[i];
  }

  /// 段首缩进串（全角空格）
  String get paragraphIndentText => '　' * paragraphIndent.clamp(0, 4);
}

/// 阅读主题预设
class ReaderTheme {
  final Color background;
  final Color text;
  final Color appBar;
  final Color progress;
  /// 可选背景图路径（zip 导入 bgType=2）
  final String? bgImagePath;

  const ReaderTheme({
    required this.background,
    required this.text,
    required this.appBar,
    required this.progress,
    this.bgImagePath,
  });

  static const Map<String, ReaderTheme> themes = {
    'paper': ReaderTheme(
      background: Color(0xFFF5F0E8),
      text: Color(0xFF3C3C3C),
      appBar: Colors.white,
      progress: Colors.orange,
    ),
    'white': ReaderTheme(
      background: Colors.white,
      text: Color(0xFF333333),
      appBar: Colors.white,
      progress: Colors.blue,
    ),
    'dark': ReaderTheme(
      background: Color(0xFF1E1E1E),
      text: Color(0xFFCCCCCC),
      appBar: Color(0xFF2D2D2D),
      progress: Colors.tealAccent,
    ),
    'green': ReaderTheme(
      background: Color(0xFFC7EDCC),
      text: Color(0xFF2C4C3B),
      appBar: Color(0xFFE8F5E9),
      progress: Colors.green,
    ),
  };

  static const List<(String id, String label)> themeSlots = [
    ('paper', '米黄'),
    ('white', '白'),
    ('dark', '暗黑'),
    ('green', '护眼绿'),
  ];
}

/// ═══════════════════════════════════════════════════
class ReaderSettingsPanel extends StatefulWidget {
  final ReaderSettings settings;
  final ValueChanged<ReaderSettings> onChanged;
  final VoidCallback? onOpenTts;
  final VoidCallback? onOpenAutoRead;
  final VoidCallback? onOpenClickZone;
  final VoidCallback? onOpenMoreSettings;

  const ReaderSettingsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
    this.onOpenTts,
    this.onOpenAutoRead,
    this.onOpenClickZone,
    this.onOpenMoreSettings,
  });

  @override
  State<ReaderSettingsPanel> createState() => ReaderSettingsPanelState();
}

class ReaderSettingsPanelState extends State<ReaderSettingsPanel> {
  late ReaderSettings _s;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
  }

  @override
  void didUpdateWidget(covariant ReaderSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _s = widget.settings;
    }
  }

  void _update(ReaderSettings s) {
    setState(() => _s = s);
    widget.onChanged(s);
    if (!s.shareLayout) {
      unawaited(
        ReadStylePrefs.saveTypography(
          s.themeName,
          ThemeTypography.fromReaderSettings(s),
        ),
      );
    }
  }

  Future<void> _applyThemeTypography(String themeName) async {
    if (_s.shareLayout) return;
    final saved = await ReadStylePrefs.loadTypography(themeName);
    if (!mounted) return;
    if (saved != null) {
      _update(saved.applyTo(_s.copyWith(themeName: themeName)));
    } else {
      _update(_s.copyWith(themeName: themeName));
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Color _slotColor(String themeId) {
    final o = _s.themeOverrides[themeId];
    if (o?.background != null) return o!.background!;
    return ReaderTheme.themes[themeId]?.background ?? const Color(0xFFF5F0E8);
  }

  String _slotLabel(String themeId, String fallback) {
    final name = _s.themeOverrides[themeId]?.name;
    if (name != null && name.isNotEmpty) return name;
    return fallback;
  }

  Future<void> _openBgTextConfig(String themeId, String label) async {
    final base = ReaderTheme.themes[themeId] ?? ReaderTheme.themes['paper']!;
    final result = await BgTextConfigPanel.show(
      context,
      themeName: themeId,
      themeLabel: label,
      baseTheme: base,
      initialOverride: _s.themeOverrides[themeId],
      settings: _s,
    );
    if (result == null || !mounted) return;

    final nextOverrides = Map<String, ReadStyleSlotOverride>.from(
      _s.themeOverrides,
    );
    if (result.cleared) {
      nextOverrides.remove(themeId);
      await ReadStylePrefs.clearOverride(themeId);
    } else {
      nextOverrides[themeId] = result.override;
      await ReadStylePrefs.upsertOverride(themeId, result.override);
    }

    var next = _s.copyWith(
      themeName: themeId,
      themeOverrides: nextOverrides,
    );
    await ReadStylePrefs.saveThemeName(themeId);
    // 导入 zip 时应用排版；关闭共用布局时仅提示（排版仍全局，缺口见计划）
    if (result.appliedTypography != null) {
      if (_s.shareLayout) {
        next = result.appliedTypography!.copyWith(
          themeName: themeId,
          themeOverrides: nextOverrides,
          shareLayout: _s.shareLayout,
        );
      } else {
        next = result.appliedTypography!.copyWith(
          themeName: themeId,
          themeOverrides: nextOverrides,
          shareLayout: false,
        );
        if (mounted) {
          _toast('已取消共用布局：排版仍全局应用（每主题独立排版待补）');
        }
      }
    }
    _update(next);
  }

  Future<void> _pickFontWeight() async {
    final picked = await showDialog<ReaderFontWeight>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('文章字重切换'),
        children: [
          for (final w in ReaderFontWeight.values)
            ListTile(
              title: Text(w.label),
              trailing: _s.fontWeight == w
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, w),
            ),
        ],
      ),
    );
    if (picked != null) _update(_s.copyWith(fontWeight: picked));
  }

  Future<void> _pickIndent() async {
    const labels = ['无缩进', '一字符缩进', '二字符缩进', '三字符缩进', '四字符缩进'];
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('缩进'),
        children: [
          for (var i = 0; i < labels.length; i++)
            ListTile(
              title: Text(labels[i]),
              trailing: _s.paragraphIndent == i
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, i),
            ),
        ],
      ),
    );
    if (picked != null) _update(_s.copyWith(paragraphIndent: picked));
  }

  Future<void> _pickChineseConvert() async {
    final picked = await showDialog<ChineseConvertMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('中文简繁体转换'),
        children: [
          for (final m in ChineseConvertMode.values)
            ListTile(
              title: Text(m.label),
              trailing: _s.chineseConvert == m
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, m),
            ),
        ],
      ),
    );
    if (picked != null) _update(_s.copyWith(chineseConvert: picked));
  }

  Widget _fontWeightChipLabel(ReaderFontWeight w) {
    final accent = Theme.of(context).colorScheme.primary;
    TextSpan span(String ch, bool on) => TextSpan(
          text: ch,
          style: TextStyle(
            fontSize: 13,
            color: on ? accent : null,
            fontWeight: on ? FontWeight.w700 : FontWeight.w400,
          ),
        );
    return Text.rich(
      TextSpan(
        children: [
          span('中', w == ReaderFontWeight.normal),
          const TextSpan(text: '/'),
          span('粗', w == ReaderFontWeight.bold),
          const TextSpan(text: '/'),
          span('细', w == ReaderFontWeight.light),
        ],
      ),
    );
  }

  Widget _chineseChipLabel(ChineseConvertMode m) {
    final accent = Theme.of(context).colorScheme.primary;
    TextSpan span(String ch, bool on) => TextSpan(
          text: ch,
          style: TextStyle(
            fontSize: 13,
            color: on ? accent : null,
            fontWeight: on ? FontWeight.w700 : FontWeight.w400,
          ),
        );
    return Text.rich(
      TextSpan(
        children: [
          span('简', m == ChineseConvertMode.traditionalToSimplified),
          const TextSpan(text: '/'),
          span('繁', m == ChineseConvertMode.simplifiedToTraditional),
        ],
      ),
    );
  }

  Future<void> _pickFont() async {
    final customFiles = await ReaderFontLoader.listCustomFontFiles();
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Widget tile(String family, String label) {
          final selected = _s.fontFamily == family;
          final previewFamily = ReaderFontLoader.resolveFamilySync(family);
          return ListTile(
            title: Text(
              label,
              style: TextStyle(
                fontFamily: previewFamily,
                fontFamilyFallback: ReaderFontLoader.cjkFallbackFamilies(),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: selected
                ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                : null,
            onTap: () => Navigator.pop(ctx, family),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '选择字体',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // 对齐 Jingshiro ChapterProvider：空 / SERIF / MONOSPACE
              tile('', '系统默认（无衬线）'),
              tile('serif', '衬线（serif）'),
              tile('monospace', '等宽（monospace）'),
              if (customFiles.isNotEmpty) ...[
                const Divider(height: 1),
                for (final f in customFiles)
                  tile(f.path, ReaderFontLoader.displayName(f.path)),
              ],
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('导入自定义字体'),
                subtitle: const Text('将 .ttf/.otf 放入应用字体目录后可选'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final dir = await ReaderFontLoader.fontDirectory();
                  _toast('请将字体文件复制到：\n${dir.path}');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    if (ReaderFontLoader.isFontFilePath(picked)) {
      await ReaderFontLoader.ensureLoaded(picked);
    }
    if (!mounted) return;
    _update(_s.copyWith(fontFamily: picked));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Text(
                    '界面',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),

            // ── 对齐 dialog_read_book_style 顶栏芯片：中/粗/细 · 字体 · 缩进 · 简/繁 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StyleChip(
                    onTap: _pickFontWeight,
                    child: _fontWeightChipLabel(_s.fontWeight),
                  ),
                  _StyleChip(
                    label: '字体',
                    selected: _s.fontFamily.isNotEmpty,
                    onTap: _pickFont,
                  ),
                  _StyleChip(
                    label: '缩进',
                    selected: _s.paragraphIndent > 0,
                    onTap: _pickIndent,
                  ),
                  _StyleChip(
                    onTap: _pickChineseConvert,
                    child: _chineseChipLabel(_s.chineseConvert),
                  ),
                  _StyleChip(
                    label: '边距',
                    selected: true,
                    onTap: () => _toast('见下方左右/上下边距滑块'),
                  ),
                  _StyleChip(
                    label: '信息',
                    selected: _s.showPageInfo || _s.showTime || _s.showBattery,
                    onTap: () => _toast('见下方「信息区」开关'),
                  ),
                ],
              ),
            ),

            // ── 字号 / 字距 / 行距 / 段距（legado 顺序）──
            _sliderBlock(
              label: '字号',
              leading: const Icon(Icons.text_fields, size: 20),
              value: _s.fontSize,
              min: 12,
              max: 32,
              divisions: 20,
              valueText: '${_s.fontSize.toInt()}',
              onChanged: (v) => _update(_s.copyWith(fontSize: v)),
            ),
            _sliderBlock(
              label: '字距',
              leading: const Text('字', style: TextStyle(fontSize: 12)),
              value: _s.letterSpacing,
              min: -0.5,
              max: 0.5,
              divisions: 20,
              valueText: _s.letterSpacing.toStringAsFixed(2),
              onChanged: (v) => _update(_s.copyWith(letterSpacing: v)),
            ),
            _sliderBlock(
              label: '行距',
              leading: const Text('A', style: TextStyle(fontSize: 12)),
              value: _s.lineHeight,
              min: 1.2,
              max: 2.5,
              divisions: 13,
              valueText: _s.lineHeight.toStringAsFixed(1),
              onChanged: (v) => _update(_s.copyWith(lineHeight: v)),
            ),
            _sliderBlock(
              label: '段距',
              leading: const Icon(Icons.format_line_spacing, size: 18),
              value: _s.paragraphSpacing,
              min: 0,
              max: 2.0,
              divisions: 20,
              valueText: _s.paragraphSpacing.toStringAsFixed(1),
              onChanged: (v) => _update(_s.copyWith(paragraphSpacing: v)),
            ),
            const SizedBox(height: 4),

            // ── 边距 ──
            _sliderBlock(
              label: '左右边距',
              leading: const Icon(Icons.swap_horiz, size: 18),
              value: _s.paddingHorizontal,
              min: 8,
              max: 48,
              divisions: 20,
              valueText: '${_s.paddingHorizontal.toInt()}',
              onChanged: (v) =>
                  _update(_s.copyWith(paddingHorizontal: v.roundToDouble())),
            ),
            _sliderBlock(
              label: '上下边距',
              leading: const Icon(Icons.swap_vert, size: 18),
              value: _s.paddingVertical,
              min: 0,
              max: 32,
              divisions: 16,
              valueText: '${_s.paddingVertical.toInt()}',
              onChanged: (v) =>
                  _update(_s.copyWith(paddingVertical: v.roundToDouble())),
            ),
            const SizedBox(height: 8),

            // ── 翻页动画（legado PageAnim：覆盖/滑动/仿真/滚动/无）──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('翻页动画', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in PageAnimMode.values)
                        _ModeChip(
                          icon: switch (m) {
                            PageAnimMode.cover => Icons.auto_stories_outlined,
                            PageAnimMode.slide => Icons.swipe,
                            PageAnimMode.simulation => Icons.menu_book_outlined,
                            PageAnimMode.scroll => Icons.unfold_more,
                            PageAnimMode.none => Icons.flash_off_outlined,
                          },
                          label: m.label,
                          selected: _s.pageMode == m.id,
                          onTap: () => _update(_s.copyWith(pageMode: m.id)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 阅读主题（对齐 ReadStyleDialog：共用布局 + 长按自定义/zip）──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('阅读主题', style: TextStyle(fontSize: 13)),
                      ),
                      const Text('共用布局', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _s.shareLayout,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (v) async {
                            final next = v ?? true;
                            _update(_s.copyWith(shareLayout: next));
                            await ReadStylePrefs.saveShareLayout(next);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '文字颜色和背景（长按自定义）',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final slot in ReaderTheme.themeSlots)
                        _ThemeDot(
                          color: _slotColor(slot.$1),
                          name: _slotLabel(slot.$1, slot.$2),
                          selected: _s.themeName == slot.$1,
                          onTap: () async {
                            _update(_s.copyWith(themeName: slot.$1));
                            await ReadStylePrefs.saveThemeName(slot.$1);
                          },
                          onLongPress: () => _openBgTextConfig(slot.$1, slot.$2),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),

            // ── 信息区开关 ──
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text('信息区', style: TextStyle(fontSize: 13)),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              title: const Text('显示页码', style: TextStyle(fontSize: 13)),
              value: _s.showPageInfo,
              onChanged: (v) => _update(_s.copyWith(showPageInfo: v)),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              title: const Text('显示时间', style: TextStyle(fontSize: 13)),
              value: _s.showTime,
              onChanged: (v) => _update(_s.copyWith(showTime: v)),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              title: const Text('显示电量', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                '底栏显示系统电量（battery_plus）',
                style: TextStyle(fontSize: 11),
              ),
              value: _s.showBattery,
              onChanged: (v) => _update(_s.copyWith(showBattery: v)),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              title: const Text('音量键翻页', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                '部分桌面环境可能无效；更多键见「更多设置」',
                style: TextStyle(fontSize: 11),
              ),
              value: _s.volumeKeyTurnPage,
              onChanged: (v) => _update(_s.copyWith(volumeKeyTurnPage: v)),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              title: const Text('朗读时音量键翻页', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                '关闭后朗读中音量键调音量（对齐 volumeKeyPageOnPlay）',
                style: TextStyle(fontSize: 11),
              ),
              value: _s.volumeKeyPageOnPlay,
              onChanged: (v) =>
                  _update(_s.copyWith(volumeKeyPageOnPlay: v)),
            ),

            const Divider(),

            // ── UI-2：TTS / 自动阅读 / 点击区域 / 更多 ──
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              leading: const Icon(Icons.record_voice_over_outlined, size: 22),
              title: const Text('朗读 (TTS)', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                '语速/音调/引擎 · 系统 TTS 发音',
                style: TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenTts?.call();
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              leading: const Icon(Icons.auto_stories_outlined, size: 22),
              title: const Text('自动阅读', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                '间隔 ${_s.autoReadIntervalSec.toStringAsFixed(1)}s · 定时翻页',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenAutoRead?.call();
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              leading: const Icon(Icons.touch_app_outlined, size: 22),
              title: const Text('点击区域', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                '九宫格 · 中=${_s.clickMC.label}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenClickZone?.call();
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              leading: const Icon(Icons.tune, size: 22),
              title: const Text('设置', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                '${_s.screenOrientation.label} · '
                '${_s.brightnessFollowSystem ? '亮度跟随系统' : '亮度${(_s.brightness * 100).round()}%'}'
                '${_s.bluetoothPageKey ? ' · 蓝牙翻页' : ''}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenMoreSettings?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sliderBlock({
    required String label,
    required Widget leading,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueText,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            children: [
              leading,
              Expanded(
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: valueText,
                  onChanged: onChanged,
                ),
              ),
              Text(valueText, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 对齐 dialog_read_book_style StrokeTextView 芯片
class _StyleChip extends StatelessWidget {
  final String? label;
  final Widget? child;
  final bool selected;
  final VoidCallback onTap;

  const _StyleChip({
    this.label,
    this.child,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? primary : Colors.grey.shade400,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: child ??
              Text(
                label ?? '',
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? primary : null,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
        ),
      ),
    );
  }
}

/// 翻页模式选择标签
class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 主题色圆点选择器（短按切换；长按打开文字/背景/zip 导入）
class _ThemeDot extends StatelessWidget {
  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ThemeDot({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
                width: selected ? 3 : 1,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
