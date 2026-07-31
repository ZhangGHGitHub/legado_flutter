// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AppError {
  String get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) network,
    required TResult Function(String field0) parse,
    required TResult Function(String field0) database,
    required TResult Function(String field0) jsExecution,
    required TResult Function(String field0) validation,
    required TResult Function(String field0) unsupported,
    required TResult Function(String field0) cancelled,
    required TResult Function(String field0) unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? network,
    TResult? Function(String field0)? parse,
    TResult? Function(String field0)? database,
    TResult? Function(String field0)? jsExecution,
    TResult? Function(String field0)? validation,
    TResult? Function(String field0)? unsupported,
    TResult? Function(String field0)? cancelled,
    TResult? Function(String field0)? unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? network,
    TResult Function(String field0)? parse,
    TResult Function(String field0)? database,
    TResult Function(String field0)? jsExecution,
    TResult Function(String field0)? validation,
    TResult Function(String field0)? unsupported,
    TResult Function(String field0)? cancelled,
    TResult Function(String field0)? unknown,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppError_Network value) network,
    required TResult Function(AppError_Parse value) parse,
    required TResult Function(AppError_Database value) database,
    required TResult Function(AppError_JsExecution value) jsExecution,
    required TResult Function(AppError_Validation value) validation,
    required TResult Function(AppError_Unsupported value) unsupported,
    required TResult Function(AppError_Cancelled value) cancelled,
    required TResult Function(AppError_Unknown value) unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppError_Network value)? network,
    TResult? Function(AppError_Parse value)? parse,
    TResult? Function(AppError_Database value)? database,
    TResult? Function(AppError_JsExecution value)? jsExecution,
    TResult? Function(AppError_Validation value)? validation,
    TResult? Function(AppError_Unsupported value)? unsupported,
    TResult? Function(AppError_Cancelled value)? cancelled,
    TResult? Function(AppError_Unknown value)? unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppError_Network value)? network,
    TResult Function(AppError_Parse value)? parse,
    TResult Function(AppError_Database value)? database,
    TResult Function(AppError_JsExecution value)? jsExecution,
    TResult Function(AppError_Validation value)? validation,
    TResult Function(AppError_Unsupported value)? unsupported,
    TResult Function(AppError_Cancelled value)? cancelled,
    TResult Function(AppError_Unknown value)? unknown,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppErrorCopyWith<AppError> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppErrorCopyWith<$Res> {
  factory $AppErrorCopyWith(AppError value, $Res Function(AppError) then) =
      _$AppErrorCopyWithImpl<$Res, AppError>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$AppErrorCopyWithImpl<$Res, $Val extends AppError>
    implements $AppErrorCopyWith<$Res> {
  _$AppErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _value.copyWith(
            field0: null == field0
                ? _value.field0
                : field0 // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppError_NetworkImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$AppError_NetworkImplCopyWith(
    _$AppError_NetworkImpl value,
    $Res Function(_$AppError_NetworkImpl) then,
  ) = __$$AppError_NetworkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$AppError_NetworkImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$AppError_NetworkImpl>
    implements _$$AppError_NetworkImplCopyWith<$Res> {
  __$$AppError_NetworkImplCopyWithImpl(
    _$AppError_NetworkImpl _value,
    $Res Function(_$AppError_NetworkImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$AppError_NetworkImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AppError_NetworkImpl extends AppError_Network {
  const _$AppError_NetworkImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'AppError.network(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppError_NetworkImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppError_NetworkImplCopyWith<_$AppError_NetworkImpl> get copyWith =>
      __$$AppError_NetworkImplCopyWithImpl<_$AppError_NetworkImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) network,
    required TResult Function(String field0) parse,
    required TResult Function(String field0) database,
    required TResult Function(String field0) jsExecution,
    required TResult Function(String field0) validation,
    required TResult Function(String field0) unsupported,
    required TResult Function(String field0) cancelled,
    required TResult Function(String field0) unknown,
  }) {
    return network(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? network,
    TResult? Function(String field0)? parse,
    TResult? Function(String field0)? database,
    TResult? Function(String field0)? jsExecution,
    TResult? Function(String field0)? validation,
    TResult? Function(String field0)? unsupported,
    TResult? Function(String field0)? cancelled,
    TResult? Function(String field0)? unknown,
  }) {
    return network?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? network,
    TResult Function(String field0)? parse,
    TResult Function(String field0)? database,
    TResult Function(String field0)? jsExecution,
    TResult Function(String field0)? validation,
    TResult Function(String field0)? unsupported,
    TResult Function(String field0)? cancelled,
    TResult Function(String field0)? unknown,
    required TResult orElse(),
  }) {
    if (network != null) {
      return network(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppError_Network value) network,
    required TResult Function(AppError_Parse value) parse,
    required TResult Function(AppError_Database value) database,
    required TResult Function(AppError_JsExecution value) jsExecution,
    required TResult Function(AppError_Validation value) validation,
    required TResult Function(AppError_Unsupported value) unsupported,
    required TResult Function(AppError_Cancelled value) cancelled,
    required TResult Function(AppError_Unknown value) unknown,
  }) {
    return network(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppError_Network value)? network,
    TResult? Function(AppError_Parse value)? parse,
    TResult? Function(AppError_Database value)? database,
    TResult? Function(AppError_JsExecution value)? jsExecution,
    TResult? Function(AppError_Validation value)? validation,
    TResult? Function(AppError_Unsupported value)? unsupported,
    TResult? Function(AppError_Cancelled value)? cancelled,
    TResult? Function(AppError_Unknown value)? unknown,
  }) {
    return network?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppError_Network value)? network,
    TResult Function(AppError_Parse value)? parse,
    TResult Function(AppError_Database value)? database,
    TResult Function(AppError_JsExecution value)? jsExecution,
    TResult Function(AppError_Validation value)? validation,
    TResult Function(AppError_Unsupported value)? unsupported,
    TResult Function(AppError_Cancelled value)? cancelled,
    TResult Function(AppError_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (network != null) {
      return network(this);
    }
    return orElse();
  }
}

