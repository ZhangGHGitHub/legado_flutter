import '../../domain/reader_config/click_zone.dart';

extension ClickZoneActionLabel on ClickZoneAction {
  String get label => switch (this) {
    ClickZoneAction.none => '无操作',
    ClickZoneAction.menu => '菜单',
    ClickZoneAction.nextPage => '下一页',
    ClickZoneAction.prevPage => '上一页',
    ClickZoneAction.nextChapter => '下一章',
    ClickZoneAction.prevChapter => '上一章',
    ClickZoneAction.aloudPrevParagraph => '朗读上一段',
    ClickZoneAction.aloudNextParagraph => '朗读下一段',
    ClickZoneAction.addBookmark => '添加书签',
    ClickZoneAction.editContent => '编辑内容',
    ClickZoneAction.replaceToggle => '替换(启用/禁用)',
    ClickZoneAction.chapterList => '目录',
    ClickZoneAction.searchContent => '全文搜索',
    ClickZoneAction.syncProgress => '同步阅读进度',
    ClickZoneAction.aloudPauseResume => '朗读暂停/继续',
  };
}
