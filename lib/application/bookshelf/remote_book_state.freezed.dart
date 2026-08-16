// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'remote_book_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RemoteBookState {
  RemoteBookStatus get status => throw _privateConstructorUsedError;
  WebDavConfig? get config => throw _privateConstructorUsedError;
  String get booksRoot => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  List<WebDavEntry> get dirStack => throw _privateConstructorUsedError;
  List<WebDavEntry> get entries => throw _privateConstructorUsedError;
  Set<String> get selected => throw _privateConstructorUsedError;
  String get filter => throw _privateConstructorUsedError;
  RemoteBookSortMode get sortMode => throw _privateConstructorUsedError;
  bool get sortAscending => throw _privateConstructorUsedError;
  bool get searchOpen => throw _privateConstructorUsedError;
  bool get isImporting => throw _privateConstructorUsedError;
  int get importedCount => throw _privateConstructorUsedError;
  int get failedCount => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get needsConfig => throw _privateConstructorUsedError;
  bool get booksRootEnsured => throw _privateConstructorUsedError;

  /// Create a copy of RemoteBookState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RemoteBookStateCopyWith<RemoteBookState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RemoteBookStateCopyWith<$Res> {
  factory $RemoteBookStateCopyWith(
    RemoteBookState value,
    $Res Function(RemoteBookState) then,
  ) = _$RemoteBookStateCopyWithImpl<$Res, RemoteBookState>;
  @useResult
  $Res call({
    RemoteBookStatus status,
    WebDavConfig? config,
    String booksRoot,
    String path,
    List<WebDavEntry> dirStack,
    List<WebDavEntry> entries,
    Set<String> selected,
    String filter,
    RemoteBookSortMode sortMode,
    bool sortAscending,
    bool searchOpen,
    bool isImporting,
    int importedCount,
    int failedCount,
    String? error,
    bool needsConfig,
    bool booksRootEnsured,
  });
}

/// @nodoc
class _$RemoteBookStateCopyWithImpl<$Res, $Val extends RemoteBookState>
    implements $RemoteBookStateCopyWith<$Res> {
  _$RemoteBookStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RemoteBookState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? config = freezed,
    Object? booksRoot = null,
    Object? path = null,
    Object? dirStack = null,
    Object? entries = null,
    Object? selected = null,
    Object? filter = null,
    Object? sortMode = null,
    Object? sortAscending = null,
    Object? searchOpen = null,
    Object? isImporting = null,
    Object? importedCount = null,
    Object? failedCount = null,
    Object? error = freezed,
    Object? needsConfig = null,
    Object? booksRootEnsured = null,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as RemoteBookStatus,
            config: freezed == config
                ? _value.config
                : config // ignore: cast_nullable_to_non_nullable
                      as WebDavConfig?,
            booksRoot: null == booksRoot
                ? _value.booksRoot
                : booksRoot // ignore: cast_nullable_to_non_nullable
                      as String,
            path: null == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                      as String,
            dirStack: null == dirStack
                ? _value.dirStack
                : dirStack // ignore: cast_nullable_to_non_nullable
                      as List<WebDavEntry>,
            entries: null == entries
                ? _value.entries
                : entries // ignore: cast_nullable_to_non_nullable
                      as List<WebDavEntry>,
            selected: null == selected
                ? _value.selected
                : selected // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
            filter: null == filter
                ? _value.filter
                : filter // ignore: cast_nullable_to_non_nullable
                      as String,
            sortMode: null == sortMode
                ? _value.sortMode
                : sortMode // ignore: cast_nullable_to_non_nullable
                      as RemoteBookSortMode,
            sortAscending: null == sortAscending
                ? _value.sortAscending
                : sortAscending // ignore: cast_nullable_to_non_nullable
                      as bool,
            searchOpen: null == searchOpen
                ? _value.searchOpen
                : searchOpen // ignore: cast_nullable_to_non_nullable
                      as bool,
            isImporting: null == isImporting
                ? _value.isImporting
                : isImporting // ignore: cast_nullable_to_non_nullable
                      as bool,
            importedCount: null == importedCount
                ? _value.importedCount
                : importedCount // ignore: cast_nullable_to_non_nullable
                      as int,
            failedCount: null == failedCount
                ? _value.failedCount
                : failedCount // ignore: cast_nullable_to_non_nullable
                      as int,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            needsConfig: null == needsConfig
                ? _value.needsConfig
                : needsConfig // ignore: cast_nullable_to_non_nullable
                      as bool,
            booksRootEnsured: null == booksRootEnsured
                ? _value.booksRootEnsured
                : booksRootEnsured // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RemoteBookStateImplCopyWith<$Res>
    implements $RemoteBookStateCopyWith<$Res> {
  factory _$$RemoteBookStateImplCopyWith(
    _$RemoteBookStateImpl value,
    $Res Function(_$RemoteBookStateImpl) then,
  ) = __$$RemoteBookStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    RemoteBookStatus status,
    WebDavConfig? config,
    String booksRoot,
    String path,
    List<WebDavEntry> dirStack,
    List<WebDavEntry> entries,
    Set<String> selected,
    String filter,
    RemoteBookSortMode sortMode,
    bool sortAscending,
    bool searchOpen,
    bool isImporting,
    int importedCount,
    int failedCount,
    String? error,
    bool needsConfig,
    bool booksRootEnsured,
  });
}

