import '../../domain/book/book_group.dart';

/// 书架分组的默认数据和中文展示策略。
abstract final class BookGroupPolicy {
  /// 对齐 `@array/book_sort`，index = bookSort + 1。
  static const sortLabels = <String>[
    '默认',
    '按阅读时间',
    '按更新时间',
    '按书名',
    '手动排序',
    '综合排序',
    '按作者',
  ];

  /// 对齐 AppDatabase 迁移插入的系统分组。
  static List<BookGroup> defaultSystemGroups() => const [
    BookGroup(groupId: BookGroup.idAll, groupName: '全部', order: -10),
    BookGroup(
      groupId: BookGroup.idLocal,
      groupName: '本地',
      order: -9,
      enableRefresh: false,
    ),
    BookGroup(groupId: BookGroup.idAudio, groupName: '音频', order: -8),
    BookGroup(groupId: BookGroup.idNetNone, groupName: '网络未分组', order: -7),
    BookGroup(
      groupId: BookGroup.idLocalNone,
      groupName: '本地未分组',
      order: -6,
      show: false,
    ),
    BookGroup(groupId: BookGroup.idVideo, groupName: '视频', order: -5),
    BookGroup(groupId: BookGroup.idError, groupName: '更新失败', order: -1),
  ];

  static String manageName(BookGroup group) {
    return switch (group.groupId) {
      BookGroup.idAll => '${group.groupName}(全部)',
      BookGroup.idLocal => '${group.groupName}(本地)',
      BookGroup.idAudio => '${group.groupName}(音频)',
      BookGroup.idNetNone => '${group.groupName}(网络未分组)',
      BookGroup.idLocalNone => '${group.groupName}(本地未分组)',
      BookGroup.idVideo => '${group.groupName}(视频)',
      BookGroup.idError => '${group.groupName}(更新失败)',
      _ => group.groupName,
    };
  }
}

extension BookGroupPresentation on BookGroup {
  String get manageName => BookGroupPolicy.manageName(this);
}
