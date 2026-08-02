// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'source_verification_browser_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SourceVerificationBrowserRequest {
  String get sourceKey => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get html => throw _privateConstructorUsedError;
  Map<String, String> get headers => throw _privateConstructorUsedError;
  bool get refetchAfterSuccess => throw _privateConstructorUsedError;

  /// Create a copy of SourceVerificationBrowserRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SourceVerificationBrowserRequestCopyWith<SourceVerificationBrowserRequest>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SourceVerificationBrowserRequestCopyWith<$Res> {
  factory $SourceVerificationBrowserRequestCopyWith(
    SourceVerificationBrowserRequest value,
    $Res Function(SourceVerificationBrowserRequest) then,
  ) =
      _$SourceVerificationBrowserRequestCopyWithImpl<
        $Res,
        SourceVerificationBrowserRequest
      >;
  @useResult
  $Res call({
    String sourceKey,
    String url,
    String title,
    String? html,
    Map<String, String> headers,
    bool refetchAfterSuccess,
  });
}

/// @nodoc
class _$SourceVerificationBrowserRequestCopyWithImpl<
  $Res,
  $Val extends SourceVerificationBrowserRequest
>
    implements $SourceVerificationBrowserRequestCopyWith<$Res> {
  _$SourceVerificationBrowserRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SourceVerificationBrowserRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceKey = null,
    Object? url = null,
    Object? title = null,
    Object? html = freezed,
    Object? headers = null,
    Object? refetchAfterSuccess = null,
  }) {
    return _then(
      _value.copyWith(
            sourceKey: null == sourceKey
                ? _value.sourceKey
                : sourceKey // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            html: freezed == html
                ? _value.html
                : html // ignore: cast_nullable_to_non_nullable
                      as String?,
            headers: null == headers
                ? _value.headers
                : headers // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            refetchAfterSuccess: null == refetchAfterSuccess
                ? _value.refetchAfterSuccess
                : refetchAfterSuccess // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SourceVerificationBrowserRequestImplCopyWith<$Res>
    implements $SourceVerificationBrowserRequestCopyWith<$Res> {
  factory _$$SourceVerificationBrowserRequestImplCopyWith(
    _$SourceVerificationBrowserRequestImpl value,
    $Res Function(_$SourceVerificationBrowserRequestImpl) then,
  ) = __$$SourceVerificationBrowserRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String sourceKey,
    String url,
    String title,
    String? html,
    Map<String, String> headers,
    bool refetchAfterSuccess,
  });
}

/// @nodoc
class __$$SourceVerificationBrowserRequestImplCopyWithImpl<$Res>
    extends
        _$SourceVerificationBrowserRequestCopyWithImpl<
          $Res,
          _$SourceVerificationBrowserRequestImpl
        >
    implements _$$SourceVerificationBrowserRequestImplCopyWith<$Res> {
  __$$SourceVerificationBrowserRequestImplCopyWithImpl(
    _$SourceVerificationBrowserRequestImpl _value,
    $Res Function(_$SourceVerificationBrowserRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SourceVerificationBrowserRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceKey = null,
    Object? url = null,
    Object? title = null,
    Object? html = freezed,
    Object? headers = null,
    Object? refetchAfterSuccess = null,
  }) {
    return _then(
      _$SourceVerificationBrowserRequestImpl(
        sourceKey: null == sourceKey
            ? _value.sourceKey
            : sourceKey // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        html: freezed == html
            ? _value.html
            : html // ignore: cast_nullable_to_non_nullable
                  as String?,
        headers: null == headers
            ? _value._headers
            : headers // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        refetchAfterSuccess: null == refetchAfterSuccess
            ? _value.refetchAfterSuccess
            : refetchAfterSuccess // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$SourceVerificationBrowserRequestImpl
    implements _SourceVerificationBrowserRequest {
  const _$SourceVerificationBrowserRequestImpl({
    required this.sourceKey,
    required this.url,
    required this.title,
    required this.html,
    required final Map<String, String> headers,
    required this.refetchAfterSuccess,
  }) : _headers = headers;

  @override
  final String sourceKey;
  @override
  final String url;
  @override
  final String title;
  @override
  final String? html;
  final Map<String, String> _headers;
  @override
  Map<String, String> get headers {
    if (_headers is EqualUnmodifiableMapView) return _headers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_headers);
  }

  @override
  final bool refetchAfterSuccess;

  @override
  String toString() {
    return 'SourceVerificationBrowserRequest(sourceKey: $sourceKey, url: $url, title: $title, html: $html, headers: $headers, refetchAfterSuccess: $refetchAfterSuccess)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SourceVerificationBrowserRequestImpl &&
            (identical(other.sourceKey, sourceKey) ||
                other.sourceKey == sourceKey) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.html, html) || other.html == html) &&
            const DeepCollectionEquality().equals(other._headers, _headers) &&
            (identical(other.refetchAfterSuccess, refetchAfterSuccess) ||
                other.refetchAfterSuccess == refetchAfterSuccess));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    sourceKey,
    url,
    title,
    html,
    const DeepCollectionEquality().hash(_headers),
    refetchAfterSuccess,
  );

  /// Create a copy of SourceVerificationBrowserRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SourceVerificationBrowserRequestImplCopyWith<
    _$SourceVerificationBrowserRequestImpl
  >
  get copyWith =>
      __$$SourceVerificationBrowserRequestImplCopyWithImpl<
        _$SourceVerificationBrowserRequestImpl
      >(this, _$identity);
}

abstract class _SourceVerificationBrowserRequest
    implements SourceVerificationBrowserRequest {
  const factory _SourceVerificationBrowserRequest({
    required final String sourceKey,
    required final String url,
    required final String title,
    required final String? html,
    required final Map<String, String> headers,
    required final bool refetchAfterSuccess,
  }) = _$SourceVerificationBrowserRequestImpl;

  @override
  String get sourceKey;
  @override
  String get url;
  @override
  String get title;
  @override
  String? get html;
  @override
  Map<String, String> get headers;
  @override
  bool get refetchAfterSuccess;

  /// Create a copy of SourceVerificationBrowserRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SourceVerificationBrowserRequestImplCopyWith<
    _$SourceVerificationBrowserRequestImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SourceVerificationBrowserResult {
  String get finalUrl => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;

  /// Create a copy of SourceVerificationBrowserResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SourceVerificationBrowserResultCopyWith<SourceVerificationBrowserResult>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SourceVerificationBrowserResultCopyWith<$Res> {
  factory $SourceVerificationBrowserResultCopyWith(
    SourceVerificationBrowserResult value,
    $Res Function(SourceVerificationBrowserResult) then,
  ) =
      _$SourceVerificationBrowserResultCopyWithImpl<
        $Res,
        SourceVerificationBrowserResult
      >;
  @useResult
  $Res call({String finalUrl, String body});
}

/// @nodoc
class _$SourceVerificationBrowserResultCopyWithImpl<
  $Res,
  $Val extends SourceVerificationBrowserResult
>
    implements $SourceVerificationBrowserResultCopyWith<$Res> {
  _$SourceVerificationBrowserResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SourceVerificationBrowserResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? finalUrl = null, Object? body = null}) {
    return _then(
      _value.copyWith(
            finalUrl: null == finalUrl
                ? _value.finalUrl
                : finalUrl // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$SourceVerificationBrowserResultImplCopyWith<$Res>
    implements $SourceVerificationBrowserResultCopyWith<$Res> {
  factory _$$SourceVerificationBrowserResultImplCopyWith(
    _$SourceVerificationBrowserResultImpl value,
    $Res Function(_$SourceVerificationBrowserResultImpl) then,
  ) = __$$SourceVerificationBrowserResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String finalUrl, String body});
}

/// @nodoc
class __$$SourceVerificationBrowserResultImplCopyWithImpl<$Res>
    extends
        _$SourceVerificationBrowserResultCopyWithImpl<
          $Res,
          _$SourceVerificationBrowserResultImpl
        >
    implements _$$SourceVerificationBrowserResultImplCopyWith<$Res> {
  __$$SourceVerificationBrowserResultImplCopyWithImpl(
    _$SourceVerificationBrowserResultImpl _value,
    $Res Function(_$SourceVerificationBrowserResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SourceVerificationBrowserResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? finalUrl = null, Object? body = null}) {
    return _then(
      _$SourceVerificationBrowserResultImpl(
        finalUrl: null == finalUrl
            ? _value.finalUrl
            : finalUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SourceVerificationBrowserResultImpl
    implements _SourceVerificationBrowserResult {
  const _$SourceVerificationBrowserResultImpl({
    required this.finalUrl,
    required this.body,
  });

  @override
  final String finalUrl;
  @override
  final String body;

  @override
  String toString() {
    return 'SourceVerificationBrowserResult(finalUrl: $finalUrl, body: $body)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SourceVerificationBrowserResultImpl &&
            (identical(other.finalUrl, finalUrl) ||
                other.finalUrl == finalUrl) &&
            (identical(other.body, body) || other.body == body));
  }

  @override
  int get hashCode => Object.hash(runtimeType, finalUrl, body);

  /// Create a copy of SourceVerificationBrowserResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SourceVerificationBrowserResultImplCopyWith<
    _$SourceVerificationBrowserResultImpl
  >
  get copyWith =>
      __$$SourceVerificationBrowserResultImplCopyWithImpl<
        _$SourceVerificationBrowserResultImpl
      >(this, _$identity);
}

abstract class _SourceVerificationBrowserResult
    implements SourceVerificationBrowserResult {
  const factory _SourceVerificationBrowserResult({
    required final String finalUrl,
    required final String body,
  }) = _$SourceVerificationBrowserResultImpl;

  @override
  String get finalUrl;
  @override
  String get body;

  /// Create a copy of SourceVerificationBrowserResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SourceVerificationBrowserResultImplCopyWith<
    _$SourceVerificationBrowserResultImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}
