import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_click_action_prefs_adapter.dart';
import 'package:legado_flutter/models/click_zone.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('preserves click action keys and the menu fallback', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const layout = ClickZoneLayout(
      tl: ClickZoneAction.nextPage,
      tc: ClickZoneAction.nextPage,
      tr: ClickZoneAction.nextPage,
      ml: ClickZoneAction.nextPage,
      mc: ClickZoneAction.nextPage,
      mr: ClickZoneAction.nextPage,
      bl: ClickZoneAction.nextPage,
      bc: ClickZoneAction.nextPage,
      br: ClickZoneAction.nextPage,
    );

    await const SharedPreferencesClickActionPrefsAdapter().save(layout);

    expect(prefs.getInt('clickActionTopLeft'), 1);
    expect(prefs.getInt('clickActionTopCenter'), 1);
    expect(prefs.getInt('clickActionTopRight'), 1);
    expect(prefs.getInt('clickActionMiddleLeft'), 1);
    expect(prefs.getInt('clickActionMiddleCenter'), 0);
    expect(prefs.getInt('clickActionMiddleRight'), 1);
    expect(prefs.getInt('clickActionBottomLeft'), 1);
    expect(prefs.getInt('clickActionBottomCenter'), 1);
    expect(prefs.getInt('clickActionBottomRight'), 1);

    final loaded = await const SharedPreferencesClickActionPrefsAdapter().load();
    expect(loaded.mc, ClickZoneAction.menu);
    expect(loaded.tl, ClickZoneAction.nextPage);
    expect(
      await const SharedPreferencesClickActionPrefsAdapter().isTipShown(),
      isFalse,
    );
    await const SharedPreferencesClickActionPrefsAdapter().markTipShown();
    expect(
      await const SharedPreferencesClickActionPrefsAdapter().isTipShown(),
      isTrue,
    );
  });
}
