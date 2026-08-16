import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/reader_config/click_zone.dart';

void main() {
  group('ClickZoneAction', () {
    test('preserves legacy codes and fallback behavior', () {
      expect(ClickZoneAction.none.code, -1);
      expect(ClickZoneAction.menu.code, 0);
      expect(ClickZoneAction.aloudPauseResume.code, 13);
      expect(
        ClickZoneAction.fromCode(ClickZoneAction.nextChapter.code),
        ClickZoneAction.nextChapter,
      );
      expect(ClickZoneAction.fromCode(999), ClickZoneAction.menu);
    });

    test('keeps selector order aligned with enum values', () {
      expect(ClickZoneAction.selectorOrder, ClickZoneAction.values);
    });
  });

  group('ClickZoneLayout', () {
    test('keeps all nine grid fields and detects menu actions', () {
      const layout = ClickZoneLayout(
        tl: ClickZoneAction.none,
        tc: ClickZoneAction.nextPage,
        tr: ClickZoneAction.prevPage,
        ml: ClickZoneAction.nextChapter,
        mc: ClickZoneAction.menu,
        mr: ClickZoneAction.prevChapter,
        bl: ClickZoneAction.addBookmark,
        bc: ClickZoneAction.editContent,
        br: ClickZoneAction.syncProgress,
      );

      expect(layout.tl, ClickZoneAction.none);
      expect(layout.tc, ClickZoneAction.nextPage);
      expect(layout.tr, ClickZoneAction.prevPage);
      expect(layout.ml, ClickZoneAction.nextChapter);
      expect(layout.mc, ClickZoneAction.menu);
      expect(layout.mr, ClickZoneAction.prevChapter);
      expect(layout.bl, ClickZoneAction.addBookmark);
      expect(layout.bc, ClickZoneAction.editContent);
      expect(layout.br, ClickZoneAction.syncProgress);
      expect(layout.hasMenu, isTrue);
    });

    test('provides immutable value equality and copyWith updates', () {
      const layout = ClickZoneLayout(
        tl: ClickZoneAction.none,
        tc: ClickZoneAction.none,
        tr: ClickZoneAction.none,
        ml: ClickZoneAction.none,
        mc: ClickZoneAction.none,
        mr: ClickZoneAction.none,
        bl: ClickZoneAction.none,
        bc: ClickZoneAction.none,
        br: ClickZoneAction.none,
      );

      expect(layout, layout.copyWith());
      expect(layout.copyWith(mc: ClickZoneAction.menu).hasMenu, isTrue);
      expect(layout.hasMenu, isFalse);
      expect(
        layout,
        const ClickZoneLayout(
          tl: ClickZoneAction.none,
          tc: ClickZoneAction.none,
          tr: ClickZoneAction.none,
          ml: ClickZoneAction.none,
          mc: ClickZoneAction.none,
          mr: ClickZoneAction.none,
          bl: ClickZoneAction.none,
          bc: ClickZoneAction.none,
          br: ClickZoneAction.none,
        ),
      );
    });
  });
}