abstract class AppError_Network extends AppError {
  const factory AppError_Network(final String field0) = _$AppError_NetworkImpl;
  const AppError_Network._() : super._();

  @override
  String get field0;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppError_NetworkImplCopyWith<_$AppError_NetworkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AppError_ParseImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$AppError_ParseImplCopyWith(
    _$AppError_ParseImpl value,
    $Res Function(_$AppError_ParseImpl) then,
  ) = __$$AppError_ParseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$AppError_ParseImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$AppError_ParseImpl>
    implements _$$AppError_ParseImplCopyWith<$Res> {
  __$$AppError_ParseImplCopyWithImpl(
    _$AppError_ParseImpl _value,
    $Res Function(_$AppError_ParseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$AppError_ParseImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AppError_ParseImpl extends AppError_Parse {
  const _$AppError_ParseImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'AppError.parse(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppError_ParseImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppError_ParseImplCopyWith<_$AppError_ParseImpl> get copyWith =>
      __$$AppError_ParseImplCopyWithImpl<_$AppError_ParseImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) network,
    required TResult Function(String field0) parse,
    required TResult Function(String field0) database,
    required TResult Function(String field0) jsExecution,
    required TResult Function(String field0) validation,
    required TResult Function(String field0) unsupported,
    required TResult Function(String field0) cancelled,
    required TResult Function(String field0) unknown,
  }) {
    return parse(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? network,
    TResult? Function(String field0)? parse,
    TResult? Function(String field0)? database,
    TResult? Function(String field0)? jsExecution,
    TResult? Function(String field0)? validation,
    TResult? Function(String field0)? unsupported,
    TResult? Function(String field0)? cancelled,
    TResult? Function(String field0)? unknown,
  }) {
    return parse?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? network,
    TResult Function(String field0)? parse,
    TResult Function(String field0)? database,
    TResult Function(String field0)? jsExecution,
    TResult Function(String field0)? validation,
    TResult Function(String field0)? unsupported,
    TResult Function(String field0)? cancelled,
    TResult Function(String field0)? unknown,
    required TResult orElse(),
  }) {
    if (parse != null) {
      return parse(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppError_Network value) network,
    required TResult Function(AppError_Parse value) parse,
    required TResult Function(AppError_Database value) database,
    required TResult Function(AppError_JsExecution value) jsExecution,
    required TResult Function(AppError_Validation value) validation,
    required TResult Function(AppError_Unsupported value) unsupported,
    required TResult Function(AppError_Cancelled value) cancelled,
    required TResult Function(AppError_Unknown value) unknown,
  }) {
    return parse(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppError_Network value)? network,
    TResult? Function(AppError_Parse value)? parse,
    TResult? Function(AppError_Database value)? database,
    TResult? Function(AppError_JsExecution value)? jsExecution,
    TResult? Function(AppError_Validation value)? validation,
    TResult? Function(AppError_Unsupported value)? unsupported,
    TResult? Function(AppError_Cancelled value)? cancelled,
    TResult? Function(AppError_Unknown value)? unknown,
  }) {
    return parse?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppError_Network value)? network,
    TResult Function(AppError_Parse value)? parse,
    TResult Function(AppError_Database value)? database,
    TResult Function(AppError_JsExecution value)? jsExecution,
    TResult Function(AppError_Validation value)? validation,
    TResult Function(AppError_Unsupported value)? unsupported,
    TResult Function(AppError_Cancelled value)? cancelled,
    TResult Function(AppError_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (parse != null) {
      return parse(this);
    }
    return orElse();
  }
}

