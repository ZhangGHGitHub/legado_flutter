// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dict_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DictRule {
  String get name => throw _privateConstructorUsedError;
  String get urlRule => throw _privateConstructorUsedError;
  String get showRule => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  int get sortNumber => throw _privateConstructorUsedError;

  /// Create a copy of DictRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DictRuleCopyWith<DictRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DictRuleCopyWith<$Res> {
  factory $DictRuleCopyWith(DictRule value, $Res Function(DictRule) then) =
      _$DictRuleCopyWithImpl<$Res, DictRule>;
  @useResult
  $Res call({
    String name,
    String urlRule,
    String showRule,
    bool enabled,
    int sortNumber,
  });
}

/// @nodoc
class _$DictRuleCopyWithImpl<$Res, $Val extends DictRule>
    implements $DictRuleCopyWith<$Res> {
  _$DictRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DictRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? urlRule = null,
    Object? showRule = null,
    Object? enabled = null,
    Object? sortNumber = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            urlRule: null == urlRule
                ? _value.urlRule
                : urlRule // ignore: cast_nullable_to_non_nullable
                      as String,
            showRule: null == showRule
                ? _value.showRule
                : showRule // ignore: cast_nullable_to_non_nullable
                      as String,
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            sortNumber: null == sortNumber
                ? _value.sortNumber
                : sortNumber // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DictRuleImplCopyWith<$Res>
    implements $DictRuleCopyWith<$Res> {
  factory _$$DictRuleImplCopyWith(
    _$DictRuleImpl value,
    $Res Function(_$DictRuleImpl) then,
  ) = __$$DictRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String urlRule,
    String showRule,
    bool enabled,
    int sortNumber,
  });
}

/// @nodoc
class __$$DictRuleImplCopyWithImpl<$Res>
    extends _$DictRuleCopyWithImpl<$Res, _$DictRuleImpl>
    implements _$$DictRuleImplCopyWith<$Res> {
  __$$DictRuleImplCopyWithImpl(
    _$DictRuleImpl _value,
    $Res Function(_$DictRuleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DictRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? urlRule = null,
    Object? showRule = null,
    Object? enabled = null,
    Object? sortNumber = null,
  }) {
    return _then(
      _$DictRuleImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        urlRule: null == urlRule
            ? _value.urlRule
            : urlRule // ignore: cast_nullable_to_non_nullable
                  as String,
        showRule: null == showRule
            ? _value.showRule
            : showRule // ignore: cast_nullable_to_non_nullable
                  as String,
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortNumber: null == sortNumber
            ? _value.sortNumber
            : sortNumber // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$DictRuleImpl extends _DictRule {
  const _$DictRuleImpl({
    required this.name,
    this.urlRule = '',
    this.showRule = '',
    this.enabled = true,
    this.sortNumber = 0,
  }) : super._();

  @override
  final String name;
  @override
  @JsonKey()
  final String urlRule;
  @override
  @JsonKey()
  final String showRule;
  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final int sortNumber;

  @override
  String toString() {
    return 'DictRule(name: $name, urlRule: $urlRule, showRule: $showRule, enabled: $enabled, sortNumber: $sortNumber)';
  }

  /// Create a copy of DictRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DictRuleImplCopyWith<_$DictRuleImpl> get copyWith =>
      __$$DictRuleImplCopyWithImpl<_$DictRuleImpl>(this, _$identity);
}

abstract class _DictRule extends DictRule {
  const factory _DictRule({
    required final String name,
    final String urlRule,
    final String showRule,
    final bool enabled,
    final int sortNumber,
  }) = _$DictRuleImpl;
  const _DictRule._() : super._();

  @override
  String get name;
  @override
  String get urlRule;
  @override
  String get showRule;
  @override
  bool get enabled;
  @override
  int get sortNumber;

  /// Create a copy of DictRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DictRuleImplCopyWith<_$DictRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
