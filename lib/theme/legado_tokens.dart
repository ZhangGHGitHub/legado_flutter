import 'package:flutter/material.dart';

/// Design.md 命名约定下的尺寸别名（与 [LegadoTokens] 同源）
abstract final class LegadoDimens {
  static const pageHorizontal = LegadoTokens.spacingMd;
  static const pageVertical = 12.0;

  static const spacingSmall = LegadoTokens.spacingXs;
  static const spacingMedium = LegadoTokens.spacingSm;
  static const spacingLarge = LegadoTokens.spacingMd;
  static const spacingXLarge = LegadoTokens.spacingLg;

  static const radiusSmall = 4.0;
  static const radiusMedium = LegadoTokens.radiusCover;
  static const radiusLarge = LegadoTokens.radiusCard;
  static const radiusXLarge = 16.0;

  static const coverGridWidth = LegadoTokens.bookCoverWidthGrid;
  static const coverGridHeight = 96.0;
  static const coverListWidth = 64.0;
  static const coverListHeight = 86.0;
  static const coverAspectRatio = 0.75;

  static const readerPaddingHorizontal = 20.0;
  static const readerLineHeight = 1.6;
  static const readerParagraphSpacing = LegadoTokens.spacingSm;
}

/// Legado MD3 设计 token（对齐 Jingshiro MyFragment / 书架）
abstract final class LegadoTokens {
  static const double radiusCard = 12;
  static const double radiusCover = 8;
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double bookCoverWidthList = 40;
  static const double bookCoverWidthGrid = 72;
  static const double bookCoverWidthDetail = 96;
  static const double sourceChipHeight = 20;
  static const int bookshelfGridCols = 3;

  /// 全局顶栏默认高度（手机竖屏 Material `actionBarSize`）。
  /// 运行时请用 [LegadoChrome.toolbarHeightOf]，勿直接当全端定值。
  static const double toolbarHeight = 56;

  /// 弹窗标题栏默认高度（与 [toolbarHeight] 同源基准）
  static const double dialogTitleBarHeight = 56;

  /// 弹窗圆角（顶栏与 Dialog 共用）
  static const double dialogRadius = 16;

  /// 欢迎/启动页 — 对齐 `activity_welcome.xml`
  static const double welcomeTitleFontSize = 49;
  static const double welcomeSubtitleFontSize = 16;
  static const double welcomeGzhFontSize = 16;
  static const double welcomeGzhLetterSpacingEm = 0.1;
  static const double welcomeTitleLineWidth = 6;
  static const double welcomeTitleGap = 6;
  static const double welcomeSubtitleTop = 60;
  static const double welcomeBookSize = 120;
  static const double welcomeBookGzhGap = 32;
  static const double welcomeBottomMargin = 32;

  /// 与 [LegadoDimens] 对齐的别名
  static const double spacingSmall = spacingXs;
  static const double spacingMedium = spacingSm;
  static const double spacingLarge = spacingMd;
  static const double spacingXLarge = spacingLg;
  static const double radiusSmall = LegadoDimens.radiusSmall;
  static const double radiusMedium = radiusCover;
  static const double radiusLarge = radiusCard;
  static const double coverListWidth = LegadoDimens.coverListWidth;
  static const double coverListHeight = LegadoDimens.coverListHeight;
  static const double pageHorizontal = LegadoDimens.pageHorizontal;

  static const Color sourceDotGreen = Color(0xFF4CAF50);
  static const Color sourceDotRed = Color(0xFFE53935);
  static const Color sourceDotGray = Color(0xFF9E9E9E);

  static BorderRadius get cardRadius => BorderRadius.circular(radiusCard);
  static BorderRadius get coverRadius => BorderRadius.circular(radiusCover);
}
