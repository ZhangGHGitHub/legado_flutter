// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'replace_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ReplaceRule {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get pattern => throw _privateConstructorUsedError;
  String get replacement => throw _privateConstructorUsedError;
  bool get isEnabled => throw _privateConstructorUsedError;
  bool get isRegex => throw _privateConstructorUsedError;

  /// Create a copy of ReplaceRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReplaceRuleCopyWith<ReplaceRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReplaceRuleCopyWith<$Res> {
  factory $ReplaceRuleCopyWith(
    ReplaceRule value,
    $Res Function(ReplaceRule) then,
  ) = _$ReplaceRuleCopyWithImpl<$Res, ReplaceRule>;
  @useResult
  $Res call({
    String id,
    String name,
    String pattern,
    String replacement,
    bool isEnabled,
    bool isRegex,
  });
}

/// @nodoc
class _$ReplaceRuleCopyWithImpl<$Res, $Val extends ReplaceRule>
    implements $ReplaceRuleCopyWith<$Res> {
  _$ReplaceRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReplaceRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? pattern = null,
    Object? replacement = null,
    Object? isEnabled = null,
    Object? isRegex = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            pattern: null == pattern
                ? _value.pattern
                : pattern // ignore: cast_nullable_to_non_nullable
                      as String,
            replacement: null == replacement
                ? _value.replacement
                : replacement // ignore: cast_nullable_to_non_nullable
                      as String,
            isEnabled: null == isEnabled
                ? _value.isEnabled
                : isEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            isRegex: null == isRegex
                ? _value.isRegex
                : isRegex // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReplaceRuleImplCopyWith<$Res>
    implements $ReplaceRuleCopyWith<$Res> {
  factory _$$ReplaceRuleImplCopyWith(
    _$ReplaceRuleImpl value,
    $Res Function(_$ReplaceRuleImpl) then,
  ) = __$$ReplaceRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String pattern,
    String replacement,
    bool isEnabled,
    bool isRegex,
  });
}

/// @nodoc
class __$$ReplaceRuleImplCopyWithImpl<$Res>
    extends _$ReplaceRuleCopyWithImpl<$Res, _$ReplaceRuleImpl>
    implements _$$ReplaceRuleImplCopyWith<$Res> {
  __$$ReplaceRuleImplCopyWithImpl(
    _$ReplaceRuleImpl _value,
    $Res Function(_$ReplaceRuleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReplaceRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? pattern = null,
    Object? replacement = null,
    Object? isEnabled = null,
    Object? isRegex = null,
  }) {
    return _then(
      _$ReplaceRuleImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        pattern: null == pattern
            ? _value.pattern
            : pattern // ignore: cast_nullable_to_non_nullable
                  as String,
        replacement: null == replacement
            ? _value.replacement
            : replacement // ignore: cast_nullable_to_non_nullable
                  as String,
        isEnabled: null == isEnabled
            ? _value.isEnabled
            : isEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        isRegex: null == isRegex
            ? _value.isRegex
            : isRegex // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$ReplaceRuleImpl extends _ReplaceRule {
  const _$ReplaceRuleImpl({
    required this.id,
    required this.name,
    required this.pattern,
    this.replacement = '',
    this.isEnabled = true,
    this.isRegex = true,
  }) : super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final String pattern;
  @override
  @JsonKey()
  final String replacement;
  @override
  @JsonKey()
  final bool isEnabled;
  @override
  @JsonKey()
  final bool isRegex;

  @override
  String toString() {
    return 'ReplaceRule(id: $id, name: $name, pattern: $pattern, replacement: $replacement, isEnabled: $isEnabled, isRegex: $isRegex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplaceRuleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.pattern, pattern) || other.pattern == pattern) &&
            (identical(other.replacement, replacement) ||
                other.replacement == replacement) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled) &&
            (identical(other.isRegex, isRegex) || other.isRegex == isRegex));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    pattern,
    replacement,
    isEnabled,
    isRegex,
  );

  /// Create a copy of ReplaceRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplaceRuleImplCopyWith<_$ReplaceRuleImpl> get copyWith =>
      __$$ReplaceRuleImplCopyWithImpl<_$ReplaceRuleImpl>(this, _$identity);
}

abstract class _ReplaceRule extends ReplaceRule {
  const factory _ReplaceRule({
    required final String id,
    required final String name,
    required final String pattern,
    final String replacement,
    final bool isEnabled,
    final bool isRegex,
  }) = _$ReplaceRuleImpl;
  const _ReplaceRule._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String get pattern;
  @override
  String get replacement;
  @override
  bool get isEnabled;
  @override
  bool get isRegex;

  /// Create a copy of ReplaceRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReplaceRuleImplCopyWith<_$ReplaceRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