abstract class AppError_Parse extends AppError {
  const factory AppError_Parse(final String field0) = _$AppError_ParseImpl;
  const AppError_Parse._() : super._();

  @override
  String get field0;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppError_ParseImplCopyWith<_$AppError_ParseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AppError_DatabaseImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$AppError_DatabaseImplCopyWith(
    _$AppError_DatabaseImpl value,
    $Res Function(_$AppError_DatabaseImpl) then,
  ) = __$$AppError_DatabaseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$AppError_DatabaseImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$AppError_DatabaseImpl>
    implements _$$AppError_DatabaseImplCopyWith<$Res> {
  __$$AppError_DatabaseImplCopyWithImpl(
    _$AppError_DatabaseImpl _value,
    $Res Function(_$AppError_DatabaseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$AppError_DatabaseImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AppError_DatabaseImpl extends AppError_Database {
  const _$AppError_DatabaseImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'AppError.database(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppError_DatabaseImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppError_DatabaseImplCopyWith<_$AppError_DatabaseImpl> get copyWith =>
      __$$AppError_DatabaseImplCopyWithImpl<_$AppError_DatabaseImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) network,
    required TResult Function(String field0) parse,
    required TResult Function(String field0) database,
    required TResult Function(String field0) jsExecution,
    required TResult Function(String field0) validation,
    required TResult Function(String field0) unsupported,
    required TResult Function(String field0) cancelled,
    required TResult Function(String field0) unknown,
  }) {
    return database(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? network,
    TResult? Function(String field0)? parse,
    TResult? Function(String field0)? database,
    TResult? Function(String field0)? jsExecution,
    TResult? Function(String field0)? validation,
    TResult? Function(String field0)? unsupported,
    TResult? Function(String field0)? cancelled,
    TResult? Function(String field0)? unknown,
  }) {
    return database?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? network,
    TResult Function(String field0)? parse,
    TResult Function(String field0)? database,
    TResult Function(String field0)? jsExecution,
    TResult Function(String field0)? validation,
    TResult Function(String field0)? unsupported,
    TResult Function(String field0)? cancelled,
    TResult Function(String field0)? unknown,
    required TResult orElse(),
  }) {
    if (database != null) {
      return database(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppError_Network value) network,
    required TResult Function(AppError_Parse value) parse,
    required TResult Function(AppError_Database value) database,
    required TResult Function(AppError_JsExecution value) jsExecution,
    required TResult Function(AppError_Validation value) validation,
    required TResult Function(AppError_Unsupported value) unsupported,
    required TResult Function(AppError_Cancelled value) cancelled,
    required TResult Function(AppError_Unknown value) unknown,
  }) {
    return database(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppError_Network value)? network,
    TResult? Function(AppError_Parse value)? parse,
    TResult? Function(AppError_Database value)? database,
    TResult? Function(AppError_JsExecution value)? jsExecution,
    TResult? Function(AppError_Validation value)? validation,
    TResult? Function(AppError_Unsupported value)? unsupported,
    TResult? Function(AppError_Cancelled value)? cancelled,
    TResult? Function(AppError_Unknown value)? unknown,
  }) {
    return database?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppError_Network value)? network,
    TResult Function(AppError_Parse value)? parse,
    TResult Function(AppError_Database value)? database,
    TResult Function(AppError_JsExecution value)? jsExecution,
    TResult Function(AppError_Validation value)? validation,
    TResult Function(AppError_Unsupported value)? unsupported,
    TResult Function(AppError_Cancelled value)? cancelled,
    TResult Function(AppError_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (database != null) {
      return database(this);
    }
    return orElse();
  }
}

