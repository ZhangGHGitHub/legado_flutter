// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_result_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SearchResultItem _$SearchResultItemFromJson(Map<String, dynamic> json) {
  return _SearchResultItem.fromJson(json);
}

/// @nodoc
mixin _$SearchResultItem {
  String get name => throw _privateConstructorUsedError;
  String get author => throw _privateConstructorUsedError;
  String get bookUrl => throw _privateConstructorUsedError;
  String get coverUrl => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  String get note => throw _privateConstructorUsedError;

  /// Serializes this SearchResultItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchResultItemCopyWith<SearchResultItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchResultItemCopyWith<$Res> {
  factory $SearchResultItemCopyWith(
    SearchResultItem value,
    $Res Function(SearchResultItem) then,
  ) = _$SearchResultItemCopyWithImpl<$Res, SearchResultItem>;
  @useResult
  $Res call({
    String name,
    String author,
    String bookUrl,
    String coverUrl,
    String kind,
    String note,
  });
}

/// @nodoc
class _$SearchResultItemCopyWithImpl<$Res, $Val extends SearchResultItem>
    implements $SearchResultItemCopyWith<$Res> {
  _$SearchResultItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? author = null,
    Object? bookUrl = null,
    Object? coverUrl = null,
    Object? kind = null,
    Object? note = null,
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
            bookUrl: null == bookUrl
                ? _value.bookUrl
                : bookUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            coverUrl: null == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as String,
            note: null == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SearchResultItemImplCopyWith<$Res>
    implements $SearchResultItemCopyWith<$Res> {
  factory _$$SearchResultItemImplCopyWith(
    _$SearchResultItemImpl value,
    $Res Function(_$SearchResultItemImpl) then,
  ) = __$$SearchResultItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String author,
    String bookUrl,
    String coverUrl,
    String kind,
    String note,
  });
}

/// @nodoc
class __$$SearchResultItemImplCopyWithImpl<$Res>
    extends _$SearchResultItemCopyWithImpl<$Res, _$SearchResultItemImpl>
    implements _$$SearchResultItemImplCopyWith<$Res> {
  __$$SearchResultItemImplCopyWithImpl(
    _$SearchResultItemImpl _value,
    $Res Function(_$SearchResultItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? author = null,
    Object? bookUrl = null,
    Object? coverUrl = null,
    Object? kind = null,
    Object? note = null,
  }) {
    return _then(
      _$SearchResultItemImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        author: null == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as String,
        bookUrl: null == bookUrl
            ? _value.bookUrl
            : bookUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        coverUrl: null == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
        note: null == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchResultItemImpl extends _SearchResultItem {
  const _$SearchResultItemImpl({
    required this.name,
    required this.author,
    required this.bookUrl,
    this.coverUrl = '',
    this.kind = '',
    this.note = '',
  }) : super._();

  factory _$SearchResultItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchResultItemImplFromJson(json);

  @override
  final String name;
  @override
  final String author;
  @override
  final String bookUrl;
  @override
  @JsonKey()
  final String coverUrl;
  @override
  @JsonKey()
  final String kind;
  @override
  @JsonKey()
  final String note;

  @override
  String toString() {
    return 'SearchResultItem(name: $name, author: $author, bookUrl: $bookUrl, coverUrl: $coverUrl, kind: $kind, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchResultItemImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.bookUrl, bookUrl) || other.bookUrl == bookUrl) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, author, bookUrl, coverUrl, kind, note);

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchResultItemImplCopyWith<_$SearchResultItemImpl> get copyWith =>
      __$$SearchResultItemImplCopyWithImpl<_$SearchResultItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchResultItemImplToJson(this);
  }
}

abstract class _SearchResultItem extends SearchResultItem {
  const factory _SearchResultItem({
    required final String name,
    required final String author,
    required final String bookUrl,
    final String coverUrl,
    final String kind,
    final String note,
  }) = _$SearchResultItemImpl;
  const _SearchResultItem._() : super._();

  factory _SearchResultItem.fromJson(Map<String, dynamic> json) =
      _$SearchResultItemImpl.fromJson;

  @override
  String get name;
  @override
  String get author;
  @override
  String get bookUrl;
  @override
  String get coverUrl;
  @override
  String get kind;
  @override
  String get note;

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchResultItemImplCopyWith<_$SearchResultItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
