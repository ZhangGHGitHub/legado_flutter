import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_group.freezed.dart';
part 'book_group.g.dart';

/// 书架分组领域实体，对齐 Legado `BookGroup` 的持久化字段。
@Freezed(copyWith: false)
class BookGroup with _$BookGroup {
  const BookGroup._();

  static const int idRoot = -100;
  static const int idAll = -1;
  static const int idLocal = -2;
  static const int idAudio = -3;
  static const int idNetNone = -4;
  static const int idLocalNone = -5;
  static const int idVideo = -6;
  static const int idError = -11;

  const factory BookGroup({
    @Default(0) int groupId,
    @Default('') String groupName,
    String? cover,
    @Default(0) int order,
    @Default(true) bool enableRefresh,
    @Default(true) bool show,
    @Default(-1) int bookSort,
    @Default(false) bool onlyUpdateRead,
  }) = _BookGroup;

  factory BookGroup.fromJson(Map<String, dynamic> json) =>
      _$BookGroupFromJson(json);

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
}
