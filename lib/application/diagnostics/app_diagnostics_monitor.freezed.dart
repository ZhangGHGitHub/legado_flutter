// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_diagnostics_monitor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AppDiagnosticsConfig {
  bool get enabled => throw _privateConstructorUsedError;
  bool get recordFrames => throw _privateConstructorUsedError;
  bool get recordFreeze => throw _privateConstructorUsedError;
  bool get recordDispatchers => throw _privateConstructorUsedError;
  bool get recordStartupTasks => throw _privateConstructorUsedError;
  Duration get frameBudget => throw _privateConstructorUsedError;
  Duration get freezeProbeInterval => throw _privateConstructorUsedError;
  Duration get freezeTolerance => throw _privateConstructorUsedError;
  Duration get dispatcherTimeout => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )
    $default, {
    required TResult Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )
    disabled,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )?
    $default, {
    TResult? Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )?
    disabled,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )?
    $default, {
    TResult Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )?
    disabled,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AppDiagnosticsConfig value) $default, {
    required TResult Function(_DisabledAppDiagnosticsConfig value) disabled,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AppDiagnosticsConfig value)? $default, {
    TResult? Function(_DisabledAppDiagnosticsConfig value)? disabled,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AppDiagnosticsConfig value)? $default, {
    TResult Function(_DisabledAppDiagnosticsConfig value)? disabled,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Create a copy of AppDiagnosticsConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppDiagnosticsConfigCopyWith<AppDiagnosticsConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppDiagnosticsConfigCopyWith<$Res> {
  factory $AppDiagnosticsConfigCopyWith(
    AppDiagnosticsConfig value,
    $Res Function(AppDiagnosticsConfig) then,
  ) = _$AppDiagnosticsConfigCopyWithImpl<$Res, AppDiagnosticsConfig>;
  @useResult
  $Res call({
    bool enabled,
    bool recordFrames,
    bool recordFreeze,
    bool recordDispatchers,
    bool recordStartupTasks,
    Duration frameBudget,
    Duration freezeProbeInterval,
    Duration freezeTolerance,
    Duration dispatcherTimeout,
  });
}

/// @nodoc
class _$AppDiagnosticsConfigCopyWithImpl<
  $Res,
  $Val extends AppDiagnosticsConfig
>
    implements $AppDiagnosticsConfigCopyWith<$Res> {
  _$AppDiagnosticsConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppDiagnosticsConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? recordFrames = null,
    Object? recordFreeze = null,
    Object? recordDispatchers = null,
    Object? recordStartupTasks = null,
    Object? frameBudget = null,
    Object? freezeProbeInterval = null,
    Object? freezeTolerance = null,
    Object? dispatcherTimeout = null,
  }) {
    return _then(
      _value.copyWith(
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            recordFrames: null == recordFrames
                ? _value.recordFrames
                : recordFrames // ignore: cast_nullable_to_non_nullable
                      as bool,
            recordFreeze: null == recordFreeze
                ? _value.recordFreeze
                : recordFreeze // ignore: cast_nullable_to_non_nullable
                      as bool,
            recordDispatchers: null == recordDispatchers
                ? _value.recordDispatchers
                : recordDispatchers // ignore: cast_nullable_to_non_nullable
                      as bool,
            recordStartupTasks: null == recordStartupTasks
                ? _value.recordStartupTasks
                : recordStartupTasks // ignore: cast_nullable_to_non_nullable
                      as bool,
            frameBudget: null == frameBudget
                ? _value.frameBudget
                : frameBudget // ignore: cast_nullable_to_non_nullable
                      as Duration,
            freezeProbeInterval: null == freezeProbeInterval
                ? _value.freezeProbeInterval
                : freezeProbeInterval // ignore: cast_nullable_to_non_nullable
                      as Duration,
            freezeTolerance: null == freezeTolerance
                ? _value.freezeTolerance
                : freezeTolerance // ignore: cast_nullable_to_non_nullable
                      as Duration,
            dispatcherTimeout: null == dispatcherTimeout
                ? _value.dispatcherTimeout
                : dispatcherTimeout // ignore: cast_nullable_to_non_nullable
                      as Duration,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppDiagnosticsConfigImplCopyWith<$Res>
    implements $AppDiagnosticsConfigCopyWith<$Res> {
  factory _$$AppDiagnosticsConfigImplCopyWith(
    _$AppDiagnosticsConfigImpl value,
    $Res Function(_$AppDiagnosticsConfigImpl) then,
  ) = __$$AppDiagnosticsConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool enabled,
    bool recordFrames,
    bool recordFreeze,
    bool recordDispatchers,
    bool recordStartupTasks,
    Duration frameBudget,
    Duration freezeProbeInterval,
    Duration freezeTolerance,
    Duration dispatcherTimeout,
  });
}

/// @nodoc
class __$$AppDiagnosticsConfigImplCopyWithImpl<$Res>
    extends _$AppDiagnosticsConfigCopyWithImpl<$Res, _$AppDiagnosticsConfigImpl>
    implements _$$AppDiagnosticsConfigImplCopyWith<$Res> {
  __$$AppDiagnosticsConfigImplCopyWithImpl(
    _$AppDiagnosticsConfigImpl _value,
    $Res Function(_$AppDiagnosticsConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppDiagnosticsConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? recordFrames = null,
    Object? recordFreeze = null,
    Object? recordDispatchers = null,
    Object? recordStartupTasks = null,
    Object? frameBudget = null,
    Object? freezeProbeInterval = null,
    Object? freezeTolerance = null,
    Object? dispatcherTimeout = null,
  }) {
    return _then(
      _$AppDiagnosticsConfigImpl(
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        recordFrames: null == recordFrames
            ? _value.recordFrames
            : recordFrames // ignore: cast_nullable_to_non_nullable
                  as bool,
        recordFreeze: null == recordFreeze
            ? _value.recordFreeze
            : recordFreeze // ignore: cast_nullable_to_non_nullable
                  as bool,
        recordDispatchers: null == recordDispatchers
            ? _value.recordDispatchers
            : recordDispatchers // ignore: cast_nullable_to_non_nullable
                  as bool,
        recordStartupTasks: null == recordStartupTasks
            ? _value.recordStartupTasks
            : recordStartupTasks // ignore: cast_nullable_to_non_nullable
                  as bool,
        frameBudget: null == frameBudget
            ? _value.frameBudget
            : frameBudget // ignore: cast_nullable_to_non_nullable
                  as Duration,
        freezeProbeInterval: null == freezeProbeInterval
            ? _value.freezeProbeInterval
            : freezeProbeInterval // ignore: cast_nullable_to_non_nullable
                  as Duration,
        freezeTolerance: null == freezeTolerance
            ? _value.freezeTolerance
            : freezeTolerance // ignore: cast_nullable_to_non_nullable
                  as Duration,
        dispatcherTimeout: null == dispatcherTimeout
            ? _value.dispatcherTimeout
            : dispatcherTimeout // ignore: cast_nullable_to_non_nullable
                  as Duration,
      ),
    );
  }
}

/// @nodoc

class _$AppDiagnosticsConfigImpl implements _AppDiagnosticsConfig {
  const _$AppDiagnosticsConfigImpl({
    this.enabled = false,
    this.recordFrames = true,
    this.recordFreeze = true,
    this.recordDispatchers = true,
    this.recordStartupTasks = true,
    this.frameBudget = const Duration(milliseconds: 16),
    this.freezeProbeInterval = const Duration(seconds: 3),
    this.freezeTolerance = const Duration(milliseconds: 300),
    this.dispatcherTimeout = const Duration(seconds: 5),
  });

  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final bool recordFrames;
  @override
  @JsonKey()
  final bool recordFreeze;
  @override
  @JsonKey()
  final bool recordDispatchers;
  @override
  @JsonKey()
  final bool recordStartupTasks;
  @override
  @JsonKey()
  final Duration frameBudget;
  @override
  @JsonKey()
  final Duration freezeProbeInterval;
  @override
  @JsonKey()
  final Duration freezeTolerance;
  @override
  @JsonKey()
  final Duration dispatcherTimeout;

  @override
  String toString() {
    return 'AppDiagnosticsConfig(enabled: $enabled, recordFrames: $recordFrames, recordFreeze: $recordFreeze, recordDispatchers: $recordDispatchers, recordStartupTasks: $recordStartupTasks, frameBudget: $frameBudget, freezeProbeInterval: $freezeProbeInterval, freezeTolerance: $freezeTolerance, dispatcherTimeout: $dispatcherTimeout)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppDiagnosticsConfigImpl &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.recordFrames, recordFrames) ||
                other.recordFrames == recordFrames) &&
            (identical(other.recordFreeze, recordFreeze) ||
                other.recordFreeze == recordFreeze) &&
            (identical(other.recordDispatchers, recordDispatchers) ||
                other.recordDispatchers == recordDispatchers) &&
            (identical(other.recordStartupTasks, recordStartupTasks) ||
                other.recordStartupTasks == recordStartupTasks) &&
            (identical(other.frameBudget, frameBudget) ||
                other.frameBudget == frameBudget) &&
            (identical(other.freezeProbeInterval, freezeProbeInterval) ||
                other.freezeProbeInterval == freezeProbeInterval) &&
            (identical(other.freezeTolerance, freezeTolerance) ||
                other.freezeTolerance == freezeTolerance) &&
            (identical(other.dispatcherTimeout, dispatcherTimeout) ||
                other.dispatcherTimeout == dispatcherTimeout));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    enabled,
    recordFrames,
    recordFreeze,
    recordDispatchers,
    recordStartupTasks,
    frameBudget,
    freezeProbeInterval,
    freezeTolerance,
    dispatcherTimeout,
  );

  /// Create a copy of AppDiagnosticsConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppDiagnosticsConfigImplCopyWith<_$AppDiagnosticsConfigImpl>
  get copyWith =>
      __$$AppDiagnosticsConfigImplCopyWithImpl<_$AppDiagnosticsConfigImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )
    $default, {
    required TResult Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )
    disabled,
  }) {
    return $default(
      enabled,
      recordFrames,
      recordFreeze,
      recordDispatchers,
      recordStartupTasks,
      frameBudget,
      freezeProbeInterval,
      freezeTolerance,
      dispatcherTimeout,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )?
    $default, {
    TResult? Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )?
    disabled,
  }) {
    return $default?.call(
      enabled,
      recordFrames,
      recordFreeze,
      recordDispatchers,
      recordStartupTasks,
      frameBudget,
      freezeProbeInterval,
      freezeTolerance,
      dispatcherTimeout,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )?
    $default, {
    TResult Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )?
    disabled,
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(
        enabled,
        recordFrames,
        recordFreeze,
        recordDispatchers,
        recordStartupTasks,
        frameBudget,
        freezeProbeInterval,
        freezeTolerance,
        dispatcherTimeout,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AppDiagnosticsConfig value) $default, {
    required TResult Function(_DisabledAppDiagnosticsConfig value) disabled,
  }) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AppDiagnosticsConfig value)? $default, {
    TResult? Function(_DisabledAppDiagnosticsConfig value)? disabled,
  }) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AppDiagnosticsConfig value)? $default, {
    TResult Function(_DisabledAppDiagnosticsConfig value)? disabled,
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }
}

