// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookshelf_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BookshelfState {
  BookshelfStatus get status => throw _privateConstructorUsedError;
  List<Book> get books => throw _privateConstructorUsedError;
  Object? get error => throw _privateConstructorUsedError;
  StackTrace? get stackTrace => throw _privateConstructorUsedError;
  bool get isRefreshing => throw _privateConstructorUsedError;

  /// Create a copy of BookshelfState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookshelfStateCopyWith<BookshelfState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookshelfStateCopyWith<$Res> {
  factory $BookshelfStateCopyWith(
    BookshelfState value,
    $Res Function(BookshelfState) then,
  ) = _$BookshelfStateCopyWithImpl<$Res, BookshelfState>;
  @useResult
  $Res call({
    BookshelfStatus status,
    List<Book> books,
    Object? error,
    StackTrace? stackTrace,
    bool isRefreshing,
  });
}

/// @nodoc
class _$BookshelfStateCopyWithImpl<$Res, $Val extends BookshelfState>
    implements $BookshelfStateCopyWith<$Res> {
  _$BookshelfStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookshelfState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? books = null,
    Object? error = freezed,
    Object? stackTrace = freezed,
    Object? isRefreshing = null,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as BookshelfStatus,
            books: null == books
                ? _value.books
                : books // ignore: cast_nullable_to_non_nullable
                      as List<Book>,
            error: freezed == error ? _value.error : error,
            stackTrace: freezed == stackTrace
                ? _value.stackTrace
                : stackTrace // ignore: cast_nullable_to_non_nullable
                      as StackTrace?,
            isRefreshing: null == isRefreshing
                ? _value.isRefreshing
                : isRefreshing // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookshelfStateImplCopyWith<$Res>
    implements $BookshelfStateCopyWith<$Res> {
  factory _$$BookshelfStateImplCopyWith(
    _$BookshelfStateImpl value,
    $Res Function(_$BookshelfStateImpl) then,
  ) = __$$BookshelfStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    BookshelfStatus status,
    List<Book> books,
    Object? error,
    StackTrace? stackTrace,
    bool isRefreshing,
  });
}

/// @nodoc
class __$$BookshelfStateImplCopyWithImpl<$Res>
    extends _$BookshelfStateCopyWithImpl<$Res, _$BookshelfStateImpl>
    implements _$$BookshelfStateImplCopyWith<$Res> {
  __$$BookshelfStateImplCopyWithImpl(
    _$BookshelfStateImpl _value,
    $Res Function(_$BookshelfStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookshelfState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? books = null,
    Object? error = freezed,
    Object? stackTrace = freezed,
    Object? isRefreshing = null,
  }) {
    return _then(
      _$BookshelfStateImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as BookshelfStatus,
        books: null == books
            ? _value._books
            : books // ignore: cast_nullable_to_non_nullable
                  as List<Book>,
        error: freezed == error ? _value.error : error,
        stackTrace: freezed == stackTrace
            ? _value.stackTrace
            : stackTrace // ignore: cast_nullable_to_non_nullable
                  as StackTrace?,
        isRefreshing: null == isRefreshing
            ? _value.isRefreshing
            : isRefreshing // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$BookshelfStateImpl extends _BookshelfState {
  const _$BookshelfStateImpl({
    required this.status,
    final List<Book> books = const <Book>[],
    this.error,
    this.stackTrace,
    this.isRefreshing = false,
  }) : _books = books,
       super._();

  @override
  final BookshelfStatus status;
  final List<Book> _books;
  @override
  @JsonKey()
  List<Book> get books {
    if (_books is EqualUnmodifiableListView) return _books;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_books);
  }

  @override
  final Object? error;
  @override
  final StackTrace? stackTrace;
  @override
  @JsonKey()
  final bool isRefreshing;

  @override
  String toString() {
    return 'BookshelfState._value(status: $status, books: $books, error: $error, stackTrace: $stackTrace, isRefreshing: $isRefreshing)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookshelfStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._books, _books) &&
            const DeepCollectionEquality().equals(other.error, error) &&
            (identical(other.stackTrace, stackTrace) ||
                other.stackTrace == stackTrace) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    const DeepCollectionEquality().hash(_books),
    const DeepCollectionEquality().hash(error),
    stackTrace,
    isRefreshing,
  );

  /// Create a copy of BookshelfState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookshelfStateImplCopyWith<_$BookshelfStateImpl> get copyWith =>
      __$$BookshelfStateImplCopyWithImpl<_$BookshelfStateImpl>(
        this,
        _$identity,
      );
}

abstract class _BookshelfState extends BookshelfState {
  const factory _BookshelfState({
    required final BookshelfStatus status,
    final List<Book> books,
    final Object? error,
    final StackTrace? stackTrace,
    final bool isRefreshing,
  }) = _$BookshelfStateImpl;
  const _BookshelfState._() : super._();

  @override
  BookshelfStatus get status;
  @override
  List<Book> get books;
  @override
  Object? get error;
  @override
  StackTrace? get stackTrace;
  @override
  bool get isRefreshing;

  /// Create a copy of BookshelfState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookshelfStateImplCopyWith<_$BookshelfStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