abstract class AppError_Database extends AppError {
  const factory AppError_Database(final String field0) =
      _$AppError_DatabaseImpl;
  const AppError_Database._() : super._();

  @override
  String get field0;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppError_DatabaseImplCopyWith<_$AppError_DatabaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AppError_JsExecutionImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$AppError_JsExecutionImplCopyWith(
    _$AppError_JsExecutionImpl value,
    $Res Function(_$AppError_JsExecutionImpl) then,
  ) = __$$AppError_JsExecutionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$AppError_JsExecutionImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$AppError_JsExecutionImpl>
    implements _$$AppError_JsExecutionImplCopyWith<$Res> {
  __$$AppError_JsExecutionImplCopyWithImpl(
    _$AppError_JsExecutionImpl _value,
    $Res Function(_$AppError_JsExecutionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$AppError_JsExecutionImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AppError_JsExecutionImpl extends AppError_JsExecution {
  const _$AppError_JsExecutionImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'AppError.jsExecution(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppError_JsExecutionImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppError_JsExecutionImplCopyWith<_$AppError_JsExecutionImpl>
  get copyWith =>
      __$$AppError_JsExecutionImplCopyWithImpl<_$AppError_JsExecutionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) network,
    required TResult Function(String field0) parse,
    required TResult Function(String field0) database,
    required TResult Function(String field0) jsExecution,
    required TResult Function(String field0) validation,
    required TResult Function(String field0) unsupported,
    required TResult Function(String field0) cancelled,
    required TResult Function(String field0) unknown,
  }) {
    return jsExecution(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? network,
    TResult? Function(String field0)? parse,
    TResult? Function(String field0)? database,
    TResult? Function(String field0)? jsExecution,
    TResult? Function(String field0)? validation,
    TResult? Function(String field0)? unsupported,
    TResult? Function(String field0)? cancelled,
    TResult? Function(String field0)? unknown,
  }) {
    return jsExecution?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? network,
    TResult Function(String field0)? parse,
    TResult Function(String field0)? database,
    TResult Function(String field0)? jsExecution,
    TResult Function(String field0)? validation,
    TResult Function(String field0)? unsupported,
    TResult Function(String field0)? cancelled,
    TResult Function(String field0)? unknown,
    required TResult orElse(),
  }) {
    if (jsExecution != null) {
      return jsExecution(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppError_Network value) network,
    required TResult Function(AppError_Parse value) parse,
    required TResult Function(AppError_Database value) database,
    required TResult Function(AppError_JsExecution value) jsExecution,
    required TResult Function(AppError_Validation value) validation,
    required TResult Function(AppError_Unsupported value) unsupported,
    required TResult Function(AppError_Cancelled value) cancelled,
    required TResult Function(AppError_Unknown value) unknown,
  }) {
    return jsExecution(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppError_Network value)? network,
    TResult? Function(AppError_Parse value)? parse,
    TResult? Function(AppError_Database value)? database,
    TResult? Function(AppError_JsExecution value)? jsExecution,
    TResult? Function(AppError_Validation value)? validation,
    TResult? Function(AppError_Unsupported value)? unsupported,
    TResult? Function(AppError_Cancelled value)? cancelled,
    TResult? Function(AppError_Unknown value)? unknown,
  }) {
    return jsExecution?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppError_Network value)? network,
    TResult Function(AppError_Parse value)? parse,
    TResult Function(AppError_Database value)? database,
    TResult Function(AppError_JsExecution value)? jsExecution,
    TResult Function(AppError_Validation value)? validation,
    TResult Function(AppError_Unsupported value)? unsupported,
    TResult Function(AppError_Cancelled value)? cancelled,
    TResult Function(AppError_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (jsExecution != null) {
      return jsExecution(this);
    }
    return orElse();
  }
}

