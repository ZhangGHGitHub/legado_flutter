// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_config_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AppConfigState {
  bool get showDiscovery => throw _privateConstructorUsedError;
  bool get showRSS => throw _privateConstructorUsedError;
  String get defaultHomePage => throw _privateConstructorUsedError;
  bool get syncBookProgress => throw _privateConstructorUsedError;
  AppConfigLoadStatus get loadStatus => throw _privateConstructorUsedError;
  Object? get loadError => throw _privateConstructorUsedError;

  /// Create a copy of AppConfigState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppConfigStateCopyWith<AppConfigState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppConfigStateCopyWith<$Res> {
  factory $AppConfigStateCopyWith(
    AppConfigState value,
    $Res Function(AppConfigState) then,
  ) = _$AppConfigStateCopyWithImpl<$Res, AppConfigState>;
  @useResult
  $Res call({
    bool showDiscovery,
    bool showRSS,
    String defaultHomePage,
    bool syncBookProgress,
    AppConfigLoadStatus loadStatus,
    Object? loadError,
  });
}

/// @nodoc
class _$AppConfigStateCopyWithImpl<$Res, $Val extends AppConfigState>
    implements $AppConfigStateCopyWith<$Res> {
  _$AppConfigStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppConfigState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showDiscovery = null,
    Object? showRSS = null,
    Object? defaultHomePage = null,
    Object? syncBookProgress = null,
    Object? loadStatus = null,
    Object? loadError = freezed,
  }) {
    return _then(
      _value.copyWith(
            showDiscovery: null == showDiscovery
                ? _value.showDiscovery
                : showDiscovery // ignore: cast_nullable_to_non_nullable
                      as bool,
            showRSS: null == showRSS
                ? _value.showRSS
                : showRSS // ignore: cast_nullable_to_non_nullable
                      as bool,
            defaultHomePage: null == defaultHomePage
                ? _value.defaultHomePage
                : defaultHomePage // ignore: cast_nullable_to_non_nullable
                      as String,
            syncBookProgress: null == syncBookProgress
                ? _value.syncBookProgress
                : syncBookProgress // ignore: cast_nullable_to_non_nullable
                      as bool,
            loadStatus: null == loadStatus
                ? _value.loadStatus
                : loadStatus // ignore: cast_nullable_to_non_nullable
                      as AppConfigLoadStatus,
            loadError: freezed == loadError ? _value.loadError : loadError,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppConfigStateImplCopyWith<$Res>
    implements $AppConfigStateCopyWith<$Res> {
  factory _$$AppConfigStateImplCopyWith(
    _$AppConfigStateImpl value,
    $Res Function(_$AppConfigStateImpl) then,
  ) = __$$AppConfigStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool showDiscovery,
    bool showRSS,
    String defaultHomePage,
    bool syncBookProgress,
    AppConfigLoadStatus loadStatus,
    Object? loadError,
  });
}

/// @nodoc
class __$$AppConfigStateImplCopyWithImpl<$Res>
    extends _$AppConfigStateCopyWithImpl<$Res, _$AppConfigStateImpl>
    implements _$$AppConfigStateImplCopyWith<$Res> {
  __$$AppConfigStateImplCopyWithImpl(
    _$AppConfigStateImpl _value,
    $Res Function(_$AppConfigStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppConfigState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showDiscovery = null,
    Object? showRSS = null,
    Object? defaultHomePage = null,
    Object? syncBookProgress = null,
    Object? loadStatus = null,
    Object? loadError = freezed,
  }) {
    return _then(
      _$AppConfigStateImpl(
        showDiscovery: null == showDiscovery
            ? _value.showDiscovery
            : showDiscovery // ignore: cast_nullable_to_non_nullable
                  as bool,
        showRSS: null == showRSS
            ? _value.showRSS
            : showRSS // ignore: cast_nullable_to_non_nullable
                  as bool,
        defaultHomePage: null == defaultHomePage
            ? _value.defaultHomePage
            : defaultHomePage // ignore: cast_nullable_to_non_nullable
                  as String,
        syncBookProgress: null == syncBookProgress
            ? _value.syncBookProgress
            : syncBookProgress // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadStatus: null == loadStatus
            ? _value.loadStatus
            : loadStatus // ignore: cast_nullable_to_non_nullable
                  as AppConfigLoadStatus,
        loadError: freezed == loadError ? _value.loadError : loadError,
      ),
    );
  }
}

/// @nodoc

class _$AppConfigStateImpl extends _AppConfigState {
  const _$AppConfigStateImpl({
    this.showDiscovery = true,
    this.showRSS = true,
    this.defaultHomePage = 'bookshelf',
    this.syncBookProgress = true,
    this.loadStatus = AppConfigLoadStatus.initial,
    this.loadError,
  }) : super._();

  @override
  @JsonKey()
  final bool showDiscovery;
  @override
  @JsonKey()
  final bool showRSS;
  @override
  @JsonKey()
  final String defaultHomePage;
  @override
  @JsonKey()
  final bool syncBookProgress;
  @override
  @JsonKey()
  final AppConfigLoadStatus loadStatus;
  @override
  final Object? loadError;

  @override
  String toString() {
    return 'AppConfigState(showDiscovery: $showDiscovery, showRSS: $showRSS, defaultHomePage: $defaultHomePage, syncBookProgress: $syncBookProgress, loadStatus: $loadStatus, loadError: $loadError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppConfigStateImpl &&
            (identical(other.showDiscovery, showDiscovery) ||
                other.showDiscovery == showDiscovery) &&
            (identical(other.showRSS, showRSS) || other.showRSS == showRSS) &&
            (identical(other.defaultHomePage, defaultHomePage) ||
                other.defaultHomePage == defaultHomePage) &&
            (identical(other.syncBookProgress, syncBookProgress) ||
                other.syncBookProgress == syncBookProgress) &&
            (identical(other.loadStatus, loadStatus) ||
                other.loadStatus == loadStatus) &&
            const DeepCollectionEquality().equals(other.loadError, loadError));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    showDiscovery,
    showRSS,
    defaultHomePage,
    syncBookProgress,
    loadStatus,
    const DeepCollectionEquality().hash(loadError),
  );

  /// Create a copy of AppConfigState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppConfigStateImplCopyWith<_$AppConfigStateImpl> get copyWith =>
      __$$AppConfigStateImplCopyWithImpl<_$AppConfigStateImpl>(
        this,
        _$identity,
      );
}

abstract class _AppConfigState extends AppConfigState {
  const factory _AppConfigState({
    final bool showDiscovery,
    final bool showRSS,
    final String defaultHomePage,
    final bool syncBookProgress,
    final AppConfigLoadStatus loadStatus,
    final Object? loadError,
  }) = _$AppConfigStateImpl;
  const _AppConfigState._() : super._();

  @override
  bool get showDiscovery;
  @override
  bool get showRSS;
  @override
  String get defaultHomePage;
  @override
  bool get syncBookProgress;
  @override
  AppConfigLoadStatus get loadStatus;
  @override
  Object? get loadError;

  /// Create a copy of AppConfigState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppConfigStateImplCopyWith<_$AppConfigStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
