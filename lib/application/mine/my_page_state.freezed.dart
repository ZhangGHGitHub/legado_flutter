// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_page_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MyPageState {
  MyPageWebServiceLoadState get webServiceLoadState =>
      throw _privateConstructorUsedError;
  bool get webServiceOn => throw _privateConstructorUsedError;
  String get webServiceUrl => throw _privateConstructorUsedError;
  String? get webServiceError => throw _privateConstructorUsedError;
  MyPageBackupState get backupState => throw _privateConstructorUsedError;
  String? get backupFileName => throw _privateConstructorUsedError;
  String? get backupError => throw _privateConstructorUsedError;

  /// Create a copy of MyPageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MyPageStateCopyWith<MyPageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyPageStateCopyWith<$Res> {
  factory $MyPageStateCopyWith(
    MyPageState value,
    $Res Function(MyPageState) then,
  ) = _$MyPageStateCopyWithImpl<$Res, MyPageState>;
  @useResult
  $Res call({
    MyPageWebServiceLoadState webServiceLoadState,
    bool webServiceOn,
    String webServiceUrl,
    String? webServiceError,
    MyPageBackupState backupState,
    String? backupFileName,
    String? backupError,
  });
}

/// @nodoc
class _$MyPageStateCopyWithImpl<$Res, $Val extends MyPageState>
    implements $MyPageStateCopyWith<$Res> {
  _$MyPageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MyPageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? webServiceLoadState = null,
    Object? webServiceOn = null,
    Object? webServiceUrl = null,
    Object? webServiceError = freezed,
    Object? backupState = null,
    Object? backupFileName = freezed,
    Object? backupError = freezed,
  }) {
    return _then(
      _value.copyWith(
            webServiceLoadState: null == webServiceLoadState
                ? _value.webServiceLoadState
                : webServiceLoadState // ignore: cast_nullable_to_non_nullable
                      as MyPageWebServiceLoadState,
            webServiceOn: null == webServiceOn
                ? _value.webServiceOn
                : webServiceOn // ignore: cast_nullable_to_non_nullable
                      as bool,
            webServiceUrl: null == webServiceUrl
                ? _value.webServiceUrl
                : webServiceUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            webServiceError: freezed == webServiceError
                ? _value.webServiceError
                : webServiceError // ignore: cast_nullable_to_non_nullable
                      as String?,
            backupState: null == backupState
                ? _value.backupState
                : backupState // ignore: cast_nullable_to_non_nullable
                      as MyPageBackupState,
            backupFileName: freezed == backupFileName
                ? _value.backupFileName
                : backupFileName // ignore: cast_nullable_to_non_nullable
                      as String?,
            backupError: freezed == backupError
                ? _value.backupError
                : backupError // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MyPageStateImplCopyWith<$Res>
    implements $MyPageStateCopyWith<$Res> {
  factory _$$MyPageStateImplCopyWith(
    _$MyPageStateImpl value,
    $Res Function(_$MyPageStateImpl) then,
  ) = __$$MyPageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    MyPageWebServiceLoadState webServiceLoadState,
    bool webServiceOn,
    String webServiceUrl,
    String? webServiceError,
    MyPageBackupState backupState,
    String? backupFileName,
    String? backupError,
  });
}

/// @nodoc
class __$$MyPageStateImplCopyWithImpl<$Res>
    extends _$MyPageStateCopyWithImpl<$Res, _$MyPageStateImpl>
    implements _$$MyPageStateImplCopyWith<$Res> {
  __$$MyPageStateImplCopyWithImpl(
    _$MyPageStateImpl _value,
    $Res Function(_$MyPageStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MyPageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? webServiceLoadState = null,
    Object? webServiceOn = null,
    Object? webServiceUrl = null,
    Object? webServiceError = freezed,
    Object? backupState = null,
    Object? backupFileName = freezed,
    Object? backupError = freezed,
  }) {
    return _then(
      _$MyPageStateImpl(
        webServiceLoadState: null == webServiceLoadState
            ? _value.webServiceLoadState
            : webServiceLoadState // ignore: cast_nullable_to_non_nullable
                  as MyPageWebServiceLoadState,
        webServiceOn: null == webServiceOn
            ? _value.webServiceOn
            : webServiceOn // ignore: cast_nullable_to_non_nullable
                  as bool,
        webServiceUrl: null == webServiceUrl
            ? _value.webServiceUrl
            : webServiceUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        webServiceError: freezed == webServiceError
            ? _value.webServiceError
            : webServiceError // ignore: cast_nullable_to_non_nullable
                  as String?,
        backupState: null == backupState
            ? _value.backupState
            : backupState // ignore: cast_nullable_to_non_nullable
                  as MyPageBackupState,
        backupFileName: freezed == backupFileName
            ? _value.backupFileName
            : backupFileName // ignore: cast_nullable_to_non_nullable
                  as String?,
        backupError: freezed == backupError
            ? _value.backupError
            : backupError // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$MyPageStateImpl extends _MyPageState {
  const _$MyPageStateImpl({
    this.webServiceLoadState = MyPageWebServiceLoadState.initial,
    this.webServiceOn = false,
    this.webServiceUrl = '',
    this.webServiceError,
    this.backupState = MyPageBackupState.idle,
    this.backupFileName,
    this.backupError,
  }) : super._();

  @override
  @JsonKey()
  final MyPageWebServiceLoadState webServiceLoadState;
  @override
  @JsonKey()
  final bool webServiceOn;
  @override
  @JsonKey()
  final String webServiceUrl;
  @override
  final String? webServiceError;
  @override
  @JsonKey()
  final MyPageBackupState backupState;
  @override
  final String? backupFileName;
  @override
  final String? backupError;

  @override
  String toString() {
    return 'MyPageState(webServiceLoadState: $webServiceLoadState, webServiceOn: $webServiceOn, webServiceUrl: $webServiceUrl, webServiceError: $webServiceError, backupState: $backupState, backupFileName: $backupFileName, backupError: $backupError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyPageStateImpl &&
            (identical(other.webServiceLoadState, webServiceLoadState) ||
                other.webServiceLoadState == webServiceLoadState) &&
            (identical(other.webServiceOn, webServiceOn) ||
                other.webServiceOn == webServiceOn) &&
            (identical(other.webServiceUrl, webServiceUrl) ||
                other.webServiceUrl == webServiceUrl) &&
            (identical(other.webServiceError, webServiceError) ||
                other.webServiceError == webServiceError) &&
            (identical(other.backupState, backupState) ||
                other.backupState == backupState) &&
            (identical(other.backupFileName, backupFileName) ||
                other.backupFileName == backupFileName) &&
            (identical(other.backupError, backupError) ||
                other.backupError == backupError));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    webServiceLoadState,
    webServiceOn,
    webServiceUrl,
    webServiceError,
    backupState,
    backupFileName,
    backupError,
  );

  /// Create a copy of MyPageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MyPageStateImplCopyWith<_$MyPageStateImpl> get copyWith =>
      __$$MyPageStateImplCopyWithImpl<_$MyPageStateImpl>(this, _$identity);
}

abstract class _MyPageState extends MyPageState {
  const factory _MyPageState({
    final MyPageWebServiceLoadState webServiceLoadState,
    final bool webServiceOn,
    final String webServiceUrl,
    final String? webServiceError,
    final MyPageBackupState backupState,
    final String? backupFileName,
    final String? backupError,
  }) = _$MyPageStateImpl;
  const _MyPageState._() : super._();

  @override
  MyPageWebServiceLoadState get webServiceLoadState;
  @override
  bool get webServiceOn;
  @override
  String get webServiceUrl;
  @override
  String? get webServiceError;
  @override
  MyPageBackupState get backupState;
  @override
  String? get backupFileName;
  @override
  String? get backupError;

  /// Create a copy of MyPageState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MyPageStateImplCopyWith<_$MyPageStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
