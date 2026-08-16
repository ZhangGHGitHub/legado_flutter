// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DailyReadingStat {
  String get date => throw _privateConstructorUsedError;
  int get chars => throw _privateConstructorUsedError;
  int get durationSeconds => throw _privateConstructorUsedError;

  /// Create a copy of DailyReadingStat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailyReadingStatCopyWith<DailyReadingStat> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyReadingStatCopyWith<$Res> {
  factory $DailyReadingStatCopyWith(
    DailyReadingStat value,
    $Res Function(DailyReadingStat) then,
  ) = _$DailyReadingStatCopyWithImpl<$Res, DailyReadingStat>;
  @useResult
  $Res call({String date, int chars, int durationSeconds});
}

/// @nodoc
class _$DailyReadingStatCopyWithImpl<$Res, $Val extends DailyReadingStat>
    implements $DailyReadingStatCopyWith<$Res> {
  _$DailyReadingStatCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailyReadingStat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? chars = null,
    Object? durationSeconds = null,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            chars: null == chars
                ? _value.chars
                : chars // ignore: cast_nullable_to_non_nullable
                      as int,
            durationSeconds: null == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DailyReadingStatImplCopyWith<$Res>
    implements $DailyReadingStatCopyWith<$Res> {
  factory _$$DailyReadingStatImplCopyWith(
    _$DailyReadingStatImpl value,
    $Res Function(_$DailyReadingStatImpl) then,
  ) = __$$DailyReadingStatImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String date, int chars, int durationSeconds});
}

