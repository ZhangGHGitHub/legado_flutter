// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BookReadConfig {
  bool get reverseToc => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, dynamic> get extra => throw _privateConstructorUsedError;

  /// Create a copy of BookReadConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookReadConfigCopyWith<BookReadConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookReadConfigCopyWith<$Res> {
  factory $BookReadConfigCopyWith(
    BookReadConfig value,
    $Res Function(BookReadConfig) then,
  ) = _$BookReadConfigCopyWithImpl<$Res, BookReadConfig>;
  @useResult
  $Res call({
    bool reverseToc,
    @JsonKey(includeFromJson: false, includeToJson: false)
    Map<String, dynamic> extra,
  });
}

/// @nodoc
class _$BookReadConfigCopyWithImpl<$Res, $Val extends BookReadConfig>
    implements $BookReadConfigCopyWith<$Res> {
  _$BookReadConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookReadConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? reverseToc = null, Object? extra = null}) {
    return _then(
      _value.copyWith(
            reverseToc: null == reverseToc
                ? _value.reverseToc
                : reverseToc // ignore: cast_nullable_to_non_nullable
                      as bool,
            extra: null == extra
                ? _value.extra
                : extra // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookReadConfigImplCopyWith<$Res>
    implements $BookReadConfigCopyWith<$Res> {
  factory _$$BookReadConfigImplCopyWith(
    _$BookReadConfigImpl value,
    $Res Function(_$BookReadConfigImpl) then,
  ) = __$$BookReadConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool reverseToc,
    @JsonKey(includeFromJson: false, includeToJson: false)
    Map<String, dynamic> extra,
  });
}

/// @nodoc
class __$$BookReadConfigImplCopyWithImpl<$Res>
    extends _$BookReadConfigCopyWithImpl<$Res, _$BookReadConfigImpl>
    implements _$$BookReadConfigImplCopyWith<$Res> {
  __$$BookReadConfigImplCopyWithImpl(
    _$BookReadConfigImpl _value,
    $Res Function(_$BookReadConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookReadConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? reverseToc = null, Object? extra = null}) {
    return _then(
      _$BookReadConfigImpl(
        reverseToc: null == reverseToc
            ? _value.reverseToc
            : reverseToc // ignore: cast_nullable_to_non_nullable
                  as bool,
        extra: null == extra
            ? _value._extra
            : extra // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc

class _$BookReadConfigImpl extends _BookReadConfig {
  const _$BookReadConfigImpl({
    this.reverseToc = false,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final Map<String, dynamic> extra = const <String, dynamic>{},
  }) : _extra = extra,
       super._();

  @override
  @JsonKey()
  final bool reverseToc;
  final Map<String, dynamic> _extra;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, dynamic> get extra {
    if (_extra is EqualUnmodifiableMapView) return _extra;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_extra);
  }

  @override
  String toString() {
    return 'BookReadConfig(reverseToc: $reverseToc, extra: $extra)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookReadConfigImpl &&
            (identical(other.reverseToc, reverseToc) ||
                other.reverseToc == reverseToc) &&
            const DeepCollectionEquality().equals(other._extra, _extra));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    reverseToc,
    const DeepCollectionEquality().hash(_extra),
  );

  /// Create a copy of BookReadConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookReadConfigImplCopyWith<_$BookReadConfigImpl> get copyWith =>
      __$$BookReadConfigImplCopyWithImpl<_$BookReadConfigImpl>(
        this,
        _$identity,
      );
}

abstract class _BookReadConfig extends BookReadConfig {
  const factory _BookReadConfig({
    final bool reverseToc,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final Map<String, dynamic> extra,
  }) = _$BookReadConfigImpl;
  const _BookReadConfig._() : super._();

  @override
  bool get reverseToc;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, dynamic> get extra;

  /// Create a copy of BookReadConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookReadConfigImplCopyWith<_$BookReadConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