abstract class AppError_JsExecution extends AppError {
  const factory AppError_JsExecution(final String field0) =
      _$AppError_JsExecutionImpl;
  const AppError_JsExecution._() : super._();

  @override
  String get field0;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppError_JsExecutionImplCopyWith<_$AppError_JsExecutionImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AppError_ValidationImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$AppError_ValidationImplCopyWith(
    _$AppError_ValidationImpl value,
    $Res Function(_$AppError_ValidationImpl) then,
  ) = __$$AppError_ValidationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$AppError_ValidationImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$AppError_ValidationImpl>
    implements _$$AppError_ValidationImplCopyWith<$Res> {
  __$$AppError_ValidationImplCopyWithImpl(
    _$AppError_ValidationImpl _value,
    $Res Function(_$AppError_ValidationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$AppError_ValidationImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AppError_ValidationImpl extends AppError_Validation {
  const _$AppError_ValidationImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'AppError.validation(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppError_ValidationImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppError_ValidationImplCopyWith<_$AppError_ValidationImpl> get copyWith =>
      __$$AppError_ValidationImplCopyWithImpl<_$AppError_ValidationImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) network,
    required TResult Function(String field0) parse,
    required TResult Function(String field0) database,
    required TResult Function(String field0) jsExecution,
    required TResult Function(String field0) validation,
    required TResult Function(String field0) unsupported,
    required TResult Function(String field0) cancelled,
    required TResult Function(String field0) unknown,
  }) {
    return validation(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? network,
    TResult? Function(String field0)? parse,
    TResult? Function(String field0)? database,
    TResult? Function(String field0)? jsExecution,
    TResult? Function(String field0)? validation,
    TResult? Function(String field0)? unsupported,
    TResult? Function(String field0)? cancelled,
    TResult? Function(String field0)? unknown,
  }) {
    return validation?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? network,
    TResult Function(String field0)? parse,
    TResult Function(String field0)? database,
    TResult Function(String field0)? jsExecution,
    TResult Function(String field0)? validation,
    TResult Function(String field0)? unsupported,
    TResult Function(String field0)? cancelled,
    TResult Function(String field0)? unknown,
    required TResult orElse(),
  }) {
    if (validation != null) {
      return validation(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppError_Network value) network,
    required TResult Function(AppError_Parse value) parse,
    required TResult Function(AppError_Database value) database,
    required TResult Function(AppError_JsExecution value) jsExecution,
    required TResult Function(AppError_Validation value) validation,
    required TResult Function(AppError_Unsupported value) unsupported,
    required TResult Function(AppError_Cancelled value) cancelled,
    required TResult Function(AppError_Unknown value) unknown,
  }) {
    return validation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppError_Network value)? network,
    TResult? Function(AppError_Parse value)? parse,
    TResult? Function(AppError_Database value)? database,
    TResult? Function(AppError_JsExecution value)? jsExecution,
    TResult? Function(AppError_Validation value)? validation,
    TResult? Function(AppError_Unsupported value)? unsupported,
    TResult? Function(AppError_Cancelled value)? cancelled,
    TResult? Function(AppError_Unknown value)? unknown,
  }) {
    return validation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppError_Network value)? network,
    TResult Function(AppError_Parse value)? parse,
    TResult Function(AppError_Database value)? database,
    TResult Function(AppError_JsExecution value)? jsExecution,
    TResult Function(AppError_Validation value)? validation,
    TResult Function(AppError_Unsupported value)? unsupported,
    TResult Function(AppError_Cancelled value)? cancelled,
    TResult Function(AppError_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (validation != null) {
      return validation(this);
    }
    return orElse();
  }
}

