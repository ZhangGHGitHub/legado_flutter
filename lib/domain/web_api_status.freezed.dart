// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'web_api_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$WebApiStatus {
  bool get running => throw _privateConstructorUsedError;
  int get port => throw _privateConstructorUsedError;
  String get token => throw _privateConstructorUsedError;
  String get baseUrl => throw _privateConstructorUsedError;

  /// Create a copy of WebApiStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WebApiStatusCopyWith<WebApiStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebApiStatusCopyWith<$Res> {
  factory $WebApiStatusCopyWith(
    WebApiStatus value,
    $Res Function(WebApiStatus) then,
  ) = _$WebApiStatusCopyWithImpl<$Res, WebApiStatus>;
  @useResult
  $Res call({bool running, int port, String token, String baseUrl});
}

/// @nodoc
class _$WebApiStatusCopyWithImpl<$Res, $Val extends WebApiStatus>
    implements $WebApiStatusCopyWith<$Res> {
  _$WebApiStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WebApiStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? running = null,
    Object? port = null,
    Object? token = null,
    Object? baseUrl = null,
  }) {
    return _then(
      _value.copyWith(
            running: null == running
                ? _value.running
                : running // ignore: cast_nullable_to_non_nullable
                      as bool,
            port: null == port
                ? _value.port
                : port // ignore: cast_nullable_to_non_nullable
                      as int,
            token: null == token
                ? _value.token
                : token // ignore: cast_nullable_to_non_nullable
                      as String,
            baseUrl: null == baseUrl
                ? _value.baseUrl
                : baseUrl // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WebApiStatusImplCopyWith<$Res>
    implements $WebApiStatusCopyWith<$Res> {
  factory _$$WebApiStatusImplCopyWith(
    _$WebApiStatusImpl value,
    $Res Function(_$WebApiStatusImpl) then,
  ) = __$$WebApiStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool running, int port, String token, String baseUrl});
}

/// @nodoc
class __$$WebApiStatusImplCopyWithImpl<$Res>
    extends _$WebApiStatusCopyWithImpl<$Res, _$WebApiStatusImpl>
    implements _$$WebApiStatusImplCopyWith<$Res> {
  __$$WebApiStatusImplCopyWithImpl(
    _$WebApiStatusImpl _value,
    $Res Function(_$WebApiStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WebApiStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? running = null,
    Object? port = null,
    Object? token = null,
    Object? baseUrl = null,
  }) {
    return _then(
      _$WebApiStatusImpl(
        running: null == running
            ? _value.running
            : running // ignore: cast_nullable_to_non_nullable
                  as bool,
        port: null == port
            ? _value.port
            : port // ignore: cast_nullable_to_non_nullable
                  as int,
        token: null == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
        baseUrl: null == baseUrl
            ? _value.baseUrl
            : baseUrl // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$WebApiStatusImpl implements _WebApiStatus {
  const _$WebApiStatusImpl({
    required this.running,
    required this.port,
    required this.token,
    required this.baseUrl,
  });

  @override
  final bool running;
  @override
  final int port;
  @override
  final String token;
  @override
  final String baseUrl;

  @override
  String toString() {
    return 'WebApiStatus(running: $running, port: $port, token: $token, baseUrl: $baseUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebApiStatusImpl &&
            (identical(other.running, running) || other.running == running) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl));
  }

  @override
  int get hashCode => Object.hash(runtimeType, running, port, token, baseUrl);

  /// Create a copy of WebApiStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WebApiStatusImplCopyWith<_$WebApiStatusImpl> get copyWith =>
      __$$WebApiStatusImplCopyWithImpl<_$WebApiStatusImpl>(this, _$identity);
}

abstract class _WebApiStatus implements WebApiStatus {
  const factory _WebApiStatus({
    required final bool running,
    required final int port,
    required final String token,
    required final String baseUrl,
  }) = _$WebApiStatusImpl;

  @override
  bool get running;
  @override
  int get port;
  @override
  String get token;
  @override
  String get baseUrl;

  /// Create a copy of WebApiStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WebApiStatusImplCopyWith<_$WebApiStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
