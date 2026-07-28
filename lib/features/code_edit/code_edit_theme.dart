import 'package:flutter/material.dart';

/// Sora TextMate 主题色板（对齐 Jingshiro `textmate/*.json` 常用 token）。
class CodeEditPalette {
  const CodeEditPalette({
    required this.name,
    required this.isDark,
    required this.background,
    required this.foreground,
    required this.comment,
    required this.string,
    required this.number,
    required this.keyword,
    required this.storageType,
    required this.function,
    required this.punctuation,
    required this.keyName,
  });

  final String name;
  final bool isDark;
  final Color background;
  final Color foreground;
  final Color comment;
  final Color string;
  final Color number;
  final Color keyword;
  final Color storageType;
  final Color function;
  final Color punctuation;
  final Color keyName;

  /// 与 [CodeEditViewModel.themeFileNames] 顺序一致。
  static const names = [
    'Monokai Dimmed',
    'Monokai',
    'Modern Dark',
    'Modern Light',
    'Solarized Dark',
    'Solarized Light',
    'Abyss',
    'Quiet Light',
  ];

  static CodeEditPalette byIndex(int index) {
    final i = index.clamp(0, names.length - 1);
    return _all[i];
  }

  static const _all = [
    // 0 d_monokai_dimmed — 略降饱和的 Monokai
    CodeEditPalette(
      name: 'Monokai Dimmed',
      isDark: true,
      background: Color(0xFF1E1E1E),
      foreground: Color(0xFFC5C8C6),
      comment: Color(0xFF9A9B99),
      string: Color(0xFFD7C48F),
      number: Color(0xFFA97CA8),
      keyword: Color(0xFFCF6A6A),
      storageType: Color(0xFF7EB8C9),
      function: Color(0xFFA4C26B),
      punctuation: Color(0xFFC5C8C6),
      keyName: Color(0xFFA4C26B),
    ),
    // 1 d_monokai — tokenColors from Jingshiro d_monokai.json
    CodeEditPalette(
      name: 'Monokai',
      isDark: true,
      background: Color(0xFF272822),
      foreground: Color(0xFFF8F8F2),
      comment: Color(0xFF88846F),
      string: Color(0xFFE6DB74),
      number: Color(0xFFAE81FF),
      keyword: Color(0xFFF92672),
      storageType: Color(0xFF66D9EF),
      function: Color(0xFFA6E22E),
      punctuation: Color(0xFFF8F8F2),
      keyName: Color(0xFFA6E22E),
    ),
    // 2 d_modern
    CodeEditPalette(
      name: 'Modern Dark',
      isDark: true,
      background: Color(0xFF1F1F1F),
      foreground: Color(0xFFCCCCCC),
      comment: Color(0xFF6A9955),
      string: Color(0xFFCE9178),
      number: Color(0xFFB5CEA8),
      keyword: Color(0xFF569CD6),
      storageType: Color(0xFF4EC9B0),
      function: Color(0xFFDCDCAA),
      punctuation: Color(0xFFCCCCCC),
      keyName: Color(0xFF9CDCFE),
    ),
    // 3 l_modern
    CodeEditPalette(
      name: 'Modern Light',
      isDark: false,
      background: Color(0xFFFFFFFF),
      foreground: Color(0xFF3B3B3B),
      comment: Color(0xFF008000),
      string: Color(0xFFA31515),
      number: Color(0xFF098658),
      keyword: Color(0xFF0000FF),
      storageType: Color(0xFF267F99),
      function: Color(0xFF795E26),
      punctuation: Color(0xFF3B3B3B),
      keyName: Color(0xFF0451A5),
    ),
    // 4 d_solarized
    CodeEditPalette(
      name: 'Solarized Dark',
      isDark: true,
      background: Color(0xFF002B36),
      foreground: Color(0xFF839496),
      comment: Color(0xFF586E75),
      string: Color(0xFF2AA198),
      number: Color(0xFFD33682),
      keyword: Color(0xFF859900),
      storageType: Color(0xFF268BD2),
      function: Color(0xFF268BD2),
      punctuation: Color(0xFF839496),
      keyName: Color(0xFFB58900),
    ),
    // 5 l_solarized
    CodeEditPalette(
      name: 'Solarized Light',
      isDark: false,
      background: Color(0xFFFDF6E3),
      foreground: Color(0xFF657B83),
      comment: Color(0xFF93A1A1),
      string: Color(0xFF2AA198),
      number: Color(0xFFD33682),
      keyword: Color(0xFF859900),
      storageType: Color(0xFF268BD2),
      function: Color(0xFF268BD2),
      punctuation: Color(0xFF657B83),
      keyName: Color(0xFFB58900),
    ),
    // 6 d_abyss
    CodeEditPalette(
      name: 'Abyss',
      isDark: true,
      background: Color(0xFF000C18),
      foreground: Color(0xFF6688CC),
      comment: Color(0xFF384887),
      string: Color(0xFF22AA44),
      number: Color(0xFFF280D0),
      keyword: Color(0xFF225588),
      storageType: Color(0xFFFFEEBB),
      function: Color(0xFFDDBB88),
      punctuation: Color(0xFF6688CC),
      keyName: Color(0xFFDDBB88),
    ),
    // 7 l_quiet
    CodeEditPalette(
      name: 'Quiet Light',
      isDark: false,
      background: Color(0xFFF5F5F5),
      foreground: Color(0xFF333333),
      comment: Color(0xFF999988),
      string: Color(0xFF448C27),
      number: Color(0xFFAB6526),
      keyword: Color(0xFF4B83CD),
      storageType: Color(0xFF7A3E9D),
      function: Color(0xFFAA3731),
      punctuation: Color(0xFF333333),
      keyName: Color(0xFF4B83CD),
    ),
  ];
}