abstract class AppError_Validation extends AppError {
  const factory AppError_Validation(final String field0) =
      _$AppError_ValidationImpl;
  const AppError_Validation._() : super._();

  @override
  String get field0;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppError_ValidationImplCopyWith<_$AppError_ValidationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AppError_UnsupportedImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$AppError_UnsupportedImplCopyWith(
    _$AppError_UnsupportedImpl value,
    $Res Function(_$AppError_UnsupportedImpl) then,
  ) = __$$AppError_UnsupportedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$AppError_UnsupportedImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$AppError_UnsupportedImpl>
    implements _$$AppError_UnsupportedImplCopyWith<$Res> {
  __$$AppError_UnsupportedImplCopyWithImpl(
    _$AppError_UnsupportedImpl _value,
    $Res Function(_$AppError_UnsupportedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$AppError_UnsupportedImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AppError_UnsupportedImpl extends AppError_Unsupported {
  const _$AppError_UnsupportedImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'AppError.unsupported(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppError_UnsupportedImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppError_UnsupportedImplCopyWith<_$AppError_UnsupportedImpl>
  get copyWith =>
      __$$AppError_UnsupportedImplCopyWithImpl<_$AppError_UnsupportedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) network,
    required TResult Function(String field0) parse,
    required TResult Function(String field0) database,
    required TResult Function(String field0) jsExecution,
    required TResult Function(String field0) validation,
    required TResult Function(String field0) unsupported,
    required TResult Function(String field0) cancelled,
    required TResult Function(String field0) unknown,
  }) {
    return unsupported(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? network,
    TResult? Function(String field0)? parse,
    TResult? Function(String field0)? database,
    TResult? Function(String field0)? jsExecution,
    TResult? Function(String field0)? validation,
    TResult? Function(String field0)? unsupported,
    TResult? Function(String field0)? cancelled,
    TResult? Function(String field0)? unknown,
  }) {
    return unsupported?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? network,
    TResult Function(String field0)? parse,
    TResult Function(String field0)? database,
    TResult Function(String field0)? jsExecution,
    TResult Function(String field0)? validation,
    TResult Function(String field0)? unsupported,
    TResult Function(String field0)? cancelled,
    TResult Function(String field0)? unknown,
    required TResult orElse(),
  }) {
    if (unsupported != null) {
      return unsupported(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppError_Network value) network,
    required TResult Function(AppError_Parse value) parse,
    required TResult Function(AppError_Database value) database,
    required TResult Function(AppError_JsExecution value) jsExecution,
    required TResult Function(AppError_Validation value) validation,
    required TResult Function(AppError_Unsupported value) unsupported,
    required TResult Function(AppError_Cancelled value) cancelled,
    required TResult Function(AppError_Unknown value) unknown,
  }) {
    return unsupported(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppError_Network value)? network,
    TResult? Function(AppError_Parse value)? parse,
    TResult? Function(AppError_Database value)? database,
    TResult? Function(AppError_JsExecution value)? jsExecution,
    TResult? Function(AppError_Validation value)? validation,
    TResult? Function(AppError_Unsupported value)? unsupported,
    TResult? Function(AppError_Cancelled value)? cancelled,
    TResult? Function(AppError_Unknown value)? unknown,
  }) {
    return unsupported?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppError_Network value)? network,
    TResult Function(AppError_Parse value)? parse,
    TResult Function(AppError_Database value)? database,
    TResult Function(AppError_JsExecution value)? jsExecution,
    TResult Function(AppError_Validation value)? validation,
    TResult Function(AppError_Unsupported value)? unsupported,
    TResult Function(AppError_Cancelled value)? cancelled,
    TResult Function(AppError_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (unsupported != null) {
      return unsupported(this);
    }
    return orElse();
  }
}

