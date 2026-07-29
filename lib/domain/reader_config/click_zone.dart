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
class ClickZoneLayout {
  const ClickZoneLayout({
    required this.tl,
    required this.tc,
    required this.tr,
    required this.ml,
    required this.mc,
    required this.mr,
    required this.bl,
    required this.bc,
    required this.br,
  });

  final ClickZoneAction tl;
  final ClickZoneAction tc;
  final ClickZoneAction tr;
  final ClickZoneAction ml;
  final ClickZoneAction mc;
  final ClickZoneAction mr;
  final ClickZoneAction bl;
  final ClickZoneAction bc;
  final ClickZoneAction br;

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

  ClickZoneLayout copyWith({
    ClickZoneAction? tl,
    ClickZoneAction? tc,
    ClickZoneAction? tr,
    ClickZoneAction? ml,
    ClickZoneAction? mc,
    ClickZoneAction? mr,
    ClickZoneAction? bl,
    ClickZoneAction? bc,
    ClickZoneAction? br,
  }) {
    return ClickZoneLayout(
      tl: tl ?? this.tl,
      tc: tc ?? this.tc,
      tr: tr ?? this.tr,
      ml: ml ?? this.ml,
      mc: mc ?? this.mc,
      mr: mr ?? this.mr,
      bl: bl ?? this.bl,
      bc: bc ?? this.bc,
      br: br ?? this.br,
    );
  }
}
