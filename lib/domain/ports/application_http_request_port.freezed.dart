// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'application_http_request_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ApplicationHttpResponse {
  int get statusCode => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;

  /// Create a copy of ApplicationHttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApplicationHttpResponseCopyWith<ApplicationHttpResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApplicationHttpResponseCopyWith<$Res> {
  factory $ApplicationHttpResponseCopyWith(
    ApplicationHttpResponse value,
    $Res Function(ApplicationHttpResponse) then,
  ) = _$ApplicationHttpResponseCopyWithImpl<$Res, ApplicationHttpResponse>;
  @useResult
  $Res call({int statusCode, String body});
}

/// @nodoc
class _$ApplicationHttpResponseCopyWithImpl<
  $Res,
  $Val extends ApplicationHttpResponse
>
    implements $ApplicationHttpResponseCopyWith<$Res> {
  _$ApplicationHttpResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApplicationHttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? statusCode = null, Object? body = null}) {
    return _then(
      _value.copyWith(
            statusCode: null == statusCode
                ? _value.statusCode
                : statusCode // ignore: cast_nullable_to_non_nullable
                      as int,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ApplicationHttpResponseImplCopyWith<$Res>
    implements $ApplicationHttpResponseCopyWith<$Res> {
  factory _$$ApplicationHttpResponseImplCopyWith(
    _$ApplicationHttpResponseImpl value,
    $Res Function(_$ApplicationHttpResponseImpl) then,
  ) = __$$ApplicationHttpResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int statusCode, String body});
}

/// @nodoc
class __$$ApplicationHttpResponseImplCopyWithImpl<$Res>
    extends
        _$ApplicationHttpResponseCopyWithImpl<
          $Res,
          _$ApplicationHttpResponseImpl
        >
    implements _$$ApplicationHttpResponseImplCopyWith<$Res> {
  __$$ApplicationHttpResponseImplCopyWithImpl(
    _$ApplicationHttpResponseImpl _value,
    $Res Function(_$ApplicationHttpResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApplicationHttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? statusCode = null, Object? body = null}) {
    return _then(
      _$ApplicationHttpResponseImpl(
        statusCode: null == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ApplicationHttpResponseImpl implements _ApplicationHttpResponse {
  const _$ApplicationHttpResponseImpl({
    required this.statusCode,
    required this.body,
  });

  @override
  final int statusCode;
  @override
  final String body;

  @override
  String toString() {
    return 'ApplicationHttpResponse(statusCode: $statusCode, body: $body)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApplicationHttpResponseImpl &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode) &&
            (identical(other.body, body) || other.body == body));
  }

  @override
  int get hashCode => Object.hash(runtimeType, statusCode, body);

  /// Create a copy of ApplicationHttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApplicationHttpResponseImplCopyWith<_$ApplicationHttpResponseImpl>
  get copyWith =>
      __$$ApplicationHttpResponseImplCopyWithImpl<
        _$ApplicationHttpResponseImpl
      >(this, _$identity);
}

abstract class _ApplicationHttpResponse implements ApplicationHttpResponse {
  const factory _ApplicationHttpResponse({
    required final int statusCode,
    required final String body,
  }) = _$ApplicationHttpResponseImpl;

  @override
  int get statusCode;
  @override
  String get body;

  /// Create a copy of ApplicationHttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApplicationHttpResponseImplCopyWith<_$ApplicationHttpResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}
