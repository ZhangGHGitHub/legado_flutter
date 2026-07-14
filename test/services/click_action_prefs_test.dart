import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/click_zone.dart';
import 'package:legado_flutter/services/click_action_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults match legado AppConfig 九宫格', () async {
    final layout = await ClickActionPrefs.load();
    expect(layout.tl, ClickZoneAction.prevPage);
    expect(layout.tc, ClickZoneAction.prevPage);
    expect(layout.tr, ClickZoneAction.nextPage);
    expect(layout.ml, ClickZoneAction.prevPage);
    expect(layout.mc, ClickZoneAction.menu);
    expect(layout.mr, ClickZoneAction.nextPage);
    expect(layout.bl, ClickZoneAction.prevPage);
    expect(layout.bc, ClickZoneAction.nextPage);
    expect(layout.br, ClickZoneAction.nextPage);
  });

  test('persists and forces menu when none set', () async {
    await ClickActionPrefs.save(
      const ClickZoneLayout(
        tl: ClickZoneAction.nextPage,
        tc: ClickZoneAction.nextPage,
        tr: ClickZoneAction.nextPage,
        ml: ClickZoneAction.nextPage,
        mc: ClickZoneAction.nextPage,
        mr: ClickZoneAction.nextPage,
        bl: ClickZoneAction.nextPage,
        bc: ClickZoneAction.nextPage,
        br: ClickZoneAction.nextPage,
      ),
    );
    final layout = await ClickActionPrefs.load();
    expect(layout.mc, ClickZoneAction.menu);
    expect(layout.tr, ClickZoneAction.nextPage);
  });
}
