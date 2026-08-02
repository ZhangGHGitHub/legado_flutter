// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_reading_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BookReadingStats {
  int get readChars => throw _privateConstructorUsedError;
  int get durationSeconds => throw _privateConstructorUsedError;
  String? get startDate => throw _privateConstructorUsedError;
  String? get lastDate => throw _privateConstructorUsedError;
  int get readingDays => throw _privateConstructorUsedError;

  /// Create a copy of BookReadingStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookReadingStatsCopyWith<BookReadingStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookReadingStatsCopyWith<$Res> {
  factory $BookReadingStatsCopyWith(
    BookReadingStats value,
    $Res Function(BookReadingStats) then,
  ) = _$BookReadingStatsCopyWithImpl<$Res, BookReadingStats>;
  @useResult
  $Res call({
    int readChars,
    int durationSeconds,
    String? startDate,
    String? lastDate,
    int readingDays,
  });
}

/// @nodoc
class _$BookReadingStatsCopyWithImpl<$Res, $Val extends BookReadingStats>
    implements $BookReadingStatsCopyWith<$Res> {
  _$BookReadingStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookReadingStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? readChars = null,
    Object? durationSeconds = null,
    Object? startDate = freezed,
    Object? lastDate = freezed,
    Object? readingDays = null,
  }) {
    return _then(
      _value.copyWith(
            readChars: null == readChars
                ? _value.readChars
                : readChars // ignore: cast_nullable_to_non_nullable
                      as int,
            durationSeconds: null == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            startDate: freezed == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastDate: freezed == lastDate
                ? _value.lastDate
                : lastDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            readingDays: null == readingDays
                ? _value.readingDays
                : readingDays // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookReadingStatsImplCopyWith<$Res>
    implements $BookReadingStatsCopyWith<$Res> {
  factory _$$BookReadingStatsImplCopyWith(
    _$BookReadingStatsImpl value,
    $Res Function(_$BookReadingStatsImpl) then,
  ) = __$$BookReadingStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int readChars,
    int durationSeconds,
    String? startDate,
    String? lastDate,
    int readingDays,
  });
}

/// @nodoc
class __$$BookReadingStatsImplCopyWithImpl<$Res>
    extends _$BookReadingStatsCopyWithImpl<$Res, _$BookReadingStatsImpl>
    implements _$$BookReadingStatsImplCopyWith<$Res> {
  __$$BookReadingStatsImplCopyWithImpl(
    _$BookReadingStatsImpl _value,
    $Res Function(_$BookReadingStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookReadingStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? readChars = null,
    Object? durationSeconds = null,
    Object? startDate = freezed,
    Object? lastDate = freezed,
    Object? readingDays = null,
  }) {
    return _then(
      _$BookReadingStatsImpl(
        readChars: null == readChars
            ? _value.readChars
            : readChars // ignore: cast_nullable_to_non_nullable
                  as int,
        durationSeconds: null == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        startDate: freezed == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastDate: freezed == lastDate
            ? _value.lastDate
            : lastDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        readingDays: null == readingDays
            ? _value.readingDays
            : readingDays // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$BookReadingStatsImpl implements _BookReadingStats {
  const _$BookReadingStatsImpl({
    required this.readChars,
    required this.durationSeconds,
    required this.startDate,
    required this.lastDate,
    this.readingDays = 0,
  });

  @override
  final int readChars;
  @override
  final int durationSeconds;
  @override
  final String? startDate;
  @override
  final String? lastDate;
  @override
  @JsonKey()
  final int readingDays;

  @override
  String toString() {
    return 'BookReadingStats(readChars: $readChars, durationSeconds: $durationSeconds, startDate: $startDate, lastDate: $lastDate, readingDays: $readingDays)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookReadingStatsImpl &&
            (identical(other.readChars, readChars) ||
                other.readChars == readChars) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.lastDate, lastDate) ||
                other.lastDate == lastDate) &&
            (identical(other.readingDays, readingDays) ||
                other.readingDays == readingDays));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    readChars,
    durationSeconds,
    startDate,
    lastDate,
    readingDays,
  );

  /// Create a copy of BookReadingStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookReadingStatsImplCopyWith<_$BookReadingStatsImpl> get copyWith =>
      __$$BookReadingStatsImplCopyWithImpl<_$BookReadingStatsImpl>(
        this,
        _$identity,
      );
}

abstract class _BookReadingStats implements BookReadingStats {
  const factory _BookReadingStats({
    required final int readChars,
    required final int durationSeconds,
    required final String? startDate,
    required final String? lastDate,
    final int readingDays,
  }) = _$BookReadingStatsImpl;

  @override
  int get readChars;
  @override
  int get durationSeconds;
  @override
  String? get startDate;
  @override
  String? get lastDate;
  @override
  int get readingDays;

  /// Create a copy of BookReadingStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookReadingStatsImplCopyWith<_$BookReadingStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
