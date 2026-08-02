// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_source_debug_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BookSourceDebugStep {
  String get step => throw _privateConstructorUsedError;
  String get rule => throw _privateConstructorUsedError;
  String get result => throw _privateConstructorUsedError;
  bool get ok => throw _privateConstructorUsedError;

  /// Create a copy of BookSourceDebugStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookSourceDebugStepCopyWith<BookSourceDebugStep> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookSourceDebugStepCopyWith<$Res> {
  factory $BookSourceDebugStepCopyWith(
    BookSourceDebugStep value,
    $Res Function(BookSourceDebugStep) then,
  ) = _$BookSourceDebugStepCopyWithImpl<$Res, BookSourceDebugStep>;
  @useResult
  $Res call({String step, String rule, String result, bool ok});
}

/// @nodoc
class _$BookSourceDebugStepCopyWithImpl<$Res, $Val extends BookSourceDebugStep>
    implements $BookSourceDebugStepCopyWith<$Res> {
  _$BookSourceDebugStepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookSourceDebugStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? step = null,
    Object? rule = null,
    Object? result = null,
    Object? ok = null,
  }) {
    return _then(
      _value.copyWith(
            step: null == step
                ? _value.step
                : step // ignore: cast_nullable_to_non_nullable
                      as String,
            rule: null == rule
                ? _value.rule
                : rule // ignore: cast_nullable_to_non_nullable
                      as String,
            result: null == result
                ? _value.result
                : result // ignore: cast_nullable_to_non_nullable
                      as String,
            ok: null == ok
                ? _value.ok
                : ok // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookSourceDebugStepImplCopyWith<$Res>
    implements $BookSourceDebugStepCopyWith<$Res> {
  factory _$$BookSourceDebugStepImplCopyWith(
    _$BookSourceDebugStepImpl value,
    $Res Function(_$BookSourceDebugStepImpl) then,
  ) = __$$BookSourceDebugStepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String step, String rule, String result, bool ok});
}

/// @nodoc
class __$$BookSourceDebugStepImplCopyWithImpl<$Res>
    extends _$BookSourceDebugStepCopyWithImpl<$Res, _$BookSourceDebugStepImpl>
    implements _$$BookSourceDebugStepImplCopyWith<$Res> {
  __$$BookSourceDebugStepImplCopyWithImpl(
    _$BookSourceDebugStepImpl _value,
    $Res Function(_$BookSourceDebugStepImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookSourceDebugStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? step = null,
    Object? rule = null,
    Object? result = null,
    Object? ok = null,
  }) {
    return _then(
      _$BookSourceDebugStepImpl(
        step: null == step
            ? _value.step
            : step // ignore: cast_nullable_to_non_nullable
                  as String,
        rule: null == rule
            ? _value.rule
            : rule // ignore: cast_nullable_to_non_nullable
                  as String,
        result: null == result
            ? _value.result
            : result // ignore: cast_nullable_to_non_nullable
                  as String,
        ok: null == ok
            ? _value.ok
            : ok // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$BookSourceDebugStepImpl implements _BookSourceDebugStep {
  const _$BookSourceDebugStepImpl({
    required this.step,
    required this.rule,
    required this.result,
    required this.ok,
  });

  @override
  final String step;
  @override
  final String rule;
  @override
  final String result;
  @override
  final bool ok;

  @override
  String toString() {
    return 'BookSourceDebugStep(step: $step, rule: $rule, result: $result, ok: $ok)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookSourceDebugStepImpl &&
            (identical(other.step, step) || other.step == step) &&
            (identical(other.rule, rule) || other.rule == rule) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.ok, ok) || other.ok == ok));
  }

  @override
  int get hashCode => Object.hash(runtimeType, step, rule, result, ok);

  /// Create a copy of BookSourceDebugStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookSourceDebugStepImplCopyWith<_$BookSourceDebugStepImpl> get copyWith =>
      __$$BookSourceDebugStepImplCopyWithImpl<_$BookSourceDebugStepImpl>(
        this,
        _$identity,
      );
}

abstract class _BookSourceDebugStep implements BookSourceDebugStep {
  const factory _BookSourceDebugStep({
    required final String step,
    required final String rule,
    required final String result,
    required final bool ok,
  }) = _$BookSourceDebugStepImpl;

  @override
  String get step;
  @override
  String get rule;
  @override
  String get result;
  @override
  bool get ok;

  /// Create a copy of BookSourceDebugStep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookSourceDebugStepImplCopyWith<_$BookSourceDebugStepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BookSourceDebugItem {
  String get name => throw _privateConstructorUsedError;
  String get author => throw _privateConstructorUsedError;
  String get coverUrl => throw _privateConstructorUsedError;
  String get bookUrl => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  String get note => throw _privateConstructorUsedError;

  /// Create a copy of BookSourceDebugItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookSourceDebugItemCopyWith<BookSourceDebugItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookSourceDebugItemCopyWith<$Res> {
  factory $BookSourceDebugItemCopyWith(
    BookSourceDebugItem value,
    $Res Function(BookSourceDebugItem) then,
  ) = _$BookSourceDebugItemCopyWithImpl<$Res, BookSourceDebugItem>;
  @useResult
  $Res call({
    String name,
    String author,
    String coverUrl,
    String bookUrl,
    String kind,
    String note,
  });
}

/// @nodoc
class _$BookSourceDebugItemCopyWithImpl<$Res, $Val extends BookSourceDebugItem>
    implements $BookSourceDebugItemCopyWith<$Res> {
  _$BookSourceDebugItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookSourceDebugItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? author = null,
    Object? coverUrl = null,
    Object? bookUrl = null,
    Object? kind = null,
    Object? note = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            author: null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as String,
            coverUrl: null == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            bookUrl: null == bookUrl
                ? _value.bookUrl
                : bookUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as String,
            note: null == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookSourceDebugItemImplCopyWith<$Res>
    implements $BookSourceDebugItemCopyWith<$Res> {
  factory _$$BookSourceDebugItemImplCopyWith(
    _$BookSourceDebugItemImpl value,
    $Res Function(_$BookSourceDebugItemImpl) then,
  ) = __$$BookSourceDebugItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String author,
    String coverUrl,
    String bookUrl,
    String kind,
    String note,
  });
}

