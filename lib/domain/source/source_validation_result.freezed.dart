// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'source_validation_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BookSourceValidationSnapshot {
  bool get searchOk => throw _privateConstructorUsedError;
  bool get discoveryOk => throw _privateConstructorUsedError;
  bool get tocOk => throw _privateConstructorUsedError;
  bool get contentOk => throw _privateConstructorUsedError;
  int get searchTimeMs => throw _privateConstructorUsedError;
  List<String> get errors => throw _privateConstructorUsedError;

  /// Create a copy of BookSourceValidationSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookSourceValidationSnapshotCopyWith<BookSourceValidationSnapshot>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookSourceValidationSnapshotCopyWith<$Res> {
  factory $BookSourceValidationSnapshotCopyWith(
    BookSourceValidationSnapshot value,
    $Res Function(BookSourceValidationSnapshot) then,
  ) =
      _$BookSourceValidationSnapshotCopyWithImpl<
        $Res,
        BookSourceValidationSnapshot
      >;
  @useResult
  $Res call({
    bool searchOk,
    bool discoveryOk,
    bool tocOk,
    bool contentOk,
    int searchTimeMs,
    List<String> errors,
  });
}

/// @nodoc
class _$BookSourceValidationSnapshotCopyWithImpl<
  $Res,
  $Val extends BookSourceValidationSnapshot
>
    implements $BookSourceValidationSnapshotCopyWith<$Res> {
  _$BookSourceValidationSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookSourceValidationSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchOk = null,
    Object? discoveryOk = null,
    Object? tocOk = null,
    Object? contentOk = null,
    Object? searchTimeMs = null,
    Object? errors = null,
  }) {
    return _then(
      _value.copyWith(
            searchOk: null == searchOk
                ? _value.searchOk
                : searchOk // ignore: cast_nullable_to_non_nullable
                      as bool,
            discoveryOk: null == discoveryOk
                ? _value.discoveryOk
                : discoveryOk // ignore: cast_nullable_to_non_nullable
                      as bool,
            tocOk: null == tocOk
                ? _value.tocOk
                : tocOk // ignore: cast_nullable_to_non_nullable
                      as bool,
            contentOk: null == contentOk
                ? _value.contentOk
                : contentOk // ignore: cast_nullable_to_non_nullable
                      as bool,
            searchTimeMs: null == searchTimeMs
                ? _value.searchTimeMs
                : searchTimeMs // ignore: cast_nullable_to_non_nullable
                      as int,
            errors: null == errors
                ? _value.errors
                : errors // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookSourceValidationSnapshotImplCopyWith<$Res>
    implements $BookSourceValidationSnapshotCopyWith<$Res> {
  factory _$$BookSourceValidationSnapshotImplCopyWith(
    _$BookSourceValidationSnapshotImpl value,
    $Res Function(_$BookSourceValidationSnapshotImpl) then,
  ) = __$$BookSourceValidationSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool searchOk,
    bool discoveryOk,
    bool tocOk,
    bool contentOk,
    int searchTimeMs,
    List<String> errors,
  });
}

/// @nodoc
class __$$BookSourceValidationSnapshotImplCopyWithImpl<$Res>
    extends
        _$BookSourceValidationSnapshotCopyWithImpl<
          $Res,
          _$BookSourceValidationSnapshotImpl
        >
    implements _$$BookSourceValidationSnapshotImplCopyWith<$Res> {
  __$$BookSourceValidationSnapshotImplCopyWithImpl(
    _$BookSourceValidationSnapshotImpl _value,
    $Res Function(_$BookSourceValidationSnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookSourceValidationSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchOk = null,
    Object? discoveryOk = null,
    Object? tocOk = null,
    Object? contentOk = null,
    Object? searchTimeMs = null,
    Object? errors = null,
  }) {
    return _then(
      _$BookSourceValidationSnapshotImpl(
        searchOk: null == searchOk
            ? _value.searchOk
            : searchOk // ignore: cast_nullable_to_non_nullable
                  as bool,
        discoveryOk: null == discoveryOk
            ? _value.discoveryOk
            : discoveryOk // ignore: cast_nullable_to_non_nullable
                  as bool,
        tocOk: null == tocOk
            ? _value.tocOk
            : tocOk // ignore: cast_nullable_to_non_nullable
                  as bool,
        contentOk: null == contentOk
            ? _value.contentOk
            : contentOk // ignore: cast_nullable_to_non_nullable
                  as bool,
        searchTimeMs: null == searchTimeMs
            ? _value.searchTimeMs
            : searchTimeMs // ignore: cast_nullable_to_non_nullable
                  as int,
        errors: null == errors
            ? _value._errors
            : errors // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc

class _$BookSourceValidationSnapshotImpl extends _BookSourceValidationSnapshot {
  const _$BookSourceValidationSnapshotImpl({
    required this.searchOk,
    required this.discoveryOk,
    required this.tocOk,
    required this.contentOk,
    required this.searchTimeMs,
    final List<String> errors = const [],
  }) : _errors = errors,
       super._();

  @override
  final bool searchOk;
  @override
  final bool discoveryOk;
  @override
  final bool tocOk;
  @override
  final bool contentOk;
  @override
  final int searchTimeMs;
  final List<String> _errors;
  @override
  @JsonKey()
  List<String> get errors {
    if (_errors is EqualUnmodifiableListView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_errors);
  }

  @override
  String toString() {
    return 'BookSourceValidationSnapshot(searchOk: $searchOk, discoveryOk: $discoveryOk, tocOk: $tocOk, contentOk: $contentOk, searchTimeMs: $searchTimeMs, errors: $errors)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookSourceValidationSnapshotImpl &&
            (identical(other.searchOk, searchOk) ||
                other.searchOk == searchOk) &&
            (identical(other.discoveryOk, discoveryOk) ||
                other.discoveryOk == discoveryOk) &&
            (identical(other.tocOk, tocOk) || other.tocOk == tocOk) &&
            (identical(other.contentOk, contentOk) ||
                other.contentOk == contentOk) &&
            (identical(other.searchTimeMs, searchTimeMs) ||
                other.searchTimeMs == searchTimeMs) &&
            const DeepCollectionEquality().equals(other._errors, _errors));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    searchOk,
    discoveryOk,
    tocOk,
    contentOk,
    searchTimeMs,
    const DeepCollectionEquality().hash(_errors),
  );

  /// Create a copy of BookSourceValidationSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookSourceValidationSnapshotImplCopyWith<
    _$BookSourceValidationSnapshotImpl
  >
  get copyWith =>
      __$$BookSourceValidationSnapshotImplCopyWithImpl<
        _$BookSourceValidationSnapshotImpl
      >(this, _$identity);
}

abstract class _BookSourceValidationSnapshot
    extends BookSourceValidationSnapshot {
  const factory _BookSourceValidationSnapshot({
    required final bool searchOk,
    required final bool discoveryOk,
    required final bool tocOk,
    required final bool contentOk,
    required final int searchTimeMs,
    final List<String> errors,
  }) = _$BookSourceValidationSnapshotImpl;
  const _BookSourceValidationSnapshot._() : super._();

  @override
  bool get searchOk;
  @override
  bool get discoveryOk;
  @override
  bool get tocOk;
  @override
  bool get contentOk;
  @override
  int get searchTimeMs;
  @override
  List<String> get errors;

  /// Create a copy of BookSourceValidationSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookSourceValidationSnapshotImplCopyWith<
    _$BookSourceValidationSnapshotImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}
