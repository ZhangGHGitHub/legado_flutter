// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_row_ui.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LoginRowUi {
  String get name => throw _privateConstructorUsedError;
  LoginRowType get type => throw _privateConstructorUsedError;
  String? get viewName => throw _privateConstructorUsedError;
  String? get defaultValue => throw _privateConstructorUsedError;
  List<String> get chars => throw _privateConstructorUsedError;

  /// Create a copy of LoginRowUi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoginRowUiCopyWith<LoginRowUi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginRowUiCopyWith<$Res> {
  factory $LoginRowUiCopyWith(
    LoginRowUi value,
    $Res Function(LoginRowUi) then,
  ) = _$LoginRowUiCopyWithImpl<$Res, LoginRowUi>;
  @useResult
  $Res call({
    String name,
    LoginRowType type,
    String? viewName,
    String? defaultValue,
    List<String> chars,
  });
}

/// @nodoc
class _$LoginRowUiCopyWithImpl<$Res, $Val extends LoginRowUi>
    implements $LoginRowUiCopyWith<$Res> {
  _$LoginRowUiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoginRowUi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? type = null,
    Object? viewName = freezed,
    Object? defaultValue = freezed,
    Object? chars = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as LoginRowType,
            viewName: freezed == viewName
                ? _value.viewName
                : viewName // ignore: cast_nullable_to_non_nullable
                      as String?,
            defaultValue: freezed == defaultValue
                ? _value.defaultValue
                : defaultValue // ignore: cast_nullable_to_non_nullable
                      as String?,
            chars: null == chars
                ? _value.chars
                : chars // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LoginRowUiImplCopyWith<$Res>
    implements $LoginRowUiCopyWith<$Res> {
  factory _$$LoginRowUiImplCopyWith(
    _$LoginRowUiImpl value,
    $Res Function(_$LoginRowUiImpl) then,
  ) = __$$LoginRowUiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    LoginRowType type,
    String? viewName,
    String? defaultValue,
    List<String> chars,
  });
}

/// @nodoc
class __$$LoginRowUiImplCopyWithImpl<$Res>
    extends _$LoginRowUiCopyWithImpl<$Res, _$LoginRowUiImpl>
    implements _$$LoginRowUiImplCopyWith<$Res> {
  __$$LoginRowUiImplCopyWithImpl(
    _$LoginRowUiImpl _value,
    $Res Function(_$LoginRowUiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LoginRowUi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? type = null,
    Object? viewName = freezed,
    Object? defaultValue = freezed,
    Object? chars = null,
  }) {
    return _then(
      _$LoginRowUiImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as LoginRowType,
        viewName: freezed == viewName
            ? _value.viewName
            : viewName // ignore: cast_nullable_to_non_nullable
                  as String?,
        defaultValue: freezed == defaultValue
            ? _value.defaultValue
            : defaultValue // ignore: cast_nullable_to_non_nullable
                  as String?,
        chars: null == chars
            ? _value._chars
            : chars // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc

class _$LoginRowUiImpl extends _LoginRowUi {
  const _$LoginRowUiImpl({
    required this.name,
    required this.type,
    this.viewName,
    this.defaultValue,
    final List<String> chars = const <String>[],
  }) : _chars = chars,
       super._();

  @override
  final String name;
  @override
  final LoginRowType type;
  @override
  final String? viewName;
  @override
  final String? defaultValue;
  final List<String> _chars;
  @override
  @JsonKey()
  List<String> get chars {
    if (_chars is EqualUnmodifiableListView) return _chars;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chars);
  }

  @override
  String toString() {
    return 'LoginRowUi(name: $name, type: $type, viewName: $viewName, defaultValue: $defaultValue, chars: $chars)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginRowUiImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.viewName, viewName) ||
                other.viewName == viewName) &&
            (identical(other.defaultValue, defaultValue) ||
                other.defaultValue == defaultValue) &&
            const DeepCollectionEquality().equals(other._chars, _chars));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    type,
    viewName,
    defaultValue,
    const DeepCollectionEquality().hash(_chars),
  );

  /// Create a copy of LoginRowUi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginRowUiImplCopyWith<_$LoginRowUiImpl> get copyWith =>
      __$$LoginRowUiImplCopyWithImpl<_$LoginRowUiImpl>(this, _$identity);
}

abstract class _LoginRowUi extends LoginRowUi {
  const factory _LoginRowUi({
    required final String name,
    required final LoginRowType type,
    final String? viewName,
    final String? defaultValue,
    final List<String> chars,
  }) = _$LoginRowUiImpl;
  const _LoginRowUi._() : super._();

  @override
  String get name;
  @override
  LoginRowType get type;
  @override
  String? get viewName;
  @override
  String? get defaultValue;
  @override
  List<String> get chars;

  /// Create a copy of LoginRowUi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginRowUiImplCopyWith<_$LoginRowUiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
