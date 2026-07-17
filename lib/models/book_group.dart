/// 书架分组 — 对齐 Jingshiro [BookGroup]
class BookGroup {
  static const int idRoot = -100;
  static const int idAll = -1;
  static const int idLocal = -2;
  static const int idAudio = -3;
  static const int idNetNone = -4;
  static const int idLocalNone = -5;
  static const int idVideo = -6;
  static const int idError = -11;

  /// 排序文案（对齐 `@array/book_sort`，index = bookSort + 1）
  static const sortLabels = <String>[
    '默认',
    '按阅读时间',
    '按更新时间',
    '按书名',
    '手动排序',
    '综合排序',
    '按作者',
  ];

  final int groupId;
  final String groupName;
  final String? cover;
  final int order;
  final bool enableRefresh;
  final bool show;
  final int bookSort;
  final bool onlyUpdateRead;

  const BookGroup({
    required this.groupId,
    required this.groupName,
    this.cover,
    this.order = 0,
    this.enableRefresh = true,
    this.show = true,
    this.bookSort = -1,
    this.onlyUpdateRead = false,
  });

  bool get isSystem => groupId < 0;
  bool get isCustom => groupId > 0;

  /// 管理列表显示名 — 对齐 [BookGroup.getManageName]
  String get manageName {
    switch (groupId) {
      case idAll:
        return '$groupName(全部)';
      case idLocal:
        return '$groupName(本地)';
      case idAudio:
        return '$groupName(音频)';
      case idNetNone:
        return '$groupName(网络未分组)';
      case idLocalNone:
        return '$groupName(本地未分组)';
      case idVideo:
        return '$groupName(视频)';
      case idError:
        return '$groupName(更新失败)';
      default:
        return groupName;
    }
  }

  int get realBookSort => bookSort < 0 ? -1 : bookSort;

  BookGroup copyWith({
    int? groupId,
    String? groupName,
    String? cover,
    bool clearCover = false,
    int? order,
    bool? enableRefresh,
    bool? show,
    int? bookSort,
    bool? onlyUpdateRead,
  }) {
    return BookGroup(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      cover: clearCover ? null : (cover ?? this.cover),
      order: order ?? this.order,
      enableRefresh: enableRefresh ?? this.enableRefresh,
      show: show ?? this.show,
      bookSort: bookSort ?? this.bookSort,
      onlyUpdateRead: onlyUpdateRead ?? this.onlyUpdateRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'groupName': groupName,
        'cover': cover,
        'order': order,
        'enableRefresh': enableRefresh,
        'show': show,
        'bookSort': bookSort,
        'onlyUpdateRead': onlyUpdateRead,
      };

  factory BookGroup.fromJson(Map<String, dynamic> json) => BookGroup(
        groupId: (json['groupId'] as num?)?.toInt() ?? 0,
        groupName: json['groupName'] as String? ?? '',
        cover: json['cover'] as String?,
        order: (json['order'] as num?)?.toInt() ?? 0,
        enableRefresh: json['enableRefresh'] as bool? ?? true,
        show: json['show'] as bool? ?? true,
        bookSort: (json['bookSort'] as num?)?.toInt() ?? -1,
        onlyUpdateRead: json['onlyUpdateRead'] as bool? ?? false,
      );

  /// 对齐 AppDatabase 迁移插入的系统分组
  static List<BookGroup> defaultSystemGroups() => const [
        BookGroup(groupId: idAll, groupName: '全部', order: -10, show: true),
        BookGroup(
          groupId: idLocal,
          groupName: '本地',
          order: -9,
          enableRefresh: false,
          show: true,
        ),
        BookGroup(groupId: idAudio, groupName: '音频', order: -8, show: true),
        BookGroup(
          groupId: idNetNone,
          groupName: '网络未分组',
          order: -7,
          show: true,
        ),
        BookGroup(
          groupId: idLocalNone,
          groupName: '本地未分组',
          order: -6,
          show: false,
        ),
        BookGroup(groupId: idVideo, groupName: '视频', order: -5, show: true),
        BookGroup(groupId: idError, groupName: '更新失败', order: -1, show: true),
      ];
}