abstract class _AppDiagnosticsConfig implements AppDiagnosticsConfig {
  const factory _AppDiagnosticsConfig({
    final bool enabled,
    final bool recordFrames,
    final bool recordFreeze,
    final bool recordDispatchers,
    final bool recordStartupTasks,
    final Duration frameBudget,
    final Duration freezeProbeInterval,
    final Duration freezeTolerance,
    final Duration dispatcherTimeout,
  }) = _$AppDiagnosticsConfigImpl;

  @override
  bool get enabled;
  @override
  bool get recordFrames;
  @override
  bool get recordFreeze;
  @override
  bool get recordDispatchers;
  @override
  bool get recordStartupTasks;
  @override
  Duration get frameBudget;
  @override
  Duration get freezeProbeInterval;
  @override
  Duration get freezeTolerance;
  @override
  Duration get dispatcherTimeout;

  /// Create a copy of AppDiagnosticsConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppDiagnosticsConfigImplCopyWith<_$AppDiagnosticsConfigImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DisabledAppDiagnosticsConfigImplCopyWith<$Res>
    implements $AppDiagnosticsConfigCopyWith<$Res> {
  factory _$$DisabledAppDiagnosticsConfigImplCopyWith(
    _$DisabledAppDiagnosticsConfigImpl value,
    $Res Function(_$DisabledAppDiagnosticsConfigImpl) then,
  ) = __$$DisabledAppDiagnosticsConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool enabled,
    bool recordFrames,
    bool recordFreeze,
    bool recordDispatchers,
    bool recordStartupTasks,
    Duration frameBudget,
    Duration freezeProbeInterval,
    Duration freezeTolerance,
    Duration dispatcherTimeout,
  });
}