abstract class AppError_Unsupported extends AppError {
  const factory AppError_Unsupported(final String field0) =
      _$AppError_UnsupportedImpl;
  const AppError_Unsupported._() : super._();

  @override
  String get field0;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppError_UnsupportedImplCopyWith<_$AppError_UnsupportedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AppError_CancelledImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$AppError_CancelledImplCopyWith(
    _$AppError_CancelledImpl value,
    $Res Function(_$AppError_CancelledImpl) then,
  ) = __$$AppError_CancelledImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$AppError_CancelledImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$AppError_CancelledImpl>
    implements _$$AppError_CancelledImplCopyWith<$Res> {
  __$$AppError_CancelledImplCopyWithImpl(
    _$AppError_CancelledImpl _value,
    $Res Function(_$AppError_CancelledImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$AppError_CancelledImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AppError_CancelledImpl extends AppError_Cancelled {
  const _$AppError_CancelledImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'AppError.cancelled(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppError_CancelledImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppError_CancelledImplCopyWith<_$AppError_CancelledImpl> get copyWith =>
      __$$AppError_CancelledImplCopyWithImpl<_$AppError_CancelledImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) network,
    required TResult Function(String field0) parse,
    required TResult Function(String field0) database,
    required TResult Function(String field0) jsExecution,
    required TResult Function(String field0) validation,
    required TResult Function(String field0) unsupported,
    required TResult Function(String field0) cancelled,
    required TResult Function(String field0) unknown,
  }) {
    return cancelled(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? network,
    TResult? Function(String field0)? parse,
    TResult? Function(String field0)? database,
    TResult? Function(String field0)? jsExecution,
    TResult? Function(String field0)? validation,
    TResult? Function(String field0)? unsupported,
    TResult? Function(String field0)? cancelled,
    TResult? Function(String field0)? unknown,
  }) {
    return cancelled?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? network,
    TResult Function(String field0)? parse,
    TResult Function(String field0)? database,
    TResult Function(String field0)? jsExecution,
    TResult Function(String field0)? validation,
    TResult Function(String field0)? unsupported,
    TResult Function(String field0)? cancelled,
    TResult Function(String field0)? unknown,
    required TResult orElse(),
  }) {
    if (cancelled != null) {
      return cancelled(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppError_Network value) network,
    required TResult Function(AppError_Parse value) parse,
    required TResult Function(AppError_Database value) database,
    required TResult Function(AppError_JsExecution value) jsExecution,
    required TResult Function(AppError_Validation value) validation,
    required TResult Function(AppError_Unsupported value) unsupported,
    required TResult Function(AppError_Cancelled value) cancelled,
    required TResult Function(AppError_Unknown value) unknown,
  }) {
    return cancelled(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppError_Network value)? network,
    TResult? Function(AppError_Parse value)? parse,
    TResult? Function(AppError_Database value)? database,
    TResult? Function(AppError_JsExecution value)? jsExecution,
    TResult? Function(AppError_Validation value)? validation,
    TResult? Function(AppError_Unsupported value)? unsupported,
    TResult? Function(AppError_Cancelled value)? cancelled,
    TResult? Function(AppError_Unknown value)? unknown,
  }) {
    return cancelled?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppError_Network value)? network,
    TResult Function(AppError_Parse value)? parse,
    TResult Function(AppError_Database value)? database,
    TResult Function(AppError_JsExecution value)? jsExecution,
    TResult Function(AppError_Validation value)? validation,
    TResult Function(AppError_Unsupported value)? unsupported,
    TResult Function(AppError_Cancelled value)? cancelled,
    TResult Function(AppError_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (cancelled != null) {
      return cancelled(this);
    }
    return orElse();
  }
}

