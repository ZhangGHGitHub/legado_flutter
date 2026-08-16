// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_local_file_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LocalBackupEntry {
  String get name => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;

  /// Create a copy of LocalBackupEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocalBackupEntryCopyWith<LocalBackupEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocalBackupEntryCopyWith<$Res> {
  factory $LocalBackupEntryCopyWith(
    LocalBackupEntry value,
    $Res Function(LocalBackupEntry) then,
  ) = _$LocalBackupEntryCopyWithImpl<$Res, LocalBackupEntry>;
  @useResult
  $Res call({String name, String path});
}

/// @nodoc
class _$LocalBackupEntryCopyWithImpl<$Res, $Val extends LocalBackupEntry>
    implements $LocalBackupEntryCopyWith<$Res> {
  _$LocalBackupEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocalBackupEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? name = null, Object? path = null}) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            path: null == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LocalBackupEntryImplCopyWith<$Res>
    implements $LocalBackupEntryCopyWith<$Res> {
  factory _$$LocalBackupEntryImplCopyWith(
    _$LocalBackupEntryImpl value,
    $Res Function(_$LocalBackupEntryImpl) then,
  ) = __$$LocalBackupEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String path});
}

/// @nodoc
class __$$LocalBackupEntryImplCopyWithImpl<$Res>
    extends _$LocalBackupEntryCopyWithImpl<$Res, _$LocalBackupEntryImpl>
    implements _$$LocalBackupEntryImplCopyWith<$Res> {
  __$$LocalBackupEntryImplCopyWithImpl(
    _$LocalBackupEntryImpl _value,
    $Res Function(_$LocalBackupEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocalBackupEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? name = null, Object? path = null}) {
    return _then(
      _$LocalBackupEntryImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        path: null == path
            ? _value.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$LocalBackupEntryImpl implements _LocalBackupEntry {
  const _$LocalBackupEntryImpl({required this.name, required this.path});

  @override
  final String name;
  @override
  final String path;

  @override
  String toString() {
    return 'LocalBackupEntry(name: $name, path: $path)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalBackupEntryImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, path);

  /// Create a copy of LocalBackupEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocalBackupEntryImplCopyWith<_$LocalBackupEntryImpl> get copyWith =>
      __$$LocalBackupEntryImplCopyWithImpl<_$LocalBackupEntryImpl>(
        this,
        _$identity,
      );
}

abstract class _LocalBackupEntry implements LocalBackupEntry {
  const factory _LocalBackupEntry({
    required final String name,
    required final String path,
  }) = _$LocalBackupEntryImpl;

  @override
  String get name;
  @override
  String get path;

  /// Create a copy of LocalBackupEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocalBackupEntryImplCopyWith<_$LocalBackupEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
