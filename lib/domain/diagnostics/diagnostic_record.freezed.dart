// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diagnostic_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DiagnosticRecord {
  DateTime get time => throw _privateConstructorUsedError;
  DiagnosticSeverity get severity => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;
  Map<String, String> get metadata => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get stackTrace => throw _privateConstructorUsedError;
  DiagnosticRuntimeInfo get runtime => throw _privateConstructorUsedError;

  /// Create a copy of DiagnosticRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiagnosticRecordCopyWith<DiagnosticRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiagnosticRecordCopyWith<$Res> {
  factory $DiagnosticRecordCopyWith(
    DiagnosticRecord value,
    $Res Function(DiagnosticRecord) then,
  ) = _$DiagnosticRecordCopyWithImpl<$Res, DiagnosticRecord>;
  @useResult
  $Res call({
    DateTime time,
    DiagnosticSeverity severity,
    String message,
    String category,
    String? source,
    Map<String, String> metadata,
    String? error,
    String? stackTrace,
    DiagnosticRuntimeInfo runtime,
  });
}

/// @nodoc
class _$DiagnosticRecordCopyWithImpl<$Res, $Val extends DiagnosticRecord>
    implements $DiagnosticRecordCopyWith<$Res> {
  _$DiagnosticRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiagnosticRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? time = null,
    Object? severity = null,
    Object? message = null,
    Object? category = null,
    Object? source = freezed,
    Object? metadata = null,
    Object? error = freezed,
    Object? stackTrace = freezed,
    Object? runtime = null,
  }) {
    return _then(
      _value.copyWith(
            time: null == time
                ? _value.time
                : time // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            severity: null == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as DiagnosticSeverity,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            source: freezed == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata: null == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            stackTrace: freezed == stackTrace
                ? _value.stackTrace
                : stackTrace // ignore: cast_nullable_to_non_nullable
                      as String?,
            runtime: null == runtime
                ? _value.runtime
                : runtime // ignore: cast_nullable_to_non_nullable
                      as DiagnosticRuntimeInfo,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DiagnosticRecordImplCopyWith<$Res>
    implements $DiagnosticRecordCopyWith<$Res> {
  factory _$$DiagnosticRecordImplCopyWith(
    _$DiagnosticRecordImpl value,
    $Res Function(_$DiagnosticRecordImpl) then,
  ) = __$$DiagnosticRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DateTime time,
    DiagnosticSeverity severity,
    String message,
    String category,
    String? source,
    Map<String, String> metadata,
    String? error,
    String? stackTrace,
    DiagnosticRuntimeInfo runtime,
  });
}

/// @nodoc
class __$$DiagnosticRecordImplCopyWithImpl<$Res>
    extends _$DiagnosticRecordCopyWithImpl<$Res, _$DiagnosticRecordImpl>
    implements _$$DiagnosticRecordImplCopyWith<$Res> {
  __$$DiagnosticRecordImplCopyWithImpl(
    _$DiagnosticRecordImpl _value,
    $Res Function(_$DiagnosticRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DiagnosticRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? time = null,
    Object? severity = null,
    Object? message = null,
    Object? category = null,
    Object? source = freezed,
    Object? metadata = null,
    Object? error = freezed,
    Object? stackTrace = freezed,
    Object? runtime = null,
  }) {
    return _then(
      _$DiagnosticRecordImpl(
        time: null == time
            ? _value.time
            : time // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        severity: null == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as DiagnosticSeverity,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        source: freezed == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata: null == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        stackTrace: freezed == stackTrace
            ? _value.stackTrace
            : stackTrace // ignore: cast_nullable_to_non_nullable
                  as String?,
        runtime: null == runtime
            ? _value.runtime
            : runtime // ignore: cast_nullable_to_non_nullable
                  as DiagnosticRuntimeInfo,
      ),
    );
  }
}

/// @nodoc

class _$DiagnosticRecordImpl extends _DiagnosticRecord {
  _$DiagnosticRecordImpl({
    required this.time,
    required this.severity,
    required this.message,
    required this.category,
    this.source,
    required final Map<String, String> metadata,
    this.error,
    this.stackTrace,
    required this.runtime,
  }) : _metadata = metadata,
       super._();

  @override
  final DateTime time;
  @override
  final DiagnosticSeverity severity;
  @override
  final String message;
  @override
  final String category;
  @override
  final String? source;
  final Map<String, String> _metadata;
  @override
  Map<String, String> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  final String? error;
  @override
  final String? stackTrace;
  @override
  final DiagnosticRuntimeInfo runtime;

  @override
  String toString() {
    return 'DiagnosticRecord._create(time: $time, severity: $severity, message: $message, category: $category, source: $source, metadata: $metadata, error: $error, stackTrace: $stackTrace, runtime: $runtime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiagnosticRecordImpl &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.source, source) || other.source == source) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.stackTrace, stackTrace) ||
                other.stackTrace == stackTrace) &&
            (identical(other.runtime, runtime) || other.runtime == runtime));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    time,
    severity,
    message,
    category,
    source,
    const DeepCollectionEquality().hash(_metadata),
    error,
    stackTrace,
    runtime,
  );

  /// Create a copy of DiagnosticRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiagnosticRecordImplCopyWith<_$DiagnosticRecordImpl> get copyWith =>
      __$$DiagnosticRecordImplCopyWithImpl<_$DiagnosticRecordImpl>(
        this,
        _$identity,
      );
}

abstract class _DiagnosticRecord extends DiagnosticRecord {
  factory _DiagnosticRecord({
    required final DateTime time,
    required final DiagnosticSeverity severity,
    required final String message,
    required final String category,
    final String? source,
    required final Map<String, String> metadata,
    final String? error,
    final String? stackTrace,
    required final DiagnosticRuntimeInfo runtime,
  }) = _$DiagnosticRecordImpl;
  _DiagnosticRecord._() : super._();

  @override
  DateTime get time;
  @override
  DiagnosticSeverity get severity;
  @override
  String get message;
  @override
  String get category;
  @override
  String? get source;
  @override
  Map<String, String> get metadata;
  @override
  String? get error;
  @override
  String? get stackTrace;
  @override
  DiagnosticRuntimeInfo get runtime;

  /// Create a copy of DiagnosticRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiagnosticRecordImplCopyWith<_$DiagnosticRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
