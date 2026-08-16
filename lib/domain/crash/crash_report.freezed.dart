// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'crash_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CrashReport {
  DateTime get occurredAt => throw _privateConstructorUsedError;
  CrashOrigin get origin => throw _privateConstructorUsedError;
  String get startupStage => throw _privateConstructorUsedError;
  String get error => throw _privateConstructorUsedError;
  String get stackTrace => throw _privateConstructorUsedError;
  CrashRuntimeMetadata get metadata => throw _privateConstructorUsedError;

  /// Create a copy of CrashReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CrashReportCopyWith<CrashReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CrashReportCopyWith<$Res> {
  factory $CrashReportCopyWith(
    CrashReport value,
    $Res Function(CrashReport) then,
  ) = _$CrashReportCopyWithImpl<$Res, CrashReport>;
  @useResult
  $Res call({
    DateTime occurredAt,
    CrashOrigin origin,
    String startupStage,
    String error,
    String stackTrace,
    CrashRuntimeMetadata metadata,
  });
}

/// @nodoc
class _$CrashReportCopyWithImpl<$Res, $Val extends CrashReport>
    implements $CrashReportCopyWith<$Res> {
  _$CrashReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CrashReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? occurredAt = null,
    Object? origin = null,
    Object? startupStage = null,
    Object? error = null,
    Object? stackTrace = null,
    Object? metadata = null,
  }) {
    return _then(
      _value.copyWith(
            occurredAt: null == occurredAt
                ? _value.occurredAt
                : occurredAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            origin: null == origin
                ? _value.origin
                : origin // ignore: cast_nullable_to_non_nullable
                      as CrashOrigin,
            startupStage: null == startupStage
                ? _value.startupStage
                : startupStage // ignore: cast_nullable_to_non_nullable
                      as String,
            error: null == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String,
            stackTrace: null == stackTrace
                ? _value.stackTrace
                : stackTrace // ignore: cast_nullable_to_non_nullable
                      as String,
            metadata: null == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as CrashRuntimeMetadata,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CrashReportImplCopyWith<$Res>
    implements $CrashReportCopyWith<$Res> {
  factory _$$CrashReportImplCopyWith(
    _$CrashReportImpl value,
    $Res Function(_$CrashReportImpl) then,
  ) = __$$CrashReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DateTime occurredAt,
    CrashOrigin origin,
    String startupStage,
    String error,
    String stackTrace,
    CrashRuntimeMetadata metadata,
  });
}

/// @nodoc
class __$$CrashReportImplCopyWithImpl<$Res>
    extends _$CrashReportCopyWithImpl<$Res, _$CrashReportImpl>
    implements _$$CrashReportImplCopyWith<$Res> {
  __$$CrashReportImplCopyWithImpl(
    _$CrashReportImpl _value,
    $Res Function(_$CrashReportImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CrashReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? occurredAt = null,
    Object? origin = null,
    Object? startupStage = null,
    Object? error = null,
    Object? stackTrace = null,
    Object? metadata = null,
  }) {
    return _then(
      _$CrashReportImpl(
        occurredAt: null == occurredAt
            ? _value.occurredAt
            : occurredAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        origin: null == origin
            ? _value.origin
            : origin // ignore: cast_nullable_to_non_nullable
                  as CrashOrigin,
        startupStage: null == startupStage
            ? _value.startupStage
            : startupStage // ignore: cast_nullable_to_non_nullable
                  as String,
        error: null == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String,
        stackTrace: null == stackTrace
            ? _value.stackTrace
            : stackTrace // ignore: cast_nullable_to_non_nullable
                  as String,
        metadata: null == metadata
            ? _value.metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as CrashRuntimeMetadata,
      ),
    );
  }
}

/// @nodoc

class _$CrashReportImpl extends _CrashReport {
  const _$CrashReportImpl({
    required this.occurredAt,
    required this.origin,
    required this.startupStage,
    required this.error,
    required this.stackTrace,
    required this.metadata,
  }) : super._();

  @override
  final DateTime occurredAt;
  @override
  final CrashOrigin origin;
  @override
  final String startupStage;
  @override
  final String error;
  @override
  final String stackTrace;
  @override
  final CrashRuntimeMetadata metadata;

  @override
  String toString() {
    return 'CrashReport(occurredAt: $occurredAt, origin: $origin, startupStage: $startupStage, error: $error, stackTrace: $stackTrace, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CrashReportImpl &&
            (identical(other.occurredAt, occurredAt) ||
                other.occurredAt == occurredAt) &&
            (identical(other.origin, origin) || other.origin == origin) &&
            (identical(other.startupStage, startupStage) ||
                other.startupStage == startupStage) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.stackTrace, stackTrace) ||
                other.stackTrace == stackTrace) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    occurredAt,
    origin,
    startupStage,
    error,
    stackTrace,
    metadata,
  );

  /// Create a copy of CrashReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CrashReportImplCopyWith<_$CrashReportImpl> get copyWith =>
      __$$CrashReportImplCopyWithImpl<_$CrashReportImpl>(this, _$identity);
}

abstract class _CrashReport extends CrashReport {
  const factory _CrashReport({
    required final DateTime occurredAt,
    required final CrashOrigin origin,
    required final String startupStage,
    required final String error,
    required final String stackTrace,
    required final CrashRuntimeMetadata metadata,
  }) = _$CrashReportImpl;
  const _CrashReport._() : super._();

  @override
  DateTime get occurredAt;
  @override
  CrashOrigin get origin;
  @override
  String get startupStage;
  @override
  String get error;
  @override
  String get stackTrace;
  @override
  CrashRuntimeMetadata get metadata;

  /// Create a copy of CrashReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CrashReportImplCopyWith<_$CrashReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
