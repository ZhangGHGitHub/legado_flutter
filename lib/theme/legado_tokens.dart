import 'package:flutter/material.dart';

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

  static const Color sourceDotGreen = Color(0xFF4CAF50);
  static const Color sourceDotRed = Color(0xFFE53935);

  static BorderRadius get cardRadius => BorderRadius.circular(radiusCard);
  static BorderRadius get coverRadius => BorderRadius.circular(radiusCover);
}
