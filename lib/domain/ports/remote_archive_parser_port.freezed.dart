// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'remote_archive_parser_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RemoteArchiveBookFile {
  String get relativePath => throw _privateConstructorUsedError;
  List<int> get bytes => throw _privateConstructorUsedError;

  /// Create a copy of RemoteArchiveBookFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RemoteArchiveBookFileCopyWith<RemoteArchiveBookFile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RemoteArchiveBookFileCopyWith<$Res> {
  factory $RemoteArchiveBookFileCopyWith(
    RemoteArchiveBookFile value,
    $Res Function(RemoteArchiveBookFile) then,
  ) = _$RemoteArchiveBookFileCopyWithImpl<$Res, RemoteArchiveBookFile>;
  @useResult
  $Res call({String relativePath, List<int> bytes});
}

/// @nodoc
class _$RemoteArchiveBookFileCopyWithImpl<
  $Res,
  $Val extends RemoteArchiveBookFile
>
    implements $RemoteArchiveBookFileCopyWith<$Res> {
  _$RemoteArchiveBookFileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RemoteArchiveBookFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? relativePath = null, Object? bytes = null}) {
    return _then(
      _value.copyWith(
            relativePath: null == relativePath
                ? _value.relativePath
                : relativePath // ignore: cast_nullable_to_non_nullable
                      as String,
            bytes: null == bytes
                ? _value.bytes
                : bytes // ignore: cast_nullable_to_non_nullable
                      as List<int>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RemoteArchiveBookFileImplCopyWith<$Res>
    implements $RemoteArchiveBookFileCopyWith<$Res> {
  factory _$$RemoteArchiveBookFileImplCopyWith(
    _$RemoteArchiveBookFileImpl value,
    $Res Function(_$RemoteArchiveBookFileImpl) then,
  ) = __$$RemoteArchiveBookFileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String relativePath, List<int> bytes});
}

/// @nodoc
class __$$RemoteArchiveBookFileImplCopyWithImpl<$Res>
    extends
        _$RemoteArchiveBookFileCopyWithImpl<$Res, _$RemoteArchiveBookFileImpl>
    implements _$$RemoteArchiveBookFileImplCopyWith<$Res> {
  __$$RemoteArchiveBookFileImplCopyWithImpl(
    _$RemoteArchiveBookFileImpl _value,
    $Res Function(_$RemoteArchiveBookFileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RemoteArchiveBookFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? relativePath = null, Object? bytes = null}) {
    return _then(
      _$RemoteArchiveBookFileImpl(
        relativePath: null == relativePath
            ? _value.relativePath
            : relativePath // ignore: cast_nullable_to_non_nullable
                  as String,
        bytes: null == bytes
            ? _value.bytes
            : bytes // ignore: cast_nullable_to_non_nullable
                  as List<int>,
      ),
    );
  }
}

/// @nodoc

class _$RemoteArchiveBookFileImpl implements _RemoteArchiveBookFile {
  const _$RemoteArchiveBookFileImpl({
    required this.relativePath,
    required this.bytes,
  });

  @override
  final String relativePath;
  @override
  final List<int> bytes;

  @override
  String toString() {
    return 'RemoteArchiveBookFile(relativePath: $relativePath, bytes: $bytes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RemoteArchiveBookFileImpl &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            const DeepCollectionEquality().equals(other.bytes, bytes));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    relativePath,
    const DeepCollectionEquality().hash(bytes),
  );

  /// Create a copy of RemoteArchiveBookFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RemoteArchiveBookFileImplCopyWith<_$RemoteArchiveBookFileImpl>
  get copyWith =>
      __$$RemoteArchiveBookFileImplCopyWithImpl<_$RemoteArchiveBookFileImpl>(
        this,
        _$identity,
      );
}

abstract class _RemoteArchiveBookFile implements RemoteArchiveBookFile {
  const factory _RemoteArchiveBookFile({
    required final String relativePath,
    required final List<int> bytes,
  }) = _$RemoteArchiveBookFileImpl;

  @override
  String get relativePath;
  @override
  List<int> get bytes;

  /// Create a copy of RemoteArchiveBookFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RemoteArchiveBookFileImplCopyWith<_$RemoteArchiveBookFileImpl>
  get copyWith => throw _privateConstructorUsedError;
}