/// @nodoc
class __$$RemoteBookStateImplCopyWithImpl<$Res>
    extends _$RemoteBookStateCopyWithImpl<$Res, _$RemoteBookStateImpl>
    implements _$$RemoteBookStateImplCopyWith<$Res> {
  __$$RemoteBookStateImplCopyWithImpl(
    _$RemoteBookStateImpl _value,
    $Res Function(_$RemoteBookStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RemoteBookState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? config = freezed,
    Object? booksRoot = null,
    Object? path = null,
    Object? dirStack = null,
    Object? entries = null,
    Object? selected = null,
    Object? filter = null,
    Object? sortMode = null,
    Object? sortAscending = null,
    Object? searchOpen = null,
    Object? isImporting = null,
    Object? importedCount = null,
    Object? failedCount = null,
    Object? error = freezed,
    Object? needsConfig = null,
    Object? booksRootEnsured = null,
  }) {
    return _then(
      _$RemoteBookStateImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as RemoteBookStatus,
        config: freezed == config
            ? _value.config
            : config // ignore: cast_nullable_to_non_nullable
                  as WebDavConfig?,
        booksRoot: null == booksRoot
            ? _value.booksRoot
            : booksRoot // ignore: cast_nullable_to_non_nullable
                  as String,
        path: null == path
            ? _value.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String,
        dirStack: null == dirStack
            ? _value._dirStack
            : dirStack // ignore: cast_nullable_to_non_nullable
                  as List<WebDavEntry>,
        entries: null == entries
            ? _value._entries
            : entries // ignore: cast_nullable_to_non_nullable
                  as List<WebDavEntry>,
        selected: null == selected
            ? _value._selected
            : selected // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        filter: null == filter
            ? _value.filter
            : filter // ignore: cast_nullable_to_non_nullable
                  as String,
        sortMode: null == sortMode
            ? _value.sortMode
            : sortMode // ignore: cast_nullable_to_non_nullable
                  as RemoteBookSortMode,
        sortAscending: null == sortAscending
            ? _value.sortAscending
            : sortAscending // ignore: cast_nullable_to_non_nullable
                  as bool,
        searchOpen: null == searchOpen
            ? _value.searchOpen
            : searchOpen // ignore: cast_nullable_to_non_nullable
                  as bool,
        isImporting: null == isImporting
            ? _value.isImporting
            : isImporting // ignore: cast_nullable_to_non_nullable
                  as bool,
        importedCount: null == importedCount
            ? _value.importedCount
            : importedCount // ignore: cast_nullable_to_non_nullable
                  as int,
        failedCount: null == failedCount
            ? _value.failedCount
            : failedCount // ignore: cast_nullable_to_non_nullable
                  as int,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        needsConfig: null == needsConfig
            ? _value.needsConfig
            : needsConfig // ignore: cast_nullable_to_non_nullable
                  as bool,
        booksRootEnsured: null == booksRootEnsured
            ? _value.booksRootEnsured
            : booksRootEnsured // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$RemoteBookStateImpl extends _RemoteBookState {
  const _$RemoteBookStateImpl({
    this.status = RemoteBookStatus.initial,
    this.config,
    this.booksRoot = '',
    this.path = '',
    final List<WebDavEntry> dirStack = const <WebDavEntry>[],
    final List<WebDavEntry> entries = const <WebDavEntry>[],
    final Set<String> selected = const <String>{},
    this.filter = '',
    this.sortMode = RemoteBookSortMode.time,
    this.sortAscending = false,
    this.searchOpen = false,
    this.isImporting = false,
    this.importedCount = 0,
    this.failedCount = 0,
    this.error,
    this.needsConfig = false,
    this.booksRootEnsured = false,
  }) : _dirStack = dirStack,
       _entries = entries,
       _selected = selected,
       super._();

  @override
  @JsonKey()
  final RemoteBookStatus status;
  @override
  final WebDavConfig? config;
  @override
  @JsonKey()
  final String booksRoot;
  @override
  @JsonKey()
  final String path;
  final List<WebDavEntry> _dirStack;
  @override
  @JsonKey()
  List<WebDavEntry> get dirStack {
    if (_dirStack is EqualUnmodifiableListView) return _dirStack;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dirStack);
  }

  final List<WebDavEntry> _entries;
  @override
  @JsonKey()
  List<WebDavEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  final Set<String> _selected;
  @override
  @JsonKey()
  Set<String> get selected {
    if (_selected is EqualUnmodifiableSetView) return _selected;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selected);
  }

  @override
  @JsonKey()
  final String filter;
  @override
  @JsonKey()
  final RemoteBookSortMode sortMode;
  @override
  @JsonKey()
  final bool sortAscending;
  @override
  @JsonKey()
  final bool searchOpen;
  @override
  @JsonKey()
  final bool isImporting;
  @override
  @JsonKey()
  final int importedCount;
  @override
  @JsonKey()
  final int failedCount;
  @override
  final String? error;
  @override
  @JsonKey()
  final bool needsConfig;
  @override
  @JsonKey()
  final bool booksRootEnsured;

  @override
  String toString() {
    return 'RemoteBookState(status: $status, config: $config, booksRoot: $booksRoot, path: $path, dirStack: $dirStack, entries: $entries, selected: $selected, filter: $filter, sortMode: $sortMode, sortAscending: $sortAscending, searchOpen: $searchOpen, isImporting: $isImporting, importedCount: $importedCount, failedCount: $failedCount, error: $error, needsConfig: $needsConfig, booksRootEnsured: $booksRootEnsured)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RemoteBookStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.config, config) || other.config == config) &&
            (identical(other.booksRoot, booksRoot) ||
                other.booksRoot == booksRoot) &&
            (identical(other.path, path) || other.path == path) &&
            const DeepCollectionEquality().equals(other._dirStack, _dirStack) &&
            const DeepCollectionEquality().equals(other._entries, _entries) &&
            const DeepCollectionEquality().equals(other._selected, _selected) &&
            (identical(other.filter, filter) || other.filter == filter) &&
            (identical(other.sortMode, sortMode) ||
                other.sortMode == sortMode) &&
            (identical(other.sortAscending, sortAscending) ||
                other.sortAscending == sortAscending) &&
            (identical(other.searchOpen, searchOpen) ||
                other.searchOpen == searchOpen) &&
            (identical(other.isImporting, isImporting) ||
                other.isImporting == isImporting) &&
            (identical(other.importedCount, importedCount) ||
                other.importedCount == importedCount) &&
            (identical(other.failedCount, failedCount) ||
                other.failedCount == failedCount) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.needsConfig, needsConfig) ||
                other.needsConfig == needsConfig) &&
            (identical(other.booksRootEnsured, booksRootEnsured) ||
                other.booksRootEnsured == booksRootEnsured));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    config,
    booksRoot,
    path,
    const DeepCollectionEquality().hash(_dirStack),
    const DeepCollectionEquality().hash(_entries),
    const DeepCollectionEquality().hash(_selected),
    filter,
    sortMode,
    sortAscending,
    searchOpen,
    isImporting,
    importedCount,
    failedCount,
    error,
    needsConfig,
    booksRootEnsured,
  );

  /// Create a copy of RemoteBookState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RemoteBookStateImplCopyWith<_$RemoteBookStateImpl> get copyWith =>
      __$$RemoteBookStateImplCopyWithImpl<_$RemoteBookStateImpl>(
        this,
        _$identity,
      );
}