/// @nodoc
class __$$BookSourceDebugItemImplCopyWithImpl<$Res>
    extends _$BookSourceDebugItemCopyWithImpl<$Res, _$BookSourceDebugItemImpl>
    implements _$$BookSourceDebugItemImplCopyWith<$Res> {
  __$$BookSourceDebugItemImplCopyWithImpl(
    _$BookSourceDebugItemImpl _value,
    $Res Function(_$BookSourceDebugItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookSourceDebugItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? author = null,
    Object? coverUrl = null,
    Object? bookUrl = null,
    Object? kind = null,
    Object? note = null,
  }) {
    return _then(
      _$BookSourceDebugItemImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        author: null == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as String,
        coverUrl: null == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        bookUrl: null == bookUrl
            ? _value.bookUrl
            : bookUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
        note: null == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$BookSourceDebugItemImpl implements _BookSourceDebugItem {
  const _$BookSourceDebugItemImpl({
    required this.name,
    required this.author,
    required this.coverUrl,
    required this.bookUrl,
    required this.kind,
    required this.note,
  });

  @override
  final String name;
  @override
  final String author;
  @override
  final String coverUrl;
  @override
  final String bookUrl;
  @override
  final String kind;
  @override
  final String note;

  @override
  String toString() {
    return 'BookSourceDebugItem(name: $name, author: $author, coverUrl: $coverUrl, bookUrl: $bookUrl, kind: $kind, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookSourceDebugItemImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.bookUrl, bookUrl) || other.bookUrl == bookUrl) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.note, note) || other.note == note));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, name, author, coverUrl, bookUrl, kind, note);

  /// Create a copy of BookSourceDebugItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookSourceDebugItemImplCopyWith<_$BookSourceDebugItemImpl> get copyWith =>
      __$$BookSourceDebugItemImplCopyWithImpl<_$BookSourceDebugItemImpl>(
        this,
        _$identity,
      );
}

abstract class _BookSourceDebugItem implements BookSourceDebugItem {
  const factory _BookSourceDebugItem({
    required final String name,
    required final String author,
    required final String coverUrl,
    required final String bookUrl,
    required final String kind,
    required final String note,
  }) = _$BookSourceDebugItemImpl;

  @override
  String get name;
  @override
  String get author;
  @override
  String get coverUrl;
  @override
  String get bookUrl;
  @override
  String get kind;
  @override
  String get note;

  /// Create a copy of BookSourceDebugItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookSourceDebugItemImplCopyWith<_$BookSourceDebugItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BookSourceDebugSnapshot {
  String get requestUrl => throw _privateConstructorUsedError;
  String get requestMethod => throw _privateConstructorUsedError;
  String get responseStatus => throw _privateConstructorUsedError;
  String get responseCharset => throw _privateConstructorUsedError;
  int get responseSize => throw _privateConstructorUsedError;
  String get responseBodyPreview => throw _privateConstructorUsedError;
  List<BookSourceDebugStep> get ruleSteps => throw _privateConstructorUsedError;
  List<BookSourceDebugItem> get results => throw _privateConstructorUsedError;

  /// Create a copy of BookSourceDebugSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookSourceDebugSnapshotCopyWith<BookSourceDebugSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookSourceDebugSnapshotCopyWith<$Res> {
  factory $BookSourceDebugSnapshotCopyWith(
    BookSourceDebugSnapshot value,
    $Res Function(BookSourceDebugSnapshot) then,
  ) = _$BookSourceDebugSnapshotCopyWithImpl<$Res, BookSourceDebugSnapshot>;
  @useResult
  $Res call({
    String requestUrl,
    String requestMethod,
    String responseStatus,
    String responseCharset,
    int responseSize,
    String responseBodyPreview,
    List<BookSourceDebugStep> ruleSteps,
    List<BookSourceDebugItem> results,
  });
}

/// @nodoc
class _$BookSourceDebugSnapshotCopyWithImpl<
  $Res,
  $Val extends BookSourceDebugSnapshot
>
    implements $BookSourceDebugSnapshotCopyWith<$Res> {
  _$BookSourceDebugSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookSourceDebugSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestUrl = null,
    Object? requestMethod = null,
    Object? responseStatus = null,
    Object? responseCharset = null,
    Object? responseSize = null,
    Object? responseBodyPreview = null,
    Object? ruleSteps = null,
    Object? results = null,
  }) {
    return _then(
      _value.copyWith(
            requestUrl: null == requestUrl
                ? _value.requestUrl
                : requestUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            requestMethod: null == requestMethod
                ? _value.requestMethod
                : requestMethod // ignore: cast_nullable_to_non_nullable
                      as String,
            responseStatus: null == responseStatus
                ? _value.responseStatus
                : responseStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            responseCharset: null == responseCharset
                ? _value.responseCharset
                : responseCharset // ignore: cast_nullable_to_non_nullable
                      as String,
            responseSize: null == responseSize
                ? _value.responseSize
                : responseSize // ignore: cast_nullable_to_non_nullable
                      as int,
            responseBodyPreview: null == responseBodyPreview
                ? _value.responseBodyPreview
                : responseBodyPreview // ignore: cast_nullable_to_non_nullable
                      as String,
            ruleSteps: null == ruleSteps
                ? _value.ruleSteps
                : ruleSteps // ignore: cast_nullable_to_non_nullable
                      as List<BookSourceDebugStep>,
            results: null == results
                ? _value.results
                : results // ignore: cast_nullable_to_non_nullable
                      as List<BookSourceDebugItem>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookSourceDebugSnapshotImplCopyWith<$Res>
    implements $BookSourceDebugSnapshotCopyWith<$Res> {
  factory _$$BookSourceDebugSnapshotImplCopyWith(
    _$BookSourceDebugSnapshotImpl value,
    $Res Function(_$BookSourceDebugSnapshotImpl) then,
  ) = __$$BookSourceDebugSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String requestUrl,
    String requestMethod,
    String responseStatus,
    String responseCharset,
    int responseSize,
    String responseBodyPreview,
    List<BookSourceDebugStep> ruleSteps,
    List<BookSourceDebugItem> results,
  });
}

/// @nodoc
class __$$BookSourceDebugSnapshotImplCopyWithImpl<$Res>
    extends
        _$BookSourceDebugSnapshotCopyWithImpl<
          $Res,
          _$BookSourceDebugSnapshotImpl
        >
    implements _$$BookSourceDebugSnapshotImplCopyWith<$Res> {
  __$$BookSourceDebugSnapshotImplCopyWithImpl(
    _$BookSourceDebugSnapshotImpl _value,
    $Res Function(_$BookSourceDebugSnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookSourceDebugSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestUrl = null,
    Object? requestMethod = null,
    Object? responseStatus = null,
    Object? responseCharset = null,
    Object? responseSize = null,
    Object? responseBodyPreview = null,
    Object? ruleSteps = null,
    Object? results = null,
  }) {
    return _then(
      _$BookSourceDebugSnapshotImpl(
        requestUrl: null == requestUrl
            ? _value.requestUrl
            : requestUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        requestMethod: null == requestMethod
            ? _value.requestMethod
            : requestMethod // ignore: cast_nullable_to_non_nullable
                  as String,
        responseStatus: null == responseStatus
            ? _value.responseStatus
            : responseStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        responseCharset: null == responseCharset
            ? _value.responseCharset
            : responseCharset // ignore: cast_nullable_to_non_nullable
                  as String,
        responseSize: null == responseSize
            ? _value.responseSize
            : responseSize // ignore: cast_nullable_to_non_nullable
                  as int,
        responseBodyPreview: null == responseBodyPreview
            ? _value.responseBodyPreview
            : responseBodyPreview // ignore: cast_nullable_to_non_nullable
                  as String,
        ruleSteps: null == ruleSteps
            ? _value._ruleSteps
            : ruleSteps // ignore: cast_nullable_to_non_nullable
                  as List<BookSourceDebugStep>,
        results: null == results
            ? _value._results
            : results // ignore: cast_nullable_to_non_nullable
                  as List<BookSourceDebugItem>,
      ),
    );
  }
}

/// @nodoc

class _$BookSourceDebugSnapshotImpl implements _BookSourceDebugSnapshot {
  const _$BookSourceDebugSnapshotImpl({
    required this.requestUrl,
    required this.requestMethod,
    required this.responseStatus,
    required this.responseCharset,
    required this.responseSize,
    required this.responseBodyPreview,
    required final List<BookSourceDebugStep> ruleSteps,
    required final List<BookSourceDebugItem> results,
  }) : _ruleSteps = ruleSteps,
       _results = results;

  @override
  final String requestUrl;
  @override
  final String requestMethod;
  @override
  final String responseStatus;
  @override
  final String responseCharset;
  @override
  final int responseSize;
  @override
  final String responseBodyPreview;
  final List<BookSourceDebugStep> _ruleSteps;
  @override
  List<BookSourceDebugStep> get ruleSteps {
    if (_ruleSteps is EqualUnmodifiableListView) return _ruleSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ruleSteps);
  }

  final List<BookSourceDebugItem> _results;
  @override
  List<BookSourceDebugItem> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  String toString() {
    return 'BookSourceDebugSnapshot(requestUrl: $requestUrl, requestMethod: $requestMethod, responseStatus: $responseStatus, responseCharset: $responseCharset, responseSize: $responseSize, responseBodyPreview: $responseBodyPreview, ruleSteps: $ruleSteps, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookSourceDebugSnapshotImpl &&
            (identical(other.requestUrl, requestUrl) ||
                other.requestUrl == requestUrl) &&
            (identical(other.requestMethod, requestMethod) ||
                other.requestMethod == requestMethod) &&
            (identical(other.responseStatus, responseStatus) ||
                other.responseStatus == responseStatus) &&
            (identical(other.responseCharset, responseCharset) ||
                other.responseCharset == responseCharset) &&
            (identical(other.responseSize, responseSize) ||
                other.responseSize == responseSize) &&
            (identical(other.responseBodyPreview, responseBodyPreview) ||
                other.responseBodyPreview == responseBodyPreview) &&
            const DeepCollectionEquality().equals(
              other._ruleSteps,
              _ruleSteps,
            ) &&
            const DeepCollectionEquality().equals(other._results, _results));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    requestUrl,
    requestMethod,
    responseStatus,
    responseCharset,
    responseSize,
    responseBodyPreview,
    const DeepCollectionEquality().hash(_ruleSteps),
    const DeepCollectionEquality().hash(_results),
  );

  /// Create a copy of BookSourceDebugSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookSourceDebugSnapshotImplCopyWith<_$BookSourceDebugSnapshotImpl>
  get copyWith =>
      __$$BookSourceDebugSnapshotImplCopyWithImpl<
        _$BookSourceDebugSnapshotImpl
      >(this, _$identity);
}

abstract class _BookSourceDebugSnapshot implements BookSourceDebugSnapshot {
  const factory _BookSourceDebugSnapshot({
    required final String requestUrl,
    required final String requestMethod,
    required final String responseStatus,
    required final String responseCharset,
    required final int responseSize,
    required final String responseBodyPreview,
    required final List<BookSourceDebugStep> ruleSteps,
    required final List<BookSourceDebugItem> results,
  }) = _$BookSourceDebugSnapshotImpl;

  @override
  String get requestUrl;
  @override
  String get requestMethod;
  @override
  String get responseStatus;
  @override
  String get responseCharset;
  @override
  int get responseSize;
  @override
  String get responseBodyPreview;
  @override
  List<BookSourceDebugStep> get ruleSteps;
  @override
  List<BookSourceDebugItem> get results;

  /// Create a copy of BookSourceDebugSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookSourceDebugSnapshotImplCopyWith<_$BookSourceDebugSnapshotImpl>
  get copyWith => throw _privateConstructorUsedError;
}
