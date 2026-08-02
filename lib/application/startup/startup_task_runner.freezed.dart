// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'startup_task_runner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$StartupTaskReport {
  String get id => throw _privateConstructorUsedError;
  StartupTaskStatus get status => throw _privateConstructorUsedError;
  int get attempt => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime? get finishedAt => throw _privateConstructorUsedError;
  Object? get error => throw _privateConstructorUsedError;
  StackTrace? get stackTrace => throw _privateConstructorUsedError;

  /// Create a copy of StartupTaskReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StartupTaskReportCopyWith<StartupTaskReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StartupTaskReportCopyWith<$Res> {
  factory $StartupTaskReportCopyWith(
    StartupTaskReport value,
    $Res Function(StartupTaskReport) then,
  ) = _$StartupTaskReportCopyWithImpl<$Res, StartupTaskReport>;
  @useResult
  $Res call({
    String id,
    StartupTaskStatus status,
    int attempt,
    DateTime startedAt,
    DateTime? finishedAt,
    Object? error,
    StackTrace? stackTrace,
  });
}

/// @nodoc
class _$StartupTaskReportCopyWithImpl<$Res, $Val extends StartupTaskReport>
    implements $StartupTaskReportCopyWith<$Res> {
  _$StartupTaskReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StartupTaskReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? attempt = null,
    Object? startedAt = null,
    Object? finishedAt = freezed,
    Object? error = freezed,
    Object? stackTrace = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as StartupTaskStatus,
            attempt: null == attempt
                ? _value.attempt
                : attempt // ignore: cast_nullable_to_non_nullable
                      as int,
            startedAt: null == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            finishedAt: freezed == finishedAt
                ? _value.finishedAt
                : finishedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            error: freezed == error ? _value.error : error,
            stackTrace: freezed == stackTrace
                ? _value.stackTrace
                : stackTrace // ignore: cast_nullable_to_non_nullable
                      as StackTrace?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StartupTaskReportImplCopyWith<$Res>
    implements $StartupTaskReportCopyWith<$Res> {
  factory _$$StartupTaskReportImplCopyWith(
    _$StartupTaskReportImpl value,
    $Res Function(_$StartupTaskReportImpl) then,
  ) = __$$StartupTaskReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    StartupTaskStatus status,
    int attempt,
    DateTime startedAt,
    DateTime? finishedAt,
    Object? error,
    StackTrace? stackTrace,
  });
}

/// @nodoc
class __$$StartupTaskReportImplCopyWithImpl<$Res>
    extends _$StartupTaskReportCopyWithImpl<$Res, _$StartupTaskReportImpl>
    implements _$$StartupTaskReportImplCopyWith<$Res> {
  __$$StartupTaskReportImplCopyWithImpl(
    _$StartupTaskReportImpl _value,
    $Res Function(_$StartupTaskReportImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StartupTaskReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? attempt = null,
    Object? startedAt = null,
    Object? finishedAt = freezed,
    Object? error = freezed,
    Object? stackTrace = freezed,
  }) {
    return _then(
      _$StartupTaskReportImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as StartupTaskStatus,
        attempt: null == attempt
            ? _value.attempt
            : attempt // ignore: cast_nullable_to_non_nullable
                  as int,
        startedAt: null == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        finishedAt: freezed == finishedAt
            ? _value.finishedAt
            : finishedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        error: freezed == error ? _value.error : error,
        stackTrace: freezed == stackTrace
            ? _value.stackTrace
            : stackTrace // ignore: cast_nullable_to_non_nullable
                  as StackTrace?,
      ),
    );
  }
}

/// @nodoc

class _$StartupTaskReportImpl extends _StartupTaskReport
    with DiagnosticableTreeMixin {
  const _$StartupTaskReportImpl({
    required this.id,
    required this.status,
    required this.attempt,
    required this.startedAt,
    this.finishedAt,
    this.error,
    this.stackTrace,
  }) : super._();

  @override
  final String id;
  @override
  final StartupTaskStatus status;
  @override
  final int attempt;
  @override
  final DateTime startedAt;
  @override
  final DateTime? finishedAt;
  @override
  final Object? error;
  @override
  final StackTrace? stackTrace;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'StartupTaskReport(id: $id, status: $status, attempt: $attempt, startedAt: $startedAt, finishedAt: $finishedAt, error: $error, stackTrace: $stackTrace)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'StartupTaskReport'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('attempt', attempt))
      ..add(DiagnosticsProperty('startedAt', startedAt))
      ..add(DiagnosticsProperty('finishedAt', finishedAt))
      ..add(DiagnosticsProperty('error', error))
      ..add(DiagnosticsProperty('stackTrace', stackTrace));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StartupTaskReportImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.attempt, attempt) || other.attempt == attempt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.finishedAt, finishedAt) ||
                other.finishedAt == finishedAt) &&
            const DeepCollectionEquality().equals(other.error, error) &&
            (identical(other.stackTrace, stackTrace) ||
                other.stackTrace == stackTrace));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    status,
    attempt,
    startedAt,
    finishedAt,
    const DeepCollectionEquality().hash(error),
    stackTrace,
  );

  /// Create a copy of StartupTaskReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StartupTaskReportImplCopyWith<_$StartupTaskReportImpl> get copyWith =>
      __$$StartupTaskReportImplCopyWithImpl<_$StartupTaskReportImpl>(
        this,
        _$identity,
      );
}

abstract class _StartupTaskReport extends StartupTaskReport {
  const factory _StartupTaskReport({
    required final String id,
    required final StartupTaskStatus status,
    required final int attempt,
    required final DateTime startedAt,
    final DateTime? finishedAt,
    final Object? error,
    final StackTrace? stackTrace,
  }) = _$StartupTaskReportImpl;
  const _StartupTaskReport._() : super._();

  @override
  String get id;
  @override
  StartupTaskStatus get status;
  @override
  int get attempt;
  @override
  DateTime get startedAt;
  @override
  DateTime? get finishedAt;
  @override
  Object? get error;
  @override
  StackTrace? get stackTrace;

  /// Create a copy of StartupTaskReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StartupTaskReportImplCopyWith<_$StartupTaskReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