/// @nodoc
class __$$DisabledAppDiagnosticsConfigImplCopyWithImpl<$Res>
    extends
        _$AppDiagnosticsConfigCopyWithImpl<
          $Res,
          _$DisabledAppDiagnosticsConfigImpl
        >
    implements _$$DisabledAppDiagnosticsConfigImplCopyWith<$Res> {
  __$$DisabledAppDiagnosticsConfigImplCopyWithImpl(
    _$DisabledAppDiagnosticsConfigImpl _value,
    $Res Function(_$DisabledAppDiagnosticsConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppDiagnosticsConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? recordFrames = null,
    Object? recordFreeze = null,
    Object? recordDispatchers = null,
    Object? recordStartupTasks = null,
    Object? frameBudget = null,
    Object? freezeProbeInterval = null,
    Object? freezeTolerance = null,
    Object? dispatcherTimeout = null,
  }) {
    return _then(
      _$DisabledAppDiagnosticsConfigImpl(
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        recordFrames: null == recordFrames
            ? _value.recordFrames
            : recordFrames // ignore: cast_nullable_to_non_nullable
                  as bool,
        recordFreeze: null == recordFreeze
            ? _value.recordFreeze
            : recordFreeze // ignore: cast_nullable_to_non_nullable
                  as bool,
        recordDispatchers: null == recordDispatchers
            ? _value.recordDispatchers
            : recordDispatchers // ignore: cast_nullable_to_non_nullable
                  as bool,
        recordStartupTasks: null == recordStartupTasks
            ? _value.recordStartupTasks
            : recordStartupTasks // ignore: cast_nullable_to_non_nullable
                  as bool,
        frameBudget: null == frameBudget
            ? _value.frameBudget
            : frameBudget // ignore: cast_nullable_to_non_nullable
                  as Duration,
        freezeProbeInterval: null == freezeProbeInterval
            ? _value.freezeProbeInterval
            : freezeProbeInterval // ignore: cast_nullable_to_non_nullable
                  as Duration,
        freezeTolerance: null == freezeTolerance
            ? _value.freezeTolerance
            : freezeTolerance // ignore: cast_nullable_to_non_nullable
                  as Duration,
        dispatcherTimeout: null == dispatcherTimeout
            ? _value.dispatcherTimeout
            : dispatcherTimeout // ignore: cast_nullable_to_non_nullable
                  as Duration,
      ),
    );
  }
}

