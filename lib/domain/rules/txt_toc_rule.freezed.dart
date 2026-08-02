// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'txt_toc_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TxtTocRule {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get rule => throw _privateConstructorUsedError;
  String get replacement => throw _privateConstructorUsedError;
  String? get example => throw _privateConstructorUsedError;
  int get serialNumber => throw _privateConstructorUsedError;
  bool get enable => throw _privateConstructorUsedError;

  /// Create a copy of TxtTocRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TxtTocRuleCopyWith<TxtTocRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TxtTocRuleCopyWith<$Res> {
  factory $TxtTocRuleCopyWith(
    TxtTocRule value,
    $Res Function(TxtTocRule) then,
  ) = _$TxtTocRuleCopyWithImpl<$Res, TxtTocRule>;
  @useResult
  $Res call({
    int id,
    String name,
    String rule,
    String replacement,
    String? example,
    int serialNumber,
    bool enable,
  });
}

/// @nodoc
class _$TxtTocRuleCopyWithImpl<$Res, $Val extends TxtTocRule>
    implements $TxtTocRuleCopyWith<$Res> {
  _$TxtTocRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TxtTocRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? rule = null,
    Object? replacement = null,
    Object? example = freezed,
    Object? serialNumber = null,
    Object? enable = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            rule: null == rule
                ? _value.rule
                : rule // ignore: cast_nullable_to_non_nullable
                      as String,
            replacement: null == replacement
                ? _value.replacement
                : replacement // ignore: cast_nullable_to_non_nullable
                      as String,
            example: freezed == example
                ? _value.example
                : example // ignore: cast_nullable_to_non_nullable
                      as String?,
            serialNumber: null == serialNumber
                ? _value.serialNumber
                : serialNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            enable: null == enable
                ? _value.enable
                : enable // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TxtTocRuleImplCopyWith<$Res>
    implements $TxtTocRuleCopyWith<$Res> {
  factory _$$TxtTocRuleImplCopyWith(
    _$TxtTocRuleImpl value,
    $Res Function(_$TxtTocRuleImpl) then,
  ) = __$$TxtTocRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String rule,
    String replacement,
    String? example,
    int serialNumber,
    bool enable,
  });
}

/// @nodoc
class __$$TxtTocRuleImplCopyWithImpl<$Res>
    extends _$TxtTocRuleCopyWithImpl<$Res, _$TxtTocRuleImpl>
    implements _$$TxtTocRuleImplCopyWith<$Res> {
  __$$TxtTocRuleImplCopyWithImpl(
    _$TxtTocRuleImpl _value,
    $Res Function(_$TxtTocRuleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TxtTocRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? rule = null,
    Object? replacement = null,
    Object? example = freezed,
    Object? serialNumber = null,
    Object? enable = null,
  }) {
    return _then(
      _$TxtTocRuleImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        rule: null == rule
            ? _value.rule
            : rule // ignore: cast_nullable_to_non_nullable
                  as String,
        replacement: null == replacement
            ? _value.replacement
            : replacement // ignore: cast_nullable_to_non_nullable
                  as String,
        example: freezed == example
            ? _value.example
            : example // ignore: cast_nullable_to_non_nullable
                  as String?,
        serialNumber: null == serialNumber
            ? _value.serialNumber
            : serialNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        enable: null == enable
            ? _value.enable
            : enable // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$TxtTocRuleImpl extends _TxtTocRule {
  const _$TxtTocRuleImpl({
    required this.id,
    required this.name,
    required this.rule,
    this.replacement = '',
    this.example,
    this.serialNumber = -1,
    this.enable = true,
  }) : super._();

  @override
  final int id;
  @override
  final String name;
  @override
  final String rule;
  @override
  @JsonKey()
  final String replacement;
  @override
  final String? example;
  @override
  @JsonKey()
  final int serialNumber;
  @override
  @JsonKey()
  final bool enable;

  @override
  String toString() {
    return 'TxtTocRule(id: $id, name: $name, rule: $rule, replacement: $replacement, example: $example, serialNumber: $serialNumber, enable: $enable)';
  }

  /// Create a copy of TxtTocRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TxtTocRuleImplCopyWith<_$TxtTocRuleImpl> get copyWith =>
      __$$TxtTocRuleImplCopyWithImpl<_$TxtTocRuleImpl>(this, _$identity);
}

abstract class _TxtTocRule extends TxtTocRule {
  const factory _TxtTocRule({
    required final int id,
    required final String name,
    required final String rule,
    final String replacement,
    final String? example,
    final int serialNumber,
    final bool enable,
  }) = _$TxtTocRuleImpl;
  const _TxtTocRule._() : super._();

  @override
  int get id;
  @override
  String get name;
  @override
  String get rule;
  @override
  String get replacement;
  @override
  String? get example;
  @override
  int get serialNumber;
  @override
  bool get enable;

  /// Create a copy of TxtTocRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TxtTocRuleImplCopyWith<_$TxtTocRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
