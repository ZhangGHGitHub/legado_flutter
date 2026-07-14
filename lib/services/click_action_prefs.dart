import 'package:shared_preferences/shared_preferences.dart';

import '../models/click_zone.dart';

/// 九宫格点击区域（对齐 legado PreferKey.clickAction* / AppConfig）
abstract final class ClickActionPrefs {
  static const _kTL = 'clickActionTopLeft';
  static const _kTC = 'clickActionTopCenter';
  static const _kTR = 'clickActionTopRight';
  static const _kML = 'clickActionMiddleLeft';
  static const _kMC = 'clickActionMiddleCenter';
  static const _kMR = 'clickActionMiddleRight';
  static const _kBL = 'clickActionBottomLeft';
  static const _kBC = 'clickActionBottomCenter';
  static const _kBR = 'clickActionBottomRight';

  /// 默认九宫格（对齐 AppConfig）：左/上多为上一页，右/下多为下一页，中心菜单
  static const ClickZoneLayout defaults = ClickZoneLayout(
    tl: ClickZoneAction.prevPage,
    tc: ClickZoneAction.prevPage,
    tr: ClickZoneAction.nextPage,
    ml: ClickZoneAction.prevPage,
    mc: ClickZoneAction.menu,
    mr: ClickZoneAction.nextPage,
    bl: ClickZoneAction.prevPage,
    bc: ClickZoneAction.nextPage,
    br: ClickZoneAction.nextPage,
  );

  static Future<ClickZoneLayout> load() async {
    final prefs = await SharedPreferences.getInstance();
    var layout = ClickZoneLayout(
      tl: _read(prefs, _kTL, defaults.tl),
      tc: _read(prefs, _kTC, defaults.tc),
      tr: _read(prefs, _kTR, defaults.tr),
      ml: _read(prefs, _kML, defaults.ml),
      mc: _read(prefs, _kMC, defaults.mc),
      mr: _read(prefs, _kMR, defaults.mr),
      bl: _read(prefs, _kBL, defaults.bl),
      bc: _read(prefs, _kBC, defaults.bc),
      br: _read(prefs, _kBR, defaults.br),
    );
    // 对齐 AppConfig.detectClickArea：若无一格为菜单，强制中心为菜单
    if (!layout.hasMenu) {
      layout = layout.copyWith(mc: ClickZoneAction.menu);
      await save(layout);
    }
    return layout;
  }

  static Future<void> save(ClickZoneLayout layout) async {
    var next = layout;
    if (!next.hasMenu) {
      next = next.copyWith(mc: ClickZoneAction.menu);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTL, next.tl.code);
    await prefs.setInt(_kTC, next.tc.code);
    await prefs.setInt(_kTR, next.tr.code);
    await prefs.setInt(_kML, next.ml.code);
    await prefs.setInt(_kMC, next.mc.code);
    await prefs.setInt(_kMR, next.mr.code);
    await prefs.setInt(_kBL, next.bl.code);
    await prefs.setInt(_kBC, next.bc.code);
    await prefs.setInt(_kBR, next.br.code);
  }

  static ClickZoneAction _read(
    SharedPreferences prefs,
    String key,
    ClickZoneAction fallback,
  ) {
    final raw = prefs.getInt(key);
    if (raw == null) return fallback;
    return ClickZoneAction.fromCode(raw);
  }
}
