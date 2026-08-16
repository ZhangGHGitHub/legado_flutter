import 'package:freezed_annotation/freezed_annotation.dart';

part 'click_zone.freezed.dart';

/// 点击区行为。
///
/// [code] 与 legado AppConfig 存值一致：-1 无操作，0 菜单，1 下一页……
enum ClickZoneAction {
  none(-1),
  menu(0),
  nextPage(1),
  prevPage(2),
  nextChapter(3),
  prevChapter(4),
  aloudPrevParagraph(5),
  aloudNextParagraph(6),
  addBookmark(7),
  editContent(8),
  replaceToggle(9),
  chapterList(10),
  searchContent(11),
  syncProgress(12),
  aloudPauseResume(13);

  const ClickZoneAction(this.code);

  final int code;

  static ClickZoneAction fromCode(int code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return menu;
  }

  static List<ClickZoneAction> get selectorOrder => values;
}

/// 九宫格点击区域布局快照。
@freezed
class ClickZoneLayout with _$ClickZoneLayout {
  const ClickZoneLayout._();

  const factory ClickZoneLayout({
    required ClickZoneAction tl,
    required ClickZoneAction tc,
    required ClickZoneAction tr,
    required ClickZoneAction ml,
    required ClickZoneAction mc,
    required ClickZoneAction mr,
    required ClickZoneAction bl,
    required ClickZoneAction bc,
    required ClickZoneAction br,
  }) = _ClickZoneLayout;

  bool get hasMenu =>
      tl == ClickZoneAction.menu ||
      tc == ClickZoneAction.menu ||
      tr == ClickZoneAction.menu ||
      ml == ClickZoneAction.menu ||
      mc == ClickZoneAction.menu ||
      mr == ClickZoneAction.menu ||
      bl == ClickZoneAction.menu ||
      bc == ClickZoneAction.menu ||
      br == ClickZoneAction.menu;
}
