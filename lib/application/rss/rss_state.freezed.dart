// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rss_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RssState {
  List<RssSource> get sources => throw _privateConstructorUsedError;

  /// Create a copy of RssState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RssStateCopyWith<RssState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RssStateCopyWith<$Res> {
  factory $RssStateCopyWith(RssState value, $Res Function(RssState) then) =
      _$RssStateCopyWithImpl<$Res, RssState>;
  @useResult
  $Res call({List<RssSource> sources});
}

/// @nodoc
class _$RssStateCopyWithImpl<$Res, $Val extends RssState>
    implements $RssStateCopyWith<$Res> {
  _$RssStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RssState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? sources = null}) {
    return _then(
      _value.copyWith(
            sources: null == sources
                ? _value.sources
                : sources // ignore: cast_nullable_to_non_nullable
                      as List<RssSource>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RssStateImplCopyWith<$Res>
    implements $RssStateCopyWith<$Res> {
  factory _$$RssStateImplCopyWith(
    _$RssStateImpl value,
    $Res Function(_$RssStateImpl) then,
  ) = __$$RssStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<RssSource> sources});
}

/// @nodoc
class __$$RssStateImplCopyWithImpl<$Res>
    extends _$RssStateCopyWithImpl<$Res, _$RssStateImpl>
    implements _$$RssStateImplCopyWith<$Res> {
  __$$RssStateImplCopyWithImpl(
    _$RssStateImpl _value,
    $Res Function(_$RssStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RssState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? sources = null}) {
    return _then(
      _$RssStateImpl(
        sources: null == sources
            ? _value._sources
            : sources // ignore: cast_nullable_to_non_nullable
                  as List<RssSource>,
      ),
    );
  }
}

/// @nodoc

class _$RssStateImpl implements _RssState {
  const _$RssStateImpl({final List<RssSource> sources = const <RssSource>[]})
    : _sources = sources;

  final List<RssSource> _sources;
  @override
  @JsonKey()
  List<RssSource> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  @override
  String toString() {
    return 'RssState(sources: $sources)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RssStateImpl &&
            const DeepCollectionEquality().equals(other._sources, _sources));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_sources));

  /// Create a copy of RssState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RssStateImplCopyWith<_$RssStateImpl> get copyWith =>
      __$$RssStateImplCopyWithImpl<_$RssStateImpl>(this, _$identity);
}

abstract class _RssState implements RssState {
  const factory _RssState({final List<RssSource> sources}) = _$RssStateImpl;

  @override
  List<RssSource> get sources;

  /// Create a copy of RssState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RssStateImplCopyWith<_$RssStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
