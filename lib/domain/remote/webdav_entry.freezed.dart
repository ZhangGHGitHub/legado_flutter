// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'webdav_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$WebDavEntry {
  String get name => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  bool get isDir => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;
  int get lastModified => throw _privateConstructorUsedError;
  String? get etag => throw _privateConstructorUsedError;

  /// Create a copy of WebDavEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WebDavEntryCopyWith<WebDavEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebDavEntryCopyWith<$Res> {
  factory $WebDavEntryCopyWith(
    WebDavEntry value,
    $Res Function(WebDavEntry) then,
  ) = _$WebDavEntryCopyWithImpl<$Res, WebDavEntry>;
  @useResult
  $Res call({
    String name,
    String path,
    bool isDir,
    int size,
    int lastModified,
    String? etag,
  });
}

/// @nodoc
class _$WebDavEntryCopyWithImpl<$Res, $Val extends WebDavEntry>
    implements $WebDavEntryCopyWith<$Res> {
  _$WebDavEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WebDavEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? path = null,
    Object? isDir = null,
    Object? size = null,
    Object? lastModified = null,
    Object? etag = freezed,
  }) {
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
            isDir: null == isDir
                ? _value.isDir
                : isDir // ignore: cast_nullable_to_non_nullable
                      as bool,
            size: null == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                      as int,
            lastModified: null == lastModified
                ? _value.lastModified
                : lastModified // ignore: cast_nullable_to_non_nullable
                      as int,
            etag: freezed == etag
                ? _value.etag
                : etag // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WebDavEntryImplCopyWith<$Res>
    implements $WebDavEntryCopyWith<$Res> {
  factory _$$WebDavEntryImplCopyWith(
    _$WebDavEntryImpl value,
    $Res Function(_$WebDavEntryImpl) then,
  ) = __$$WebDavEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String path,
    bool isDir,
    int size,
    int lastModified,
    String? etag,
  });
}

/// @nodoc
class __$$WebDavEntryImplCopyWithImpl<$Res>
    extends _$WebDavEntryCopyWithImpl<$Res, _$WebDavEntryImpl>
    implements _$$WebDavEntryImplCopyWith<$Res> {
  __$$WebDavEntryImplCopyWithImpl(
    _$WebDavEntryImpl _value,
    $Res Function(_$WebDavEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WebDavEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? path = null,
    Object? isDir = null,
    Object? size = null,
    Object? lastModified = null,
    Object? etag = freezed,
  }) {
    return _then(
      _$WebDavEntryImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        path: null == path
            ? _value.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String,
        isDir: null == isDir
            ? _value.isDir
            : isDir // ignore: cast_nullable_to_non_nullable
                  as bool,
        size: null == size
            ? _value.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int,
        lastModified: null == lastModified
            ? _value.lastModified
            : lastModified // ignore: cast_nullable_to_non_nullable
                  as int,
        etag: freezed == etag
            ? _value.etag
            : etag // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$WebDavEntryImpl implements _WebDavEntry {
  const _$WebDavEntryImpl({
    required this.name,
    required this.path,
    required this.isDir,
    required this.size,
    required this.lastModified,
    this.etag,
  });

  @override
  final String name;
  @override
  final String path;
  @override
  final bool isDir;
  @override
  final int size;
  @override
  final int lastModified;
  @override
  final String? etag;

  @override
  String toString() {
    return 'WebDavEntry(name: $name, path: $path, isDir: $isDir, size: $size, lastModified: $lastModified, etag: $etag)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebDavEntryImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.isDir, isDir) || other.isDir == isDir) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.lastModified, lastModified) ||
                other.lastModified == lastModified) &&
            (identical(other.etag, etag) || other.etag == etag));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, name, path, isDir, size, lastModified, etag);

  /// Create a copy of WebDavEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WebDavEntryImplCopyWith<_$WebDavEntryImpl> get copyWith =>
      __$$WebDavEntryImplCopyWithImpl<_$WebDavEntryImpl>(this, _$identity);
}

abstract class _WebDavEntry implements WebDavEntry {
  const factory _WebDavEntry({
    required final String name,
    required final String path,
    required final bool isDir,
    required final int size,
    required final int lastModified,
    final String? etag,
  }) = _$WebDavEntryImpl;

  @override
  String get name;
  @override
  String get path;
  @override
  bool get isDir;
  @override
  int get size;
  @override
  int get lastModified;
  @override
  String? get etag;

  /// Create a copy of WebDavEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WebDavEntryImplCopyWith<_$WebDavEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
