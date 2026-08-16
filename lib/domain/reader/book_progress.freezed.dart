// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BookProgress {
  String get name => throw _privateConstructorUsedError;
  String get author => throw _privateConstructorUsedError;
  int get durChapterIndex => throw _privateConstructorUsedError;

  /// UTF-16 章内位置，与原版和阅读位置迁移契约一致。
  int get durChapterPos => throw _privateConstructorUsedError;
  int get durChapterTime => throw _privateConstructorUsedError;
  String? get durChapterTitle => throw _privateConstructorUsedError;

  /// Create a copy of BookProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookProgressCopyWith<BookProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookProgressCopyWith<$Res> {
  factory $BookProgressCopyWith(
    BookProgress value,
    $Res Function(BookProgress) then,
  ) = _$BookProgressCopyWithImpl<$Res, BookProgress>;
  @useResult
  $Res call({
    String name,
    String author,
    int durChapterIndex,
    int durChapterPos,
    int durChapterTime,
    String? durChapterTitle,
  });
}

/// @nodoc
class _$BookProgressCopyWithImpl<$Res, $Val extends BookProgress>
    implements $BookProgressCopyWith<$Res> {
  _$BookProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? author = null,
    Object? durChapterIndex = null,
    Object? durChapterPos = null,
    Object? durChapterTime = null,
    Object? durChapterTitle = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            author: null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as String,
            durChapterIndex: null == durChapterIndex
                ? _value.durChapterIndex
                : durChapterIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            durChapterPos: null == durChapterPos
                ? _value.durChapterPos
                : durChapterPos // ignore: cast_nullable_to_non_nullable
                      as int,
            durChapterTime: null == durChapterTime
                ? _value.durChapterTime
                : durChapterTime // ignore: cast_nullable_to_non_nullable
                      as int,
            durChapterTitle: freezed == durChapterTitle
                ? _value.durChapterTitle
                : durChapterTitle // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookProgressImplCopyWith<$Res>
    implements $BookProgressCopyWith<$Res> {
  factory _$$BookProgressImplCopyWith(
    _$BookProgressImpl value,
    $Res Function(_$BookProgressImpl) then,
  ) = __$$BookProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String author,
    int durChapterIndex,
    int durChapterPos,
    int durChapterTime,
    String? durChapterTitle,
  });
}

/// @nodoc
class __$$BookProgressImplCopyWithImpl<$Res>
    extends _$BookProgressCopyWithImpl<$Res, _$BookProgressImpl>
    implements _$$BookProgressImplCopyWith<$Res> {
  __$$BookProgressImplCopyWithImpl(
    _$BookProgressImpl _value,
    $Res Function(_$BookProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? author = null,
    Object? durChapterIndex = null,
    Object? durChapterPos = null,
    Object? durChapterTime = null,
    Object? durChapterTitle = freezed,
  }) {
    return _then(
      _$BookProgressImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        author: null == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as String,
        durChapterIndex: null == durChapterIndex
            ? _value.durChapterIndex
            : durChapterIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        durChapterPos: null == durChapterPos
            ? _value.durChapterPos
            : durChapterPos // ignore: cast_nullable_to_non_nullable
                  as int,
        durChapterTime: null == durChapterTime
            ? _value.durChapterTime
            : durChapterTime // ignore: cast_nullable_to_non_nullable
                  as int,
        durChapterTitle: freezed == durChapterTitle
            ? _value.durChapterTitle
            : durChapterTitle // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$BookProgressImpl extends _BookProgress {
  const _$BookProgressImpl({
    required this.name,
    required this.author,
    required this.durChapterIndex,
    required this.durChapterPos,
    required this.durChapterTime,
    this.durChapterTitle,
  }) : super._();

  @override
  final String name;
  @override
  final String author;
  @override
  final int durChapterIndex;

  /// UTF-16 章内位置，与原版和阅读位置迁移契约一致。
  @override
  final int durChapterPos;
  @override
  final int durChapterTime;
  @override
  final String? durChapterTitle;

  @override
  String toString() {
    return 'BookProgress(name: $name, author: $author, durChapterIndex: $durChapterIndex, durChapterPos: $durChapterPos, durChapterTime: $durChapterTime, durChapterTitle: $durChapterTitle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookProgressImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.durChapterIndex, durChapterIndex) ||
                other.durChapterIndex == durChapterIndex) &&
            (identical(other.durChapterPos, durChapterPos) ||
                other.durChapterPos == durChapterPos) &&
            (identical(other.durChapterTime, durChapterTime) ||
                other.durChapterTime == durChapterTime) &&
            (identical(other.durChapterTitle, durChapterTitle) ||
                other.durChapterTitle == durChapterTitle));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    author,
    durChapterIndex,
    durChapterPos,
    durChapterTime,
    durChapterTitle,
  );

  /// Create a copy of BookProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookProgressImplCopyWith<_$BookProgressImpl> get copyWith =>
      __$$BookProgressImplCopyWithImpl<_$BookProgressImpl>(this, _$identity);
}

abstract class _BookProgress extends BookProgress {
  const factory _BookProgress({
    required final String name,
    required final String author,
    required final int durChapterIndex,
    required final int durChapterPos,
    required final int durChapterTime,
    final String? durChapterTitle,
  }) = _$BookProgressImpl;
  const _BookProgress._() : super._();

  @override
  String get name;
  @override
  String get author;
  @override
  int get durChapterIndex;

  /// UTF-16 章内位置，与原版和阅读位置迁移契约一致。
  @override
  int get durChapterPos;
  @override
  int get durChapterTime;
  @override
  String? get durChapterTitle;

  /// Create a copy of BookProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookProgressImplCopyWith<_$BookProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
