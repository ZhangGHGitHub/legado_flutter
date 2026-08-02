// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rule_sub_import_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RuleSubImportResult {
  RuleSubImportKind get kind => throw _privateConstructorUsedError;
  List<BookSource> get bookSources => throw _privateConstructorUsedError;
  List<RssSource> get rssSources => throw _privateConstructorUsedError;
  List<ReplaceRule> get replaceRules => throw _privateConstructorUsedError;

  /// Create a copy of RuleSubImportResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RuleSubImportResultCopyWith<RuleSubImportResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RuleSubImportResultCopyWith<$Res> {
  factory $RuleSubImportResultCopyWith(
    RuleSubImportResult value,
    $Res Function(RuleSubImportResult) then,
  ) = _$RuleSubImportResultCopyWithImpl<$Res, RuleSubImportResult>;
  @useResult
  $Res call({
    RuleSubImportKind kind,
    List<BookSource> bookSources,
    List<RssSource> rssSources,
    List<ReplaceRule> replaceRules,
  });
}

/// @nodoc
class _$RuleSubImportResultCopyWithImpl<$Res, $Val extends RuleSubImportResult>
    implements $RuleSubImportResultCopyWith<$Res> {
  _$RuleSubImportResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RuleSubImportResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? bookSources = null,
    Object? rssSources = null,
    Object? replaceRules = null,
  }) {
    return _then(
      _value.copyWith(
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as RuleSubImportKind,
            bookSources: null == bookSources
                ? _value.bookSources
                : bookSources // ignore: cast_nullable_to_non_nullable
                      as List<BookSource>,
            rssSources: null == rssSources
                ? _value.rssSources
                : rssSources // ignore: cast_nullable_to_non_nullable
                      as List<RssSource>,
            replaceRules: null == replaceRules
                ? _value.replaceRules
                : replaceRules // ignore: cast_nullable_to_non_nullable
                      as List<ReplaceRule>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RuleSubImportResultImplCopyWith<$Res>
    implements $RuleSubImportResultCopyWith<$Res> {
  factory _$$RuleSubImportResultImplCopyWith(
    _$RuleSubImportResultImpl value,
    $Res Function(_$RuleSubImportResultImpl) then,
  ) = __$$RuleSubImportResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    RuleSubImportKind kind,
    List<BookSource> bookSources,
    List<RssSource> rssSources,
    List<ReplaceRule> replaceRules,
  });
}

/// @nodoc
class __$$RuleSubImportResultImplCopyWithImpl<$Res>
    extends _$RuleSubImportResultCopyWithImpl<$Res, _$RuleSubImportResultImpl>
    implements _$$RuleSubImportResultImplCopyWith<$Res> {
  __$$RuleSubImportResultImplCopyWithImpl(
    _$RuleSubImportResultImpl _value,
    $Res Function(_$RuleSubImportResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RuleSubImportResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? bookSources = null,
    Object? rssSources = null,
    Object? replaceRules = null,
  }) {
    return _then(
      _$RuleSubImportResultImpl(
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as RuleSubImportKind,
        bookSources: null == bookSources
            ? _value._bookSources
            : bookSources // ignore: cast_nullable_to_non_nullable
                  as List<BookSource>,
        rssSources: null == rssSources
            ? _value._rssSources
            : rssSources // ignore: cast_nullable_to_non_nullable
                  as List<RssSource>,
        replaceRules: null == replaceRules
            ? _value._replaceRules
            : replaceRules // ignore: cast_nullable_to_non_nullable
                  as List<ReplaceRule>,
      ),
    );
  }
}

/// @nodoc

class _$RuleSubImportResultImpl extends _RuleSubImportResult {
  const _$RuleSubImportResultImpl({
    required this.kind,
    final List<BookSource> bookSources = const <BookSource>[],
    final List<RssSource> rssSources = const <RssSource>[],
    final List<ReplaceRule> replaceRules = const <ReplaceRule>[],
  }) : _bookSources = bookSources,
       _rssSources = rssSources,
       _replaceRules = replaceRules,
       super._();

  @override
  final RuleSubImportKind kind;
  final List<BookSource> _bookSources;
  @override
  @JsonKey()
  List<BookSource> get bookSources {
    if (_bookSources is EqualUnmodifiableListView) return _bookSources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookSources);
  }

  final List<RssSource> _rssSources;
  @override
  @JsonKey()
  List<RssSource> get rssSources {
    if (_rssSources is EqualUnmodifiableListView) return _rssSources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rssSources);
  }

  final List<ReplaceRule> _replaceRules;
  @override
  @JsonKey()
  List<ReplaceRule> get replaceRules {
    if (_replaceRules is EqualUnmodifiableListView) return _replaceRules;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_replaceRules);
  }

  @override
  String toString() {
    return 'RuleSubImportResult._value(kind: $kind, bookSources: $bookSources, rssSources: $rssSources, replaceRules: $replaceRules)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RuleSubImportResultImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            const DeepCollectionEquality().equals(
              other._bookSources,
              _bookSources,
            ) &&
            const DeepCollectionEquality().equals(
              other._rssSources,
              _rssSources,
            ) &&
            const DeepCollectionEquality().equals(
              other._replaceRules,
              _replaceRules,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    kind,
    const DeepCollectionEquality().hash(_bookSources),
    const DeepCollectionEquality().hash(_rssSources),
    const DeepCollectionEquality().hash(_replaceRules),
  );

  /// Create a copy of RuleSubImportResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RuleSubImportResultImplCopyWith<_$RuleSubImportResultImpl> get copyWith =>
      __$$RuleSubImportResultImplCopyWithImpl<_$RuleSubImportResultImpl>(
        this,
        _$identity,
      );
}

abstract class _RuleSubImportResult extends RuleSubImportResult {
  const factory _RuleSubImportResult({
    required final RuleSubImportKind kind,
    final List<BookSource> bookSources,
    final List<RssSource> rssSources,
    final List<ReplaceRule> replaceRules,
  }) = _$RuleSubImportResultImpl;
  const _RuleSubImportResult._() : super._();

  @override
  RuleSubImportKind get kind;
  @override
  List<BookSource> get bookSources;
  @override
  List<RssSource> get rssSources;
  @override
  List<ReplaceRule> get replaceRules;

  /// Create a copy of RuleSubImportResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RuleSubImportResultImplCopyWith<_$RuleSubImportResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
