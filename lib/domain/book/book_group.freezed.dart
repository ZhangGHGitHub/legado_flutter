// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BookGroup _$BookGroupFromJson(Map<String, dynamic> json) {
  return _BookGroup.fromJson(json);
}

/// @nodoc
mixin _$BookGroup {
  int get groupId => throw _privateConstructorUsedError;
  String get groupName => throw _privateConstructorUsedError;
  String? get cover => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  bool get enableRefresh => throw _privateConstructorUsedError;
  bool get show => throw _privateConstructorUsedError;
  int get bookSort => throw _privateConstructorUsedError;
  bool get onlyUpdateRead => throw _privateConstructorUsedError;

  /// Serializes this BookGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
@JsonSerializable()
class _$BookGroupImpl extends _BookGroup {
  const _$BookGroupImpl({
    this.groupId = 0,
    this.groupName = '',
    this.cover,
    this.order = 0,
    this.enableRefresh = true,
    this.show = true,
    this.bookSort = -1,
    this.onlyUpdateRead = false,
  }) : super._();

  factory _$BookGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookGroupImplFromJson(json);

  @override
  @JsonKey()
  final int groupId;
  @override
  @JsonKey()
  final String groupName;
  @override
  final String? cover;
  @override
  @JsonKey()
  final int order;
  @override
  @JsonKey()
  final bool enableRefresh;
  @override
  @JsonKey()
  final bool show;
  @override
  @JsonKey()
  final int bookSort;
  @override
  @JsonKey()
  final bool onlyUpdateRead;

  @override
  String toString() {
    return 'BookGroup(groupId: $groupId, groupName: $groupName, cover: $cover, order: $order, enableRefresh: $enableRefresh, show: $show, bookSort: $bookSort, onlyUpdateRead: $onlyUpdateRead)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookGroupImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.cover, cover) || other.cover == cover) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.enableRefresh, enableRefresh) ||
                other.enableRefresh == enableRefresh) &&
            (identical(other.show, show) || other.show == show) &&
            (identical(other.bookSort, bookSort) ||
                other.bookSort == bookSort) &&
            (identical(other.onlyUpdateRead, onlyUpdateRead) ||
                other.onlyUpdateRead == onlyUpdateRead));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    groupId,
    groupName,
    cover,
    order,
    enableRefresh,
    show,
    bookSort,
    onlyUpdateRead,
  );

  @override
  Map<String, dynamic> toJson() {
    return _$$BookGroupImplToJson(this);
  }
}

abstract class _BookGroup extends BookGroup {
  const factory _BookGroup({
    final int groupId,
    final String groupName,
    final String? cover,
    final int order,
    final bool enableRefresh,
    final bool show,
    final int bookSort,
    final bool onlyUpdateRead,
  }) = _$BookGroupImpl;
  const _BookGroup._() : super._();

  factory _BookGroup.fromJson(Map<String, dynamic> json) =
      _$BookGroupImpl.fromJson;

  @override
  int get groupId;
  @override
  String get groupName;
  @override
  String? get cover;
  @override
  int get order;
  @override
  bool get enableRefresh;
  @override
  bool get show;
  @override
  int get bookSort;
  @override
  bool get onlyUpdateRead;
}
