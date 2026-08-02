// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rss_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RssArticlesResult {
  List<RssArticle> get articles => throw _privateConstructorUsedError;
  String? get nextUrl => throw _privateConstructorUsedError;

  /// Create a copy of RssArticlesResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RssArticlesResultCopyWith<RssArticlesResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RssArticlesResultCopyWith<$Res> {
  factory $RssArticlesResultCopyWith(
    RssArticlesResult value,
    $Res Function(RssArticlesResult) then,
  ) = _$RssArticlesResultCopyWithImpl<$Res, RssArticlesResult>;
  @useResult
  $Res call({List<RssArticle> articles, String? nextUrl});
}

/// @nodoc
class _$RssArticlesResultCopyWithImpl<$Res, $Val extends RssArticlesResult>
    implements $RssArticlesResultCopyWith<$Res> {
  _$RssArticlesResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RssArticlesResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? articles = null, Object? nextUrl = freezed}) {
    return _then(
      _value.copyWith(
            articles: null == articles
                ? _value.articles
                : articles // ignore: cast_nullable_to_non_nullable
                      as List<RssArticle>,
            nextUrl: freezed == nextUrl
                ? _value.nextUrl
                : nextUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RssArticlesResultImplCopyWith<$Res>
    implements $RssArticlesResultCopyWith<$Res> {
  factory _$$RssArticlesResultImplCopyWith(
    _$RssArticlesResultImpl value,
    $Res Function(_$RssArticlesResultImpl) then,
  ) = __$$RssArticlesResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<RssArticle> articles, String? nextUrl});
}

/// @nodoc
class __$$RssArticlesResultImplCopyWithImpl<$Res>
    extends _$RssArticlesResultCopyWithImpl<$Res, _$RssArticlesResultImpl>
    implements _$$RssArticlesResultImplCopyWith<$Res> {
  __$$RssArticlesResultImplCopyWithImpl(
    _$RssArticlesResultImpl _value,
    $Res Function(_$RssArticlesResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RssArticlesResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? articles = null, Object? nextUrl = freezed}) {
    return _then(
      _$RssArticlesResultImpl(
        articles: null == articles
            ? _value._articles
            : articles // ignore: cast_nullable_to_non_nullable
                  as List<RssArticle>,
        nextUrl: freezed == nextUrl
            ? _value.nextUrl
            : nextUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$RssArticlesResultImpl implements _RssArticlesResult {
  const _$RssArticlesResultImpl({
    required final List<RssArticle> articles,
    this.nextUrl,
  }) : _articles = articles;

  final List<RssArticle> _articles;
  @override
  List<RssArticle> get articles {
    if (_articles is EqualUnmodifiableListView) return _articles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_articles);
  }

  @override
  final String? nextUrl;

  @override
  String toString() {
    return 'RssArticlesResult(articles: $articles, nextUrl: $nextUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RssArticlesResultImpl &&
            const DeepCollectionEquality().equals(other._articles, _articles) &&
            (identical(other.nextUrl, nextUrl) || other.nextUrl == nextUrl));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_articles),
    nextUrl,
  );

  /// Create a copy of RssArticlesResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RssArticlesResultImplCopyWith<_$RssArticlesResultImpl> get copyWith =>
      __$$RssArticlesResultImplCopyWithImpl<_$RssArticlesResultImpl>(
        this,
        _$identity,
      );
}

abstract class _RssArticlesResult implements RssArticlesResult {
  const factory _RssArticlesResult({
    required final List<RssArticle> articles,
    final String? nextUrl,
  }) = _$RssArticlesResultImpl;

  @override
  List<RssArticle> get articles;
  @override
  String? get nextUrl;

  /// Create a copy of RssArticlesResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RssArticlesResultImplCopyWith<_$RssArticlesResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