/// @nodoc

class _$DisabledAppDiagnosticsConfigImpl
    implements _DisabledAppDiagnosticsConfig {
  const _$DisabledAppDiagnosticsConfigImpl({
    this.enabled = false,
    this.recordFrames = true,
    this.recordFreeze = true,
    this.recordDispatchers = true,
    this.recordStartupTasks = true,
    this.frameBudget = const Duration(milliseconds: 16),
    this.freezeProbeInterval = const Duration(seconds: 3),
    this.freezeTolerance = const Duration(milliseconds: 300),
    this.dispatcherTimeout = const Duration(seconds: 5),
  });

  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final bool recordFrames;
  @override
  @JsonKey()
  final bool recordFreeze;
  @override
  @JsonKey()
  final bool recordDispatchers;
  @override
  @JsonKey()
  final bool recordStartupTasks;
  @override
  @JsonKey()
  final Duration frameBudget;
  @override
  @JsonKey()
  final Duration freezeProbeInterval;
  @override
  @JsonKey()
  final Duration freezeTolerance;
  @override
  @JsonKey()
  final Duration dispatcherTimeout;

  @override
  String toString() {
    return 'AppDiagnosticsConfig.disabled(enabled: $enabled, recordFrames: $recordFrames, recordFreeze: $recordFreeze, recordDispatchers: $recordDispatchers, recordStartupTasks: $recordStartupTasks, frameBudget: $frameBudget, freezeProbeInterval: $freezeProbeInterval, freezeTolerance: $freezeTolerance, dispatcherTimeout: $dispatcherTimeout)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DisabledAppDiagnosticsConfigImpl &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.recordFrames, recordFrames) ||
                other.recordFrames == recordFrames) &&
            (identical(other.recordFreeze, recordFreeze) ||
                other.recordFreeze == recordFreeze) &&
            (identical(other.recordDispatchers, recordDispatchers) ||
                other.recordDispatchers == recordDispatchers) &&
            (identical(other.recordStartupTasks, recordStartupTasks) ||
                other.recordStartupTasks == recordStartupTasks) &&
            (identical(other.frameBudget, frameBudget) ||
                other.frameBudget == frameBudget) &&
            (identical(other.freezeProbeInterval, freezeProbeInterval) ||
                other.freezeProbeInterval == freezeProbeInterval) &&
            (identical(other.freezeTolerance, freezeTolerance) ||
                other.freezeTolerance == freezeTolerance) &&
            (identical(other.dispatcherTimeout, dispatcherTimeout) ||
                other.dispatcherTimeout == dispatcherTimeout));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    enabled,
    recordFrames,
    recordFreeze,
    recordDispatchers,
    recordStartupTasks,
    frameBudget,
    freezeProbeInterval,
    freezeTolerance,
    dispatcherTimeout,
  );

  /// Create a copy of AppDiagnosticsConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DisabledAppDiagnosticsConfigImplCopyWith<
    _$DisabledAppDiagnosticsConfigImpl
  >
  get copyWith =>
      __$$DisabledAppDiagnosticsConfigImplCopyWithImpl<
        _$DisabledAppDiagnosticsConfigImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )
    $default, {
    required TResult Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )
    disabled,
  }) {
    return disabled(
      enabled,
      recordFrames,
      recordFreeze,
      recordDispatchers,
      recordStartupTasks,
      frameBudget,
      freezeProbeInterval,
      freezeTolerance,
      dispatcherTimeout,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )?
    $default, {
    TResult? Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )?
    disabled,
  }) {
    return disabled?.call(
      enabled,
      recordFrames,
      recordFreeze,
      recordDispatchers,
      recordStartupTasks,
      frameBudget,
      freezeProbeInterval,
      freezeTolerance,
      dispatcherTimeout,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )?
    $default, {
    TResult Function(
      bool enabled,
      bool recordFrames,
      bool recordFreeze,
      bool recordDispatchers,
      bool recordStartupTasks,
      Duration frameBudget,
      Duration freezeProbeInterval,
      Duration freezeTolerance,
      Duration dispatcherTimeout,
    )?
    disabled,
    required TResult orElse(),
  }) {
    if (disabled != null) {
      return disabled(
        enabled,
        recordFrames,
        recordFreeze,
        recordDispatchers,
        recordStartupTasks,
        frameBudget,
        freezeProbeInterval,
        freezeTolerance,
        dispatcherTimeout,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AppDiagnosticsConfig value) $default, {
    required TResult Function(_DisabledAppDiagnosticsConfig value) disabled,
  }) {
    return disabled(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AppDiagnosticsConfig value)? $default, {
    TResult? Function(_DisabledAppDiagnosticsConfig value)? disabled,
  }) {
    return disabled?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AppDiagnosticsConfig value)? $default, {
    TResult Function(_DisabledAppDiagnosticsConfig value)? disabled,
    required TResult orElse(),
  }) {
    if (disabled != null) {
      return disabled(this);
    }
    return orElse();
  }
}

