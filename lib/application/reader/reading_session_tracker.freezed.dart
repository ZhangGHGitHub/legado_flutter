// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_session_tracker.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ReadingSessionDelta {
  int get chars => throw _privateConstructorUsedError;
  int get durationSeconds => throw _privateConstructorUsedError;
  DateTime get endedAt => throw _privateConstructorUsedError;

  /// Create a copy of ReadingSessionDelta
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReadingSessionDeltaCopyWith<ReadingSessionDelta> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReadingSessionDeltaCopyWith<$Res> {
  factory $ReadingSessionDeltaCopyWith(
    ReadingSessionDelta value,
    $Res Function(ReadingSessionDelta) then,
  ) = _$ReadingSessionDeltaCopyWithImpl<$Res, ReadingSessionDelta>;
  @useResult
  $Res call({int chars, int durationSeconds, DateTime endedAt});
}

/// @nodoc
class _$ReadingSessionDeltaCopyWithImpl<$Res, $Val extends ReadingSessionDelta>
    implements $ReadingSessionDeltaCopyWith<$Res> {
  _$ReadingSessionDeltaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReadingSessionDelta
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chars = null,
    Object? durationSeconds = null,
    Object? endedAt = null,
  }) {
    return _then(
      _value.copyWith(
            chars: null == chars
                ? _value.chars
                : chars // ignore: cast_nullable_to_non_nullable
                      as int,
            durationSeconds: null == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            endedAt: null == endedAt
                ? _value.endedAt
                : endedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReadingSessionDeltaImplCopyWith<$Res>
    implements $ReadingSessionDeltaCopyWith<$Res> {
  factory _$$ReadingSessionDeltaImplCopyWith(
    _$ReadingSessionDeltaImpl value,
    $Res Function(_$ReadingSessionDeltaImpl) then,
  ) = __$$ReadingSessionDeltaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int chars, int durationSeconds, DateTime endedAt});
}

/// @nodoc
class __$$ReadingSessionDeltaImplCopyWithImpl<$Res>
    extends _$ReadingSessionDeltaCopyWithImpl<$Res, _$ReadingSessionDeltaImpl>
    implements _$$ReadingSessionDeltaImplCopyWith<$Res> {
  __$$ReadingSessionDeltaImplCopyWithImpl(
    _$ReadingSessionDeltaImpl _value,
    $Res Function(_$ReadingSessionDeltaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReadingSessionDelta
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chars = null,
    Object? durationSeconds = null,
    Object? endedAt = null,
  }) {
    return _then(
      _$ReadingSessionDeltaImpl(
        chars: null == chars
            ? _value.chars
            : chars // ignore: cast_nullable_to_non_nullable
                  as int,
        durationSeconds: null == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        endedAt: null == endedAt
            ? _value.endedAt
            : endedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$ReadingSessionDeltaImpl implements _ReadingSessionDelta {
  const _$ReadingSessionDeltaImpl({
    required this.chars,
    required this.durationSeconds,
    required this.endedAt,
  });

  @override
  final int chars;
  @override
  final int durationSeconds;
  @override
  final DateTime endedAt;

  @override
  String toString() {
    return 'ReadingSessionDelta(chars: $chars, durationSeconds: $durationSeconds, endedAt: $endedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadingSessionDeltaImpl &&
            (identical(other.chars, chars) || other.chars == chars) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chars, durationSeconds, endedAt);

  /// Create a copy of ReadingSessionDelta
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReadingSessionDeltaImplCopyWith<_$ReadingSessionDeltaImpl> get copyWith =>
      __$$ReadingSessionDeltaImplCopyWithImpl<_$ReadingSessionDeltaImpl>(
        this,
        _$identity,
      );
}

abstract class _ReadingSessionDelta implements ReadingSessionDelta {
  const factory _ReadingSessionDelta({
    required final int chars,
    required final int durationSeconds,
    required final DateTime endedAt,
  }) = _$ReadingSessionDeltaImpl;

  @override
  int get chars;
  @override
  int get durationSeconds;
  @override
  DateTime get endedAt;

  /// Create a copy of ReadingSessionDelta
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReadingSessionDeltaImplCopyWith<_$ReadingSessionDeltaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DetailedReadingSession {
  String get bookName => throw _privateConstructorUsedError;
  DateTime get startTime => throw _privateConstructorUsedError;
  DateTime get endTime => throw _privateConstructorUsedError;
  int get readIteration => throw _privateConstructorUsedError;

  /// Create a copy of DetailedReadingSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DetailedReadingSessionCopyWith<DetailedReadingSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetailedReadingSessionCopyWith<$Res> {
  factory $DetailedReadingSessionCopyWith(
    DetailedReadingSession value,
    $Res Function(DetailedReadingSession) then,
  ) = _$DetailedReadingSessionCopyWithImpl<$Res, DetailedReadingSession>;
  @useResult
  $Res call({
    String bookName,
    DateTime startTime,
    DateTime endTime,
    int readIteration,
  });
}

/// @nodoc
class _$DetailedReadingSessionCopyWithImpl<
  $Res,
  $Val extends DetailedReadingSession
>
    implements $DetailedReadingSessionCopyWith<$Res> {
  _$DetailedReadingSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DetailedReadingSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookName = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? readIteration = null,
  }) {
    return _then(
      _value.copyWith(
            bookName: null == bookName
                ? _value.bookName
                : bookName // ignore: cast_nullable_to_non_nullable
                      as String,
            startTime: null == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endTime: null == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            readIteration: null == readIteration
                ? _value.readIteration
                : readIteration // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DetailedReadingSessionImplCopyWith<$Res>
    implements $DetailedReadingSessionCopyWith<$Res> {
  factory _$$DetailedReadingSessionImplCopyWith(
    _$DetailedReadingSessionImpl value,
    $Res Function(_$DetailedReadingSessionImpl) then,
  ) = __$$DetailedReadingSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String bookName,
    DateTime startTime,
    DateTime endTime,
    int readIteration,
  });
}

/// @nodoc
class __$$DetailedReadingSessionImplCopyWithImpl<$Res>
    extends
        _$DetailedReadingSessionCopyWithImpl<$Res, _$DetailedReadingSessionImpl>
    implements _$$DetailedReadingSessionImplCopyWith<$Res> {
  __$$DetailedReadingSessionImplCopyWithImpl(
    _$DetailedReadingSessionImpl _value,
    $Res Function(_$DetailedReadingSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DetailedReadingSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookName = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? readIteration = null,
  }) {
    return _then(
      _$DetailedReadingSessionImpl(
        bookName: null == bookName
            ? _value.bookName
            : bookName // ignore: cast_nullable_to_non_nullable
                  as String,
        startTime: null == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endTime: null == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        readIteration: null == readIteration
            ? _value.readIteration
            : readIteration // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$DetailedReadingSessionImpl implements _DetailedReadingSession {
  const _$DetailedReadingSessionImpl({
    required this.bookName,
    required this.startTime,
    required this.endTime,
    required this.readIteration,
  });

  @override
  final String bookName;
  @override
  final DateTime startTime;
  @override
  final DateTime endTime;
  @override
  final int readIteration;

  @override
  String toString() {
    return 'DetailedReadingSession(bookName: $bookName, startTime: $startTime, endTime: $endTime, readIteration: $readIteration)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetailedReadingSessionImpl &&
            (identical(other.bookName, bookName) ||
                other.bookName == bookName) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.readIteration, readIteration) ||
                other.readIteration == readIteration));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, bookName, startTime, endTime, readIteration);

  /// Create a copy of DetailedReadingSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DetailedReadingSessionImplCopyWith<_$DetailedReadingSessionImpl>
  get copyWith =>
      __$$DetailedReadingSessionImplCopyWithImpl<_$DetailedReadingSessionImpl>(
        this,
        _$identity,
      );
}

abstract class _DetailedReadingSession implements DetailedReadingSession {
  const factory _DetailedReadingSession({
    required final String bookName,
    required final DateTime startTime,
    required final DateTime endTime,
    required final int readIteration,
  }) = _$DetailedReadingSessionImpl;

  @override
  String get bookName;
  @override
  DateTime get startTime;
  @override
  DateTime get endTime;
  @override
  int get readIteration;

  /// Create a copy of DetailedReadingSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DetailedReadingSessionImplCopyWith<_$DetailedReadingSessionImpl>
  get copyWith => throw _privateConstructorUsedError;
}
