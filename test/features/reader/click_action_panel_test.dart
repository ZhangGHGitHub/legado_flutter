import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/preferences/click_action_prefs_port.dart';
import 'package:legado_flutter/features/reader/click_action_panel.dart';
import 'package:legado_flutter/features/reader/reader_settings.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('saves through the click action preference port', (tester) async {
    final port = _FakeClickActionPrefsPort();
    ReaderSettings? changed;

    await tester.pumpWidget(
      Provider<ClickActionPrefsPort>.value(
        value: port,
        child: MaterialApp(
          home: ClickActionPanel(
            settings: const ReaderSettings(
              clickTL: ClickZoneAction.nextPage,
              clickTC: ClickZoneAction.nextPage,
              clickTR: ClickZoneAction.nextPage,
              clickML: ClickZoneAction.nextPage,
              clickMC: ClickZoneAction.nextPage,
              clickMR: ClickZoneAction.nextPage,
              clickBL: ClickZoneAction.nextPage,
              clickBC: ClickZoneAction.nextPage,
              clickBR: ClickZoneAction.nextPage,
            ),
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('下一页').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('上一页'));
    await tester.pumpAndSettle();

    expect(port.saved, isNotNull);
    expect(port.saved!.tl, ClickZoneAction.prevPage);
    expect(port.saved!.mc, ClickZoneAction.menu);
    expect(changed?.clickMC, ClickZoneAction.menu);
  });
}

final class _FakeClickActionPrefsPort implements ClickActionPrefsPort {
  ClickZoneLayout? saved;

  @override
  Future<ClickZoneLayout> load() async => const ClickZoneLayout(
    tl: ClickZoneAction.menu,
    tc: ClickZoneAction.menu,
    tr: ClickZoneAction.menu,
    ml: ClickZoneAction.menu,
    mc: ClickZoneAction.menu,
    mr: ClickZoneAction.menu,
    bl: ClickZoneAction.menu,
    bc: ClickZoneAction.menu,
    br: ClickZoneAction.menu,
  );

  @override
  Future<void> save(ClickZoneLayout layout) async {
    saved = layout;
  }

  @override
  Future<bool> isTipShown() async => false;

  @override
  Future<void> markTipShown() async {}
}