abstract class _RemoteBookState extends RemoteBookState {
  const factory _RemoteBookState({
    final RemoteBookStatus status,
    final WebDavConfig? config,
    final String booksRoot,
    final String path,
    final List<WebDavEntry> dirStack,
    final List<WebDavEntry> entries,
    final Set<String> selected,
    final String filter,
    final RemoteBookSortMode sortMode,
    final bool sortAscending,
    final bool searchOpen,
    final bool isImporting,
    final int importedCount,
    final int failedCount,
    final String? error,
    final bool needsConfig,
    final bool booksRootEnsured,
  }) = _$RemoteBookStateImpl;
  const _RemoteBookState._() : super._();

  @override
  RemoteBookStatus get status;
  @override
  WebDavConfig? get config;
  @override
  String get booksRoot;
  @override
  String get path;
  @override
  List<WebDavEntry> get dirStack;
  @override
  List<WebDavEntry> get entries;
  @override
  Set<String> get selected;
  @override
  String get filter;
  @override
  RemoteBookSortMode get sortMode;
  @override
  bool get sortAscending;
  @override
  bool get searchOpen;
  @override
  bool get isImporting;
  @override
  int get importedCount;
  @override
  int get failedCount;
  @override
  String? get error;
  @override
  bool get needsConfig;
  @override
  bool get booksRootEnsured;

  /// Create a copy of RemoteBookState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RemoteBookStateImplCopyWith<_$RemoteBookStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
