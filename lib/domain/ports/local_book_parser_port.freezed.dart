// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_book_parser_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LocalBookChapterSnapshot {
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;

  /// Create a copy of LocalBookChapterSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocalBookChapterSnapshotCopyWith<LocalBookChapterSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocalBookChapterSnapshotCopyWith<$Res> {
  factory $LocalBookChapterSnapshotCopyWith(
    LocalBookChapterSnapshot value,
    $Res Function(LocalBookChapterSnapshot) then,
  ) = _$LocalBookChapterSnapshotCopyWithImpl<$Res, LocalBookChapterSnapshot>;
  @useResult
  $Res call({String title, String content});
}

/// @nodoc
class _$LocalBookChapterSnapshotCopyWithImpl<
  $Res,
  $Val extends LocalBookChapterSnapshot
>
    implements $LocalBookChapterSnapshotCopyWith<$Res> {
  _$LocalBookChapterSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocalBookChapterSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? title = null, Object? content = null}) {
    return _then(
      _value.copyWith(
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LocalBookChapterSnapshotImplCopyWith<$Res>
    implements $LocalBookChapterSnapshotCopyWith<$Res> {
  factory _$$LocalBookChapterSnapshotImplCopyWith(
    _$LocalBookChapterSnapshotImpl value,
    $Res Function(_$LocalBookChapterSnapshotImpl) then,
  ) = __$$LocalBookChapterSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String title, String content});
}

/// @nodoc
class __$$LocalBookChapterSnapshotImplCopyWithImpl<$Res>
    extends
        _$LocalBookChapterSnapshotCopyWithImpl<
          $Res,
          _$LocalBookChapterSnapshotImpl
        >
    implements _$$LocalBookChapterSnapshotImplCopyWith<$Res> {
  __$$LocalBookChapterSnapshotImplCopyWithImpl(
    _$LocalBookChapterSnapshotImpl _value,
    $Res Function(_$LocalBookChapterSnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocalBookChapterSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? title = null, Object? content = null}) {
    return _then(
      _$LocalBookChapterSnapshotImpl(
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$LocalBookChapterSnapshotImpl implements _LocalBookChapterSnapshot {
  const _$LocalBookChapterSnapshotImpl({
    required this.title,
    required this.content,
  });

  @override
  final String title;
  @override
  final String content;

  @override
  String toString() {
    return 'LocalBookChapterSnapshot(title: $title, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalBookChapterSnapshotImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content));
  }

  @override
  int get hashCode => Object.hash(runtimeType, title, content);

  /// Create a copy of LocalBookChapterSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocalBookChapterSnapshotImplCopyWith<_$LocalBookChapterSnapshotImpl>
  get copyWith =>
      __$$LocalBookChapterSnapshotImplCopyWithImpl<
        _$LocalBookChapterSnapshotImpl
      >(this, _$identity);
}

abstract class _LocalBookChapterSnapshot implements LocalBookChapterSnapshot {
  const factory _LocalBookChapterSnapshot({
    required final String title,
    required final String content,
  }) = _$LocalBookChapterSnapshotImpl;

  @override
  String get title;
  @override
  String get content;

  /// Create a copy of LocalBookChapterSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocalBookChapterSnapshotImplCopyWith<_$LocalBookChapterSnapshotImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$LocalBookEpubSnapshot {
  String get title => throw _privateConstructorUsedError;
  String get author => throw _privateConstructorUsedError;
  List<LocalBookChapterSnapshot> get chapters =>
      throw _privateConstructorUsedError;

  /// Create a copy of LocalBookEpubSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocalBookEpubSnapshotCopyWith<LocalBookEpubSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocalBookEpubSnapshotCopyWith<$Res> {
  factory $LocalBookEpubSnapshotCopyWith(
    LocalBookEpubSnapshot value,
    $Res Function(LocalBookEpubSnapshot) then,
  ) = _$LocalBookEpubSnapshotCopyWithImpl<$Res, LocalBookEpubSnapshot>;
  @useResult
  $Res call({
    String title,
    String author,
    List<LocalBookChapterSnapshot> chapters,
  });
}

/// @nodoc
class _$LocalBookEpubSnapshotCopyWithImpl<
  $Res,
  $Val extends LocalBookEpubSnapshot
>
    implements $LocalBookEpubSnapshotCopyWith<$Res> {
  _$LocalBookEpubSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocalBookEpubSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? author = null,
    Object? chapters = null,
  }) {
    return _then(
      _value.copyWith(
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            author: null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as String,
            chapters: null == chapters
                ? _value.chapters
                : chapters // ignore: cast_nullable_to_non_nullable
                      as List<LocalBookChapterSnapshot>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LocalBookEpubSnapshotImplCopyWith<$Res>
    implements $LocalBookEpubSnapshotCopyWith<$Res> {
  factory _$$LocalBookEpubSnapshotImplCopyWith(
    _$LocalBookEpubSnapshotImpl value,
    $Res Function(_$LocalBookEpubSnapshotImpl) then,
  ) = __$$LocalBookEpubSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String title,
    String author,
    List<LocalBookChapterSnapshot> chapters,
  });
}

/// @nodoc
class __$$LocalBookEpubSnapshotImplCopyWithImpl<$Res>
    extends
        _$LocalBookEpubSnapshotCopyWithImpl<$Res, _$LocalBookEpubSnapshotImpl>
    implements _$$LocalBookEpubSnapshotImplCopyWith<$Res> {
  __$$LocalBookEpubSnapshotImplCopyWithImpl(
    _$LocalBookEpubSnapshotImpl _value,
    $Res Function(_$LocalBookEpubSnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocalBookEpubSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? author = null,
    Object? chapters = null,
  }) {
    return _then(
      _$LocalBookEpubSnapshotImpl(
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        author: null == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as String,
        chapters: null == chapters
            ? _value._chapters
            : chapters // ignore: cast_nullable_to_non_nullable
                  as List<LocalBookChapterSnapshot>,
      ),
    );
  }
}

/// @nodoc

class _$LocalBookEpubSnapshotImpl implements _LocalBookEpubSnapshot {
  const _$LocalBookEpubSnapshotImpl({
    required this.title,
    required this.author,
    required final List<LocalBookChapterSnapshot> chapters,
  }) : _chapters = chapters;

  @override
  final String title;
  @override
  final String author;
  final List<LocalBookChapterSnapshot> _chapters;
  @override
  List<LocalBookChapterSnapshot> get chapters {
    if (_chapters is EqualUnmodifiableListView) return _chapters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chapters);
  }

  @override
  String toString() {
    return 'LocalBookEpubSnapshot(title: $title, author: $author, chapters: $chapters)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalBookEpubSnapshotImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            const DeepCollectionEquality().equals(other._chapters, _chapters));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    author,
    const DeepCollectionEquality().hash(_chapters),
  );

  /// Create a copy of LocalBookEpubSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocalBookEpubSnapshotImplCopyWith<_$LocalBookEpubSnapshotImpl>
  get copyWith =>
      __$$LocalBookEpubSnapshotImplCopyWithImpl<_$LocalBookEpubSnapshotImpl>(
        this,
        _$identity,
      );
}

abstract class _LocalBookEpubSnapshot implements LocalBookEpubSnapshot {
  const factory _LocalBookEpubSnapshot({
    required final String title,
    required final String author,
    required final List<LocalBookChapterSnapshot> chapters,
  }) = _$LocalBookEpubSnapshotImpl;

  @override
  String get title;
  @override
  String get author;
  @override
  List<LocalBookChapterSnapshot> get chapters;

  /// Create a copy of LocalBookEpubSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocalBookEpubSnapshotImplCopyWith<_$LocalBookEpubSnapshotImpl>
  get copyWith => throw _privateConstructorUsedError;
}