abstract class _DisabledAppDiagnosticsConfig implements AppDiagnosticsConfig {
  const factory _DisabledAppDiagnosticsConfig({
    final bool enabled,
    final bool recordFrames,
    final bool recordFreeze,
    final bool recordDispatchers,
    final bool recordStartupTasks,
    final Duration frameBudget,
    final Duration freezeProbeInterval,
    final Duration freezeTolerance,
    final Duration dispatcherTimeout,
  }) = _$DisabledAppDiagnosticsConfigImpl;

  @override
  bool get enabled;
  @override
  bool get recordFrames;
  @override
  bool get recordFreeze;
  @override
  bool get recordDispatchers;
  @override
  bool get recordStartupTasks;
  @override
  Duration get frameBudget;
  @override
  Duration get freezeProbeInterval;
  @override
  Duration get freezeTolerance;
  @override
  Duration get dispatcherTimeout;

  /// Create a copy of AppDiagnosticsConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DisabledAppDiagnosticsConfigImplCopyWith<
    _$DisabledAppDiagnosticsConfigImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AppDiagnosticEvent {
  AppDiagnosticEventKind get kind => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  DateTime get occurredAt => throw _privateConstructorUsedError;
  Duration? get duration => throw _privateConstructorUsedError;
  Duration? get threshold => throw _privateConstructorUsedError;
  Object? get error => throw _privateConstructorUsedError;
  StackTrace? get stackTrace => throw _privateConstructorUsedError;

  /// Create a copy of AppDiagnosticEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppDiagnosticEventCopyWith<AppDiagnosticEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppDiagnosticEventCopyWith<$Res> {
  factory $AppDiagnosticEventCopyWith(
    AppDiagnosticEvent value,
    $Res Function(AppDiagnosticEvent) then,
  ) = _$AppDiagnosticEventCopyWithImpl<$Res, AppDiagnosticEvent>;
  @useResult
  $Res call({
    AppDiagnosticEventKind kind,
    String source,
    String message,
    DateTime occurredAt,
    Duration? duration,
    Duration? threshold,
    Object? error,
    StackTrace? stackTrace,
  });
}

/// @nodoc
class _$AppDiagnosticEventCopyWithImpl<$Res, $Val extends AppDiagnosticEvent>
    implements $AppDiagnosticEventCopyWith<$Res> {
  _$AppDiagnosticEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppDiagnosticEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? source = null,
    Object? message = null,
    Object? occurredAt = null,
    Object? duration = freezed,
    Object? threshold = freezed,
    Object? error = freezed,
    Object? stackTrace = freezed,
  }) {
    return _then(
      _value.copyWith(
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as AppDiagnosticEventKind,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            occurredAt: null == occurredAt
                ? _value.occurredAt
                : occurredAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            duration: freezed == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as Duration?,
            threshold: freezed == threshold
                ? _value.threshold
                : threshold // ignore: cast_nullable_to_non_nullable
                      as Duration?,
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
abstract class _$$AppDiagnosticEventImplCopyWith<$Res>
    implements $AppDiagnosticEventCopyWith<$Res> {
  factory _$$AppDiagnosticEventImplCopyWith(
    _$AppDiagnosticEventImpl value,
    $Res Function(_$AppDiagnosticEventImpl) then,
  ) = __$$AppDiagnosticEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    AppDiagnosticEventKind kind,
    String source,
    String message,
    DateTime occurredAt,
    Duration? duration,
    Duration? threshold,
    Object? error,
    StackTrace? stackTrace,
  });
}

/// @nodoc
class __$$AppDiagnosticEventImplCopyWithImpl<$Res>
    extends _$AppDiagnosticEventCopyWithImpl<$Res, _$AppDiagnosticEventImpl>
    implements _$$AppDiagnosticEventImplCopyWith<$Res> {
  __$$AppDiagnosticEventImplCopyWithImpl(
    _$AppDiagnosticEventImpl _value,
    $Res Function(_$AppDiagnosticEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppDiagnosticEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? source = null,
    Object? message = null,
    Object? occurredAt = null,
    Object? duration = freezed,
    Object? threshold = freezed,
    Object? error = freezed,
    Object? stackTrace = freezed,
  }) {
    return _then(
      _$AppDiagnosticEventImpl(
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as AppDiagnosticEventKind,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        occurredAt: null == occurredAt
            ? _value.occurredAt
            : occurredAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        duration: freezed == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        threshold: freezed == threshold
            ? _value.threshold
            : threshold // ignore: cast_nullable_to_non_nullable
                  as Duration?,
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

class _$AppDiagnosticEventImpl extends _AppDiagnosticEvent {
  const _$AppDiagnosticEventImpl({
    required this.kind,
    required this.source,
    required this.message,
    required this.occurredAt,
    this.duration,
    this.threshold,
    this.error,
    this.stackTrace,
  }) : super._();

  @override
  final AppDiagnosticEventKind kind;
  @override
  final String source;
  @override
  final String message;
  @override
  final DateTime occurredAt;
  @override
  final Duration? duration;
  @override
  final Duration? threshold;
  @override
  final Object? error;
  @override
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'AppDiagnosticEvent(kind: $kind, source: $source, message: $message, occurredAt: $occurredAt, duration: $duration, threshold: $threshold, error: $error, stackTrace: $stackTrace)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppDiagnosticEventImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.occurredAt, occurredAt) ||
                other.occurredAt == occurredAt) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.threshold, threshold) ||
                other.threshold == threshold) &&
            const DeepCollectionEquality().equals(other.error, error) &&
            (identical(other.stackTrace, stackTrace) ||
                other.stackTrace == stackTrace));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    kind,
    source,
    message,
    occurredAt,
    duration,
    threshold,
    const DeepCollectionEquality().hash(error),
    stackTrace,
  );

  /// Create a copy of AppDiagnosticEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppDiagnosticEventImplCopyWith<_$AppDiagnosticEventImpl> get copyWith =>
      __$$AppDiagnosticEventImplCopyWithImpl<_$AppDiagnosticEventImpl>(
        this,
        _$identity,
      );
}

abstract class _AppDiagnosticEvent extends AppDiagnosticEvent {
  const factory _AppDiagnosticEvent({
    required final AppDiagnosticEventKind kind,
    required final String source,
    required final String message,
    required final DateTime occurredAt,
    final Duration? duration,
    final Duration? threshold,
    final Object? error,
    final StackTrace? stackTrace,
  }) = _$AppDiagnosticEventImpl;
  const _AppDiagnosticEvent._() : super._();

  @override
  AppDiagnosticEventKind get kind;
  @override
  String get source;
  @override
  String get message;
  @override
  DateTime get occurredAt;
  @override
  Duration? get duration;
  @override
  Duration? get threshold;
  @override
  Object? get error;
  @override
  StackTrace? get stackTrace;

  /// Create a copy of AppDiagnosticEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppDiagnosticEventImplCopyWith<_$AppDiagnosticEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
