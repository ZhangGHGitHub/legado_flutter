// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'application_binary_http_request_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ApplicationBinaryHttpResponse {
  int get statusCode => throw _privateConstructorUsedError;
  String get contentType => throw _privateConstructorUsedError;
  Uint8List get body => throw _privateConstructorUsedError;

  /// Create a copy of ApplicationBinaryHttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApplicationBinaryHttpResponseCopyWith<ApplicationBinaryHttpResponse>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApplicationBinaryHttpResponseCopyWith<$Res> {
  factory $ApplicationBinaryHttpResponseCopyWith(
    ApplicationBinaryHttpResponse value,
    $Res Function(ApplicationBinaryHttpResponse) then,
  ) =
      _$ApplicationBinaryHttpResponseCopyWithImpl<
        $Res,
        ApplicationBinaryHttpResponse
      >;
  @useResult
  $Res call({int statusCode, String contentType, Uint8List body});
}

/// @nodoc
class _$ApplicationBinaryHttpResponseCopyWithImpl<
  $Res,
  $Val extends ApplicationBinaryHttpResponse
>
    implements $ApplicationBinaryHttpResponseCopyWith<$Res> {
  _$ApplicationBinaryHttpResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApplicationBinaryHttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statusCode = null,
    Object? contentType = null,
    Object? body = null,
  }) {
    return _then(
      _value.copyWith(
            statusCode: null == statusCode
                ? _value.statusCode
                : statusCode // ignore: cast_nullable_to_non_nullable
                      as int,
            contentType: null == contentType
                ? _value.contentType
                : contentType // ignore: cast_nullable_to_non_nullable
                      as String,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as Uint8List,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ApplicationBinaryHttpResponseImplCopyWith<$Res>
    implements $ApplicationBinaryHttpResponseCopyWith<$Res> {
  factory _$$ApplicationBinaryHttpResponseImplCopyWith(
    _$ApplicationBinaryHttpResponseImpl value,
    $Res Function(_$ApplicationBinaryHttpResponseImpl) then,
  ) = __$$ApplicationBinaryHttpResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int statusCode, String contentType, Uint8List body});
}

/// @nodoc
class __$$ApplicationBinaryHttpResponseImplCopyWithImpl<$Res>
    extends
        _$ApplicationBinaryHttpResponseCopyWithImpl<
          $Res,
          _$ApplicationBinaryHttpResponseImpl
        >
    implements _$$ApplicationBinaryHttpResponseImplCopyWith<$Res> {
  __$$ApplicationBinaryHttpResponseImplCopyWithImpl(
    _$ApplicationBinaryHttpResponseImpl _value,
    $Res Function(_$ApplicationBinaryHttpResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApplicationBinaryHttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statusCode = null,
    Object? contentType = null,
    Object? body = null,
  }) {
    return _then(
      _$ApplicationBinaryHttpResponseImpl(
        statusCode: null == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int,
        contentType: null == contentType
            ? _value.contentType
            : contentType // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as Uint8List,
      ),
    );
  }
}

/// @nodoc

class _$ApplicationBinaryHttpResponseImpl
    implements _ApplicationBinaryHttpResponse {
  const _$ApplicationBinaryHttpResponseImpl({
    required this.statusCode,
    required this.contentType,
    required this.body,
  });

  @override
  final int statusCode;
  @override
  final String contentType;
  @override
  final Uint8List body;

  @override
  String toString() {
    return 'ApplicationBinaryHttpResponse(statusCode: $statusCode, contentType: $contentType, body: $body)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApplicationBinaryHttpResponseImpl &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType) &&
            const DeepCollectionEquality().equals(other.body, body));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    statusCode,
    contentType,
    const DeepCollectionEquality().hash(body),
  );

  /// Create a copy of ApplicationBinaryHttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApplicationBinaryHttpResponseImplCopyWith<
    _$ApplicationBinaryHttpResponseImpl
  >
  get copyWith =>
      __$$ApplicationBinaryHttpResponseImplCopyWithImpl<
        _$ApplicationBinaryHttpResponseImpl
      >(this, _$identity);
}

abstract class _ApplicationBinaryHttpResponse
    implements ApplicationBinaryHttpResponse {
  const factory _ApplicationBinaryHttpResponse({
    required final int statusCode,
    required final String contentType,
    required final Uint8List body,
  }) = _$ApplicationBinaryHttpResponseImpl;

  @override
  int get statusCode;
  @override
  String get contentType;
  @override
  Uint8List get body;

  /// Create a copy of ApplicationBinaryHttpResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApplicationBinaryHttpResponseImplCopyWith<
    _$ApplicationBinaryHttpResponseImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}
