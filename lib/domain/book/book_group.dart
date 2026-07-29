/// 书架分组领域实体，对齐 Legado `BookGroup` 的持久化字段。
class BookGroup {
  static const int idRoot = -100;
  static const int idAll = -1;
  static const int idLocal = -2;
  static const int idAudio = -3;
  static const int idNetNone = -4;
  static const int idLocalNone = -5;
  static const int idVideo = -6;
  static const int idError = -11;

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

  final int groupId;
  final String groupName;
  final String? cover;
  final int order;
  final bool enableRefresh;
  final bool show;
  final int bookSort;
  final bool onlyUpdateRead;

  bool get isSystem => groupId < 0;
  bool get isCustom => groupId > 0;
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
}