/// @nodoc
class __$$DailyReadingStatImplCopyWithImpl<$Res>
    extends _$DailyReadingStatCopyWithImpl<$Res, _$DailyReadingStatImpl>
    implements _$$DailyReadingStatImplCopyWith<$Res> {
  __$$DailyReadingStatImplCopyWithImpl(
    _$DailyReadingStatImpl _value,
    $Res Function(_$DailyReadingStatImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DailyReadingStat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? chars = null,
    Object? durationSeconds = null,
  }) {
    return _then(
      _$DailyReadingStatImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        chars: null == chars
            ? _value.chars
            : chars // ignore: cast_nullable_to_non_nullable
                  as int,
        durationSeconds: null == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$DailyReadingStatImpl implements _DailyReadingStat {
  const _$DailyReadingStatImpl({
    required this.date,
    required this.chars,
    required this.durationSeconds,
  });

  @override
  final String date;
  @override
  final int chars;
  @override
  final int durationSeconds;

  @override
  String toString() {
    return 'DailyReadingStat(date: $date, chars: $chars, durationSeconds: $durationSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyReadingStatImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.chars, chars) || other.chars == chars) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds));
  }

  @override
  int get hashCode => Object.hash(runtimeType, date, chars, durationSeconds);

  /// Create a copy of DailyReadingStat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyReadingStatImplCopyWith<_$DailyReadingStatImpl> get copyWith =>
      __$$DailyReadingStatImplCopyWithImpl<_$DailyReadingStatImpl>(
        this,
        _$identity,
      );
}

abstract class _DailyReadingStat implements DailyReadingStat {
  const factory _DailyReadingStat({
    required final String date,
    required final int chars,
    required final int durationSeconds,
  }) = _$DailyReadingStatImpl;

  @override
  String get date;
  @override
  int get chars;
  @override
  int get durationSeconds;

  /// Create a copy of DailyReadingStat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyReadingStatImplCopyWith<_$DailyReadingStatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ReadingStats {
  int get totalChars => throw _privateConstructorUsedError;
  int get totalDurationSeconds => throw _privateConstructorUsedError;
  int get todayChars => throw _privateConstructorUsedError;
  int get todayDurationSeconds => throw _privateConstructorUsedError;
  int get weekChars => throw _privateConstructorUsedError;
  List<DailyReadingStat> get daily => throw _privateConstructorUsedError;

  /// Create a copy of ReadingStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReadingStatsCopyWith<ReadingStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReadingStatsCopyWith<$Res> {
  factory $ReadingStatsCopyWith(
    ReadingStats value,
    $Res Function(ReadingStats) then,
  ) = _$ReadingStatsCopyWithImpl<$Res, ReadingStats>;
  @useResult
  $Res call({
    int totalChars,
    int totalDurationSeconds,
    int todayChars,
    int todayDurationSeconds,
    int weekChars,
    List<DailyReadingStat> daily,
  });
}

/// @nodoc
class _$ReadingStatsCopyWithImpl<$Res, $Val extends ReadingStats>
    implements $ReadingStatsCopyWith<$Res> {
  _$ReadingStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReadingStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalChars = null,
    Object? totalDurationSeconds = null,
    Object? todayChars = null,
    Object? todayDurationSeconds = null,
    Object? weekChars = null,
    Object? daily = null,
  }) {
    return _then(
      _value.copyWith(
            totalChars: null == totalChars
                ? _value.totalChars
                : totalChars // ignore: cast_nullable_to_non_nullable
                      as int,
            totalDurationSeconds: null == totalDurationSeconds
                ? _value.totalDurationSeconds
                : totalDurationSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            todayChars: null == todayChars
                ? _value.todayChars
                : todayChars // ignore: cast_nullable_to_non_nullable
                      as int,
            todayDurationSeconds: null == todayDurationSeconds
                ? _value.todayDurationSeconds
                : todayDurationSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            weekChars: null == weekChars
                ? _value.weekChars
                : weekChars // ignore: cast_nullable_to_non_nullable
                      as int,
            daily: null == daily
                ? _value.daily
                : daily // ignore: cast_nullable_to_non_nullable
                      as List<DailyReadingStat>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReadingStatsImplCopyWith<$Res>
    implements $ReadingStatsCopyWith<$Res> {
  factory _$$ReadingStatsImplCopyWith(
    _$ReadingStatsImpl value,
    $Res Function(_$ReadingStatsImpl) then,
  ) = __$$ReadingStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalChars,
    int totalDurationSeconds,
    int todayChars,
    int todayDurationSeconds,
    int weekChars,
    List<DailyReadingStat> daily,
  });
}

/// @nodoc
class __$$ReadingStatsImplCopyWithImpl<$Res>
    extends _$ReadingStatsCopyWithImpl<$Res, _$ReadingStatsImpl>
    implements _$$ReadingStatsImplCopyWith<$Res> {
  __$$ReadingStatsImplCopyWithImpl(
    _$ReadingStatsImpl _value,
    $Res Function(_$ReadingStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReadingStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalChars = null,
    Object? totalDurationSeconds = null,
    Object? todayChars = null,
    Object? todayDurationSeconds = null,
    Object? weekChars = null,
    Object? daily = null,
  }) {
    return _then(
      _$ReadingStatsImpl(
        totalChars: null == totalChars
            ? _value.totalChars
            : totalChars // ignore: cast_nullable_to_non_nullable
                  as int,
        totalDurationSeconds: null == totalDurationSeconds
            ? _value.totalDurationSeconds
            : totalDurationSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        todayChars: null == todayChars
            ? _value.todayChars
            : todayChars // ignore: cast_nullable_to_non_nullable
                  as int,
        todayDurationSeconds: null == todayDurationSeconds
            ? _value.todayDurationSeconds
            : todayDurationSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        weekChars: null == weekChars
            ? _value.weekChars
            : weekChars // ignore: cast_nullable_to_non_nullable
                  as int,
        daily: null == daily
            ? _value._daily
            : daily // ignore: cast_nullable_to_non_nullable
                  as List<DailyReadingStat>,
      ),
    );
  }
}

/// @nodoc

class _$ReadingStatsImpl implements _ReadingStats {
  const _$ReadingStatsImpl({
    required this.totalChars,
    required this.totalDurationSeconds,
    required this.todayChars,
    required this.todayDurationSeconds,
    required this.weekChars,
    required final List<DailyReadingStat> daily,
  }) : _daily = daily;

  @override
  final int totalChars;
  @override
  final int totalDurationSeconds;
  @override
  final int todayChars;
  @override
  final int todayDurationSeconds;
  @override
  final int weekChars;
  final List<DailyReadingStat> _daily;
  @override
  List<DailyReadingStat> get daily {
    if (_daily is EqualUnmodifiableListView) return _daily;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_daily);
  }

  @override
  String toString() {
    return 'ReadingStats(totalChars: $totalChars, totalDurationSeconds: $totalDurationSeconds, todayChars: $todayChars, todayDurationSeconds: $todayDurationSeconds, weekChars: $weekChars, daily: $daily)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadingStatsImpl &&
            (identical(other.totalChars, totalChars) ||
                other.totalChars == totalChars) &&
            (identical(other.totalDurationSeconds, totalDurationSeconds) ||
                other.totalDurationSeconds == totalDurationSeconds) &&
            (identical(other.todayChars, todayChars) ||
                other.todayChars == todayChars) &&
            (identical(other.todayDurationSeconds, todayDurationSeconds) ||
                other.todayDurationSeconds == todayDurationSeconds) &&
            (identical(other.weekChars, weekChars) ||
                other.weekChars == weekChars) &&
            const DeepCollectionEquality().equals(other._daily, _daily));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalChars,
    totalDurationSeconds,
    todayChars,
    todayDurationSeconds,
    weekChars,
    const DeepCollectionEquality().hash(_daily),
  );

  /// Create a copy of ReadingStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReadingStatsImplCopyWith<_$ReadingStatsImpl> get copyWith =>
      __$$ReadingStatsImplCopyWithImpl<_$ReadingStatsImpl>(this, _$identity);
}

abstract class _ReadingStats implements ReadingStats {
  const factory _ReadingStats({
    required final int totalChars,
    required final int totalDurationSeconds,
    required final int todayChars,
    required final int todayDurationSeconds,
    required final int weekChars,
    required final List<DailyReadingStat> daily,
  }) = _$ReadingStatsImpl;

  @override
  int get totalChars;
  @override
  int get totalDurationSeconds;
  @override
  int get todayChars;
  @override
  int get todayDurationSeconds;
  @override
  int get weekChars;
  @override
  List<DailyReadingStat> get daily;

  /// Create a copy of ReadingStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReadingStatsImplCopyWith<_$ReadingStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
