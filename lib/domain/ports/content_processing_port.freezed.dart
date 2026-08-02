// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_processing_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ContentProcessingSourceRules {
  String get contentReplace => throw _privateConstructorUsedError;
  String get contentReplaceTo => throw _privateConstructorUsedError;

  /// Create a copy of ContentProcessingSourceRules
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContentProcessingSourceRulesCopyWith<ContentProcessingSourceRules>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentProcessingSourceRulesCopyWith<$Res> {
  factory $ContentProcessingSourceRulesCopyWith(
    ContentProcessingSourceRules value,
    $Res Function(ContentProcessingSourceRules) then,
  ) =
      _$ContentProcessingSourceRulesCopyWithImpl<
        $Res,
        ContentProcessingSourceRules
      >;
  @useResult
  $Res call({String contentReplace, String contentReplaceTo});
}

/// @nodoc
class _$ContentProcessingSourceRulesCopyWithImpl<
  $Res,
  $Val extends ContentProcessingSourceRules
>
    implements $ContentProcessingSourceRulesCopyWith<$Res> {
  _$ContentProcessingSourceRulesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentProcessingSourceRules
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? contentReplace = null, Object? contentReplaceTo = null}) {
    return _then(
      _value.copyWith(
            contentReplace: null == contentReplace
                ? _value.contentReplace
                : contentReplace // ignore: cast_nullable_to_non_nullable
                      as String,
            contentReplaceTo: null == contentReplaceTo
                ? _value.contentReplaceTo
                : contentReplaceTo // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ContentProcessingSourceRulesImplCopyWith<$Res>
    implements $ContentProcessingSourceRulesCopyWith<$Res> {
  factory _$$ContentProcessingSourceRulesImplCopyWith(
    _$ContentProcessingSourceRulesImpl value,
    $Res Function(_$ContentProcessingSourceRulesImpl) then,
  ) = __$$ContentProcessingSourceRulesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String contentReplace, String contentReplaceTo});
}

/// @nodoc
class __$$ContentProcessingSourceRulesImplCopyWithImpl<$Res>
    extends
        _$ContentProcessingSourceRulesCopyWithImpl<
          $Res,
          _$ContentProcessingSourceRulesImpl
        >
    implements _$$ContentProcessingSourceRulesImplCopyWith<$Res> {
  __$$ContentProcessingSourceRulesImplCopyWithImpl(
    _$ContentProcessingSourceRulesImpl _value,
    $Res Function(_$ContentProcessingSourceRulesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentProcessingSourceRules
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? contentReplace = null, Object? contentReplaceTo = null}) {
    return _then(
      _$ContentProcessingSourceRulesImpl(
        contentReplace: null == contentReplace
            ? _value.contentReplace
            : contentReplace // ignore: cast_nullable_to_non_nullable
                  as String,
        contentReplaceTo: null == contentReplaceTo
            ? _value.contentReplaceTo
            : contentReplaceTo // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ContentProcessingSourceRulesImpl
    implements _ContentProcessingSourceRules {
  const _$ContentProcessingSourceRulesImpl({
    this.contentReplace = '',
    this.contentReplaceTo = '',
  });

  @override
  @JsonKey()
  final String contentReplace;
  @override
  @JsonKey()
  final String contentReplaceTo;

  @override
  String toString() {
    return 'ContentProcessingSourceRules(contentReplace: $contentReplace, contentReplaceTo: $contentReplaceTo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContentProcessingSourceRulesImpl &&
            (identical(other.contentReplace, contentReplace) ||
                other.contentReplace == contentReplace) &&
            (identical(other.contentReplaceTo, contentReplaceTo) ||
                other.contentReplaceTo == contentReplaceTo));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, contentReplace, contentReplaceTo);

  /// Create a copy of ContentProcessingSourceRules
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContentProcessingSourceRulesImplCopyWith<
    _$ContentProcessingSourceRulesImpl
  >
  get copyWith =>
      __$$ContentProcessingSourceRulesImplCopyWithImpl<
        _$ContentProcessingSourceRulesImpl
      >(this, _$identity);
}

abstract class _ContentProcessingSourceRules
    implements ContentProcessingSourceRules {
  const factory _ContentProcessingSourceRules({
    final String contentReplace,
    final String contentReplaceTo,
  }) = _$ContentProcessingSourceRulesImpl;

  @override
  String get contentReplace;
  @override
  String get contentReplaceTo;

  /// Create a copy of ContentProcessingSourceRules
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContentProcessingSourceRulesImplCopyWith<
    _$ContentProcessingSourceRulesImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}
