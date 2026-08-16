// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'replace_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ReplaceState {
  List<ReplaceRule> get rules => throw _privateConstructorUsedError;

  /// Create a copy of ReplaceState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReplaceStateCopyWith<ReplaceState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReplaceStateCopyWith<$Res> {
  factory $ReplaceStateCopyWith(
    ReplaceState value,
    $Res Function(ReplaceState) then,
  ) = _$ReplaceStateCopyWithImpl<$Res, ReplaceState>;
  @useResult
  $Res call({List<ReplaceRule> rules});
}

/// @nodoc
class _$ReplaceStateCopyWithImpl<$Res, $Val extends ReplaceState>
    implements $ReplaceStateCopyWith<$Res> {
  _$ReplaceStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReplaceState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? rules = null}) {
    return _then(
      _value.copyWith(
            rules: null == rules
                ? _value.rules
                : rules // ignore: cast_nullable_to_non_nullable
                      as List<ReplaceRule>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReplaceStateImplCopyWith<$Res>
    implements $ReplaceStateCopyWith<$Res> {
  factory _$$ReplaceStateImplCopyWith(
    _$ReplaceStateImpl value,
    $Res Function(_$ReplaceStateImpl) then,
  ) = __$$ReplaceStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ReplaceRule> rules});
}

/// @nodoc
class __$$ReplaceStateImplCopyWithImpl<$Res>
    extends _$ReplaceStateCopyWithImpl<$Res, _$ReplaceStateImpl>
    implements _$$ReplaceStateImplCopyWith<$Res> {
  __$$ReplaceStateImplCopyWithImpl(
    _$ReplaceStateImpl _value,
    $Res Function(_$ReplaceStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReplaceState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? rules = null}) {
    return _then(
      _$ReplaceStateImpl(
        rules: null == rules
            ? _value._rules
            : rules // ignore: cast_nullable_to_non_nullable
                  as List<ReplaceRule>,
      ),
    );
  }
}

/// @nodoc

class _$ReplaceStateImpl implements _ReplaceState {
  const _$ReplaceStateImpl({
    final List<ReplaceRule> rules = const <ReplaceRule>[],
  }) : _rules = rules;

  final List<ReplaceRule> _rules;
  @override
  @JsonKey()
  List<ReplaceRule> get rules {
    if (_rules is EqualUnmodifiableListView) return _rules;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rules);
  }

  @override
  String toString() {
    return 'ReplaceState(rules: $rules)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplaceStateImpl &&
            const DeepCollectionEquality().equals(other._rules, _rules));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_rules));

  /// Create a copy of ReplaceState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplaceStateImplCopyWith<_$ReplaceStateImpl> get copyWith =>
      __$$ReplaceStateImplCopyWithImpl<_$ReplaceStateImpl>(this, _$identity);
}

abstract class _ReplaceState implements ReplaceState {
  const factory _ReplaceState({final List<ReplaceRule> rules}) =
      _$ReplaceStateImpl;

  @override
  List<ReplaceRule> get rules;

  /// Create a copy of ReplaceState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReplaceStateImplCopyWith<_$ReplaceStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
