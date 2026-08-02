// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'source_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SourceState {
  List<BookSource> get sources => throw _privateConstructorUsedError;
  Map<String, List<Book>> get searchResults =>
      throw _privateConstructorUsedError;
  Map<String, BookSourceValidationSnapshot> get validationResults =>
      throw _privateConstructorUsedError;
  Map<String, String> get validationProgress =>
      throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isValidating => throw _privateConstructorUsedError;
  String? get validatingSourceUrl => throw _privateConstructorUsedError;
  String get statusMessage => throw _privateConstructorUsedError;
  String? get loadError => throw _privateConstructorUsedError;

  /// Create a copy of SourceState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SourceStateCopyWith<SourceState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SourceStateCopyWith<$Res> {
  factory $SourceStateCopyWith(
    SourceState value,
    $Res Function(SourceState) then,
  ) = _$SourceStateCopyWithImpl<$Res, SourceState>;
  @useResult
  $Res call({
    List<BookSource> sources,
    Map<String, List<Book>> searchResults,
    Map<String, BookSourceValidationSnapshot> validationResults,
    Map<String, String> validationProgress,
    bool isLoading,
    bool isValidating,
    String? validatingSourceUrl,
    String statusMessage,
    String? loadError,
  });
}

/// @nodoc
class _$SourceStateCopyWithImpl<$Res, $Val extends SourceState>
    implements $SourceStateCopyWith<$Res> {
  _$SourceStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SourceState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sources = null,
    Object? searchResults = null,
    Object? validationResults = null,
    Object? validationProgress = null,
    Object? isLoading = null,
    Object? isValidating = null,
    Object? validatingSourceUrl = freezed,
    Object? statusMessage = null,
    Object? loadError = freezed,
  }) {
    return _then(
      _value.copyWith(
            sources: null == sources
                ? _value.sources
                : sources // ignore: cast_nullable_to_non_nullable
                      as List<BookSource>,
            searchResults: null == searchResults
                ? _value.searchResults
                : searchResults // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<Book>>,
            validationResults: null == validationResults
                ? _value.validationResults
                : validationResults // ignore: cast_nullable_to_non_nullable
                      as Map<String, BookSourceValidationSnapshot>,
            validationProgress: null == validationProgress
                ? _value.validationProgress
                : validationProgress // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            isValidating: null == isValidating
                ? _value.isValidating
                : isValidating // ignore: cast_nullable_to_non_nullable
                      as bool,
            validatingSourceUrl: freezed == validatingSourceUrl
                ? _value.validatingSourceUrl
                : validatingSourceUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            statusMessage: null == statusMessage
                ? _value.statusMessage
                : statusMessage // ignore: cast_nullable_to_non_nullable
                      as String,
            loadError: freezed == loadError
                ? _value.loadError
                : loadError // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SourceStateImplCopyWith<$Res>
    implements $SourceStateCopyWith<$Res> {
  factory _$$SourceStateImplCopyWith(
    _$SourceStateImpl value,
    $Res Function(_$SourceStateImpl) then,
  ) = __$$SourceStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<BookSource> sources,
    Map<String, List<Book>> searchResults,
    Map<String, BookSourceValidationSnapshot> validationResults,
    Map<String, String> validationProgress,
    bool isLoading,
    bool isValidating,
    String? validatingSourceUrl,
    String statusMessage,
    String? loadError,
  });
}

/// @nodoc
class __$$SourceStateImplCopyWithImpl<$Res>
    extends _$SourceStateCopyWithImpl<$Res, _$SourceStateImpl>
    implements _$$SourceStateImplCopyWith<$Res> {
  __$$SourceStateImplCopyWithImpl(
    _$SourceStateImpl _value,
    $Res Function(_$SourceStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SourceState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sources = null,
    Object? searchResults = null,
    Object? validationResults = null,
    Object? validationProgress = null,
    Object? isLoading = null,
    Object? isValidating = null,
    Object? validatingSourceUrl = freezed,
    Object? statusMessage = null,
    Object? loadError = freezed,
  }) {
    return _then(
      _$SourceStateImpl(
        sources: null == sources
            ? _value._sources
            : sources // ignore: cast_nullable_to_non_nullable
                  as List<BookSource>,
        searchResults: null == searchResults
            ? _value._searchResults
            : searchResults // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<Book>>,
        validationResults: null == validationResults
            ? _value._validationResults
            : validationResults // ignore: cast_nullable_to_non_nullable
                  as Map<String, BookSourceValidationSnapshot>,
        validationProgress: null == validationProgress
            ? _value._validationProgress
            : validationProgress // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isValidating: null == isValidating
            ? _value.isValidating
            : isValidating // ignore: cast_nullable_to_non_nullable
                  as bool,
        validatingSourceUrl: freezed == validatingSourceUrl
            ? _value.validatingSourceUrl
            : validatingSourceUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        statusMessage: null == statusMessage
            ? _value.statusMessage
            : statusMessage // ignore: cast_nullable_to_non_nullable
                  as String,
        loadError: freezed == loadError
            ? _value.loadError
            : loadError // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$SourceStateImpl implements _SourceState {
  const _$SourceStateImpl({
    final List<BookSource> sources = const <BookSource>[],
    final Map<String, List<Book>> searchResults = const <String, List<Book>>{},
    final Map<String, BookSourceValidationSnapshot> validationResults =
        const <String, SourceValidationResult>{},
    final Map<String, String> validationProgress = const <String, String>{},
    this.isLoading = false,
    this.isValidating = false,
    this.validatingSourceUrl,
    this.statusMessage = '',
    this.loadError,
  }) : _sources = sources,
       _searchResults = searchResults,
       _validationResults = validationResults,
       _validationProgress = validationProgress;

  final List<BookSource> _sources;
  @override
  @JsonKey()
  List<BookSource> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  final Map<String, List<Book>> _searchResults;
  @override
  @JsonKey()
  Map<String, List<Book>> get searchResults {
    if (_searchResults is EqualUnmodifiableMapView) return _searchResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_searchResults);
  }

  final Map<String, BookSourceValidationSnapshot> _validationResults;
  @override
  @JsonKey()
  Map<String, BookSourceValidationSnapshot> get validationResults {
    if (_validationResults is EqualUnmodifiableMapView)
      return _validationResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_validationResults);
  }

  final Map<String, String> _validationProgress;
  @override
  @JsonKey()
  Map<String, String> get validationProgress {
    if (_validationProgress is EqualUnmodifiableMapView)
      return _validationProgress;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_validationProgress);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isValidating;
  @override
  final String? validatingSourceUrl;
  @override
  @JsonKey()
  final String statusMessage;
  @override
  final String? loadError;

  @override
  String toString() {
    return 'SourceState(sources: $sources, searchResults: $searchResults, validationResults: $validationResults, validationProgress: $validationProgress, isLoading: $isLoading, isValidating: $isValidating, validatingSourceUrl: $validatingSourceUrl, statusMessage: $statusMessage, loadError: $loadError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SourceStateImpl &&
            const DeepCollectionEquality().equals(other._sources, _sources) &&
            const DeepCollectionEquality().equals(
              other._searchResults,
              _searchResults,
            ) &&
            const DeepCollectionEquality().equals(
              other._validationResults,
              _validationResults,
            ) &&
            const DeepCollectionEquality().equals(
              other._validationProgress,
              _validationProgress,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isValidating, isValidating) ||
                other.isValidating == isValidating) &&
            (identical(other.validatingSourceUrl, validatingSourceUrl) ||
                other.validatingSourceUrl == validatingSourceUrl) &&
            (identical(other.statusMessage, statusMessage) ||
                other.statusMessage == statusMessage) &&
            (identical(other.loadError, loadError) ||
                other.loadError == loadError));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_sources),
    const DeepCollectionEquality().hash(_searchResults),
    const DeepCollectionEquality().hash(_validationResults),
    const DeepCollectionEquality().hash(_validationProgress),
    isLoading,
    isValidating,
    validatingSourceUrl,
    statusMessage,
    loadError,
  );

  /// Create a copy of SourceState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SourceStateImplCopyWith<_$SourceStateImpl> get copyWith =>
      __$$SourceStateImplCopyWithImpl<_$SourceStateImpl>(this, _$identity);
}

abstract class _SourceState implements SourceState {
  const factory _SourceState({
    final List<BookSource> sources,
    final Map<String, List<Book>> searchResults,
    final Map<String, BookSourceValidationSnapshot> validationResults,
    final Map<String, String> validationProgress,
    final bool isLoading,
    final bool isValidating,
    final String? validatingSourceUrl,
    final String statusMessage,
    final String? loadError,
  }) = _$SourceStateImpl;

  @override
  List<BookSource> get sources;
  @override
  Map<String, List<Book>> get searchResults;
  @override
  Map<String, BookSourceValidationSnapshot> get validationResults;
  @override
  Map<String, String> get validationProgress;
  @override
  bool get isLoading;
  @override
  bool get isValidating;
  @override
  String? get validatingSourceUrl;
  @override
  String get statusMessage;
  @override
  String? get loadError;

  /// Create a copy of SourceState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SourceStateImplCopyWith<_$SourceStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
