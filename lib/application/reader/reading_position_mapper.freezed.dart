// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_position_mapper.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ReadingPageRange {
  String get text => throw _privateConstructorUsedError;
  int get start => throw _privateConstructorUsedError;
  int get end => throw _privateConstructorUsedError;

  /// Create a copy of ReadingPageRange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReadingPageRangeCopyWith<ReadingPageRange> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReadingPageRangeCopyWith<$Res> {
  factory $ReadingPageRangeCopyWith(
    ReadingPageRange value,
    $Res Function(ReadingPageRange) then,
  ) = _$ReadingPageRangeCopyWithImpl<$Res, ReadingPageRange>;
  @useResult
  $Res call({String text, int start, int end});
}

/// @nodoc
class _$ReadingPageRangeCopyWithImpl<$Res, $Val extends ReadingPageRange>
    implements $ReadingPageRangeCopyWith<$Res> {
  _$ReadingPageRangeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReadingPageRange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? text = null, Object? start = null, Object? end = null}) {
    return _then(
      _value.copyWith(
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            start: null == start
                ? _value.start
                : start // ignore: cast_nullable_to_non_nullable
                      as int,
            end: null == end
                ? _value.end
                : end // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReadingPageRangeImplCopyWith<$Res>
    implements $ReadingPageRangeCopyWith<$Res> {
  factory _$$ReadingPageRangeImplCopyWith(
    _$ReadingPageRangeImpl value,
    $Res Function(_$ReadingPageRangeImpl) then,
  ) = __$$ReadingPageRangeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String text, int start, int end});
}

/// @nodoc
class __$$ReadingPageRangeImplCopyWithImpl<$Res>
    extends _$ReadingPageRangeCopyWithImpl<$Res, _$ReadingPageRangeImpl>
    implements _$$ReadingPageRangeImplCopyWith<$Res> {
  __$$ReadingPageRangeImplCopyWithImpl(
    _$ReadingPageRangeImpl _value,
    $Res Function(_$ReadingPageRangeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReadingPageRange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? text = null, Object? start = null, Object? end = null}) {
    return _then(
      _$ReadingPageRangeImpl(
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        start: null == start
            ? _value.start
            : start // ignore: cast_nullable_to_non_nullable
                  as int,
        end: null == end
            ? _value.end
            : end // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ReadingPageRangeImpl implements _ReadingPageRange {
  const _$ReadingPageRangeImpl({
    required this.text,
    required this.start,
    required this.end,
  });

  @override
  final String text;
  @override
  final int start;
  @override
  final int end;

  @override
  String toString() {
    return 'ReadingPageRange(text: $text, start: $start, end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadingPageRangeImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text, start, end);

  /// Create a copy of ReadingPageRange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReadingPageRangeImplCopyWith<_$ReadingPageRangeImpl> get copyWith =>
      __$$ReadingPageRangeImplCopyWithImpl<_$ReadingPageRangeImpl>(
        this,
        _$identity,
      );
}

abstract class _ReadingPageRange implements ReadingPageRange {
  const factory _ReadingPageRange({
    required final String text,
    required final int start,
    required final int end,
  }) = _$ReadingPageRangeImpl;

  @override
  String get text;
  @override
  int get start;
  @override
  int get end;

  /// Create a copy of ReadingPageRange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReadingPageRangeImplCopyWith<_$ReadingPageRangeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