abstract class AppError_Cancelled extends AppError {
  const factory AppError_Cancelled(final String field0) =
      _$AppError_CancelledImpl;
  const AppError_Cancelled._() : super._();

  @override
  String get field0;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppError_CancelledImplCopyWith<_$AppError_CancelledImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AppError_UnknownImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$AppError_UnknownImplCopyWith(
    _$AppError_UnknownImpl value,
    $Res Function(_$AppError_UnknownImpl) then,
  ) = __$$AppError_UnknownImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$AppError_UnknownImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$AppError_UnknownImpl>
    implements _$$AppError_UnknownImplCopyWith<$Res> {
  __$$AppError_UnknownImplCopyWithImpl(
    _$AppError_UnknownImpl _value,
    $Res Function(_$AppError_UnknownImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$AppError_UnknownImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AppError_UnknownImpl extends AppError_Unknown {
  const _$AppError_UnknownImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'AppError.unknown(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppError_UnknownImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppError_UnknownImplCopyWith<_$AppError_UnknownImpl> get copyWith =>
      __$$AppError_UnknownImplCopyWithImpl<_$AppError_UnknownImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) network,
    required TResult Function(String field0) parse,
    required TResult Function(String field0) database,
    required TResult Function(String field0) jsExecution,
    required TResult Function(String field0) validation,
    required TResult Function(String field0) unsupported,
    required TResult Function(String field0) cancelled,
    required TResult Function(String field0) unknown,
  }) {
    return unknown(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? network,
    TResult? Function(String field0)? parse,
    TResult? Function(String field0)? database,
    TResult? Function(String field0)? jsExecution,
    TResult? Function(String field0)? validation,
    TResult? Function(String field0)? unsupported,
    TResult? Function(String field0)? cancelled,
    TResult? Function(String field0)? unknown,
  }) {
    return unknown?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? network,
    TResult Function(String field0)? parse,
    TResult Function(String field0)? database,
    TResult Function(String field0)? jsExecution,
    TResult Function(String field0)? validation,
    TResult Function(String field0)? unsupported,
    TResult Function(String field0)? cancelled,
    TResult Function(String field0)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppError_Network value) network,
    required TResult Function(AppError_Parse value) parse,
    required TResult Function(AppError_Database value) database,
    required TResult Function(AppError_JsExecution value) jsExecution,
    required TResult Function(AppError_Validation value) validation,
    required TResult Function(AppError_Unsupported value) unsupported,
    required TResult Function(AppError_Cancelled value) cancelled,
    required TResult Function(AppError_Unknown value) unknown,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppError_Network value)? network,
    TResult? Function(AppError_Parse value)? parse,
    TResult? Function(AppError_Database value)? database,
    TResult? Function(AppError_JsExecution value)? jsExecution,
    TResult? Function(AppError_Validation value)? validation,
    TResult? Function(AppError_Unsupported value)? unsupported,
    TResult? Function(AppError_Cancelled value)? cancelled,
    TResult? Function(AppError_Unknown value)? unknown,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppError_Network value)? network,
    TResult Function(AppError_Parse value)? parse,
    TResult Function(AppError_Database value)? database,
    TResult Function(AppError_JsExecution value)? jsExecution,
    TResult Function(AppError_Validation value)? validation,
    TResult Function(AppError_Unsupported value)? unsupported,
    TResult Function(AppError_Cancelled value)? cancelled,
    TResult Function(AppError_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }
}

abstract class AppError_Unknown extends AppError {
  const factory AppError_Unknown(final String field0) = _$AppError_UnknownImpl;
  const AppError_Unknown._() : super._();

  @override
  String get field0;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppError_UnknownImplCopyWith<_$AppError_UnknownImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
