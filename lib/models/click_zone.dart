/// 点击区行为（对齐 ClickActionConfigDialog / ReadView.click）
/// [code] 与 legado AppConfig 存值一致：-1 无操作，0 菜单，1 下一页…
enum ClickZoneAction {
  none(-1, '无操作'),
  menu(0, '菜单'),
  nextPage(1, '下一页'),
  prevPage(2, '上一页'),
  nextChapter(3, '下一章'),
  prevChapter(4, '上一章'),
  aloudPrevParagraph(5, '朗读上一段'),
  aloudNextParagraph(6, '朗读下一段'),
  addBookmark(7, '添加书签'),
  editContent(8, '编辑内容'),
  replaceToggle(9, '替换(启用/禁用)'),
  chapterList(10, '目录'),
  searchContent(11, '全文搜索'),
  syncProgress(12, '同步阅读进度'),
  aloudPauseResume(13, '朗读暂停/继续');

  const ClickZoneAction(this.code, this.label);
  final int code;
  final String label;

  static ClickZoneAction fromCode(int code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return menu;
  }

  /// 选择器顺序（对齐 dialog 中 linkedMapOf）
  static List<ClickZoneAction> get selectorOrder => values;
}

/// 九宫格布局快照
class ClickZoneLayout {
  final ClickZoneAction tl;
  final ClickZoneAction tc;
  final ClickZoneAction tr;
  final ClickZoneAction ml;
  final ClickZoneAction mc;
  final ClickZoneAction mr;
  final ClickZoneAction bl;
  final ClickZoneAction bc;
  final ClickZoneAction br;

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
