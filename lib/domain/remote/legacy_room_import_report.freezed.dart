// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'legacy_room_import_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LegacyRoomImportReport {
  int get sourceRoomVersion => throw _privateConstructorUsedError;
  String get fingerprint => throw _privateConstructorUsedError;
  bool get replaced => throw _privateConstructorUsedError;
  bool get skippedDuplicate => throw _privateConstructorUsedError;
  bool get backupWritten => throw _privateConstructorUsedError;
  Map<String, int> get counts => throw _privateConstructorUsedError;
  Map<String, int> get conflictCounts => throw _privateConstructorUsedError;
  Map<String, int> get preservedRows => throw _privateConstructorUsedError;
  List<String> get warnings => throw _privateConstructorUsedError;
  Map<String, List<String>> get unmappedColumns =>
      throw _privateConstructorUsedError;
  List<String> get archiveOnlyTables => throw _privateConstructorUsedError;
  String? get sourceRoomIdentityHash => throw _privateConstructorUsedError;
  String? get backupPath => throw _privateConstructorUsedError;

  /// Create a copy of LegacyRoomImportReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LegacyRoomImportReportCopyWith<LegacyRoomImportReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LegacyRoomImportReportCopyWith<$Res> {
  factory $LegacyRoomImportReportCopyWith(
    LegacyRoomImportReport value,
    $Res Function(LegacyRoomImportReport) then,
  ) = _$LegacyRoomImportReportCopyWithImpl<$Res, LegacyRoomImportReport>;
  @useResult
  $Res call({
    int sourceRoomVersion,
    String fingerprint,
    bool replaced,
    bool skippedDuplicate,
    bool backupWritten,
    Map<String, int> counts,
    Map<String, int> conflictCounts,
    Map<String, int> preservedRows,
    List<String> warnings,
    Map<String, List<String>> unmappedColumns,
    List<String> archiveOnlyTables,
    String? sourceRoomIdentityHash,
    String? backupPath,
  });
}

/// @nodoc
class _$LegacyRoomImportReportCopyWithImpl<
  $Res,
  $Val extends LegacyRoomImportReport
>
    implements $LegacyRoomImportReportCopyWith<$Res> {
  _$LegacyRoomImportReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LegacyRoomImportReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceRoomVersion = null,
    Object? fingerprint = null,
    Object? replaced = null,
    Object? skippedDuplicate = null,
    Object? backupWritten = null,
    Object? counts = null,
    Object? conflictCounts = null,
    Object? preservedRows = null,
    Object? warnings = null,
    Object? unmappedColumns = null,
    Object? archiveOnlyTables = null,
    Object? sourceRoomIdentityHash = freezed,
    Object? backupPath = freezed,
  }) {
    return _then(
      _value.copyWith(
            sourceRoomVersion: null == sourceRoomVersion
                ? _value.sourceRoomVersion
                : sourceRoomVersion // ignore: cast_nullable_to_non_nullable
                      as int,
            fingerprint: null == fingerprint
                ? _value.fingerprint
                : fingerprint // ignore: cast_nullable_to_non_nullable
                      as String,
            replaced: null == replaced
                ? _value.replaced
                : replaced // ignore: cast_nullable_to_non_nullable
                      as bool,
            skippedDuplicate: null == skippedDuplicate
                ? _value.skippedDuplicate
                : skippedDuplicate // ignore: cast_nullable_to_non_nullable
                      as bool,
            backupWritten: null == backupWritten
                ? _value.backupWritten
                : backupWritten // ignore: cast_nullable_to_non_nullable
                      as bool,
            counts: null == counts
                ? _value.counts
                : counts // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            conflictCounts: null == conflictCounts
                ? _value.conflictCounts
                : conflictCounts // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            preservedRows: null == preservedRows
                ? _value.preservedRows
                : preservedRows // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            warnings: null == warnings
                ? _value.warnings
                : warnings // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            unmappedColumns: null == unmappedColumns
                ? _value.unmappedColumns
                : unmappedColumns // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<String>>,
            archiveOnlyTables: null == archiveOnlyTables
                ? _value.archiveOnlyTables
                : archiveOnlyTables // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            sourceRoomIdentityHash: freezed == sourceRoomIdentityHash
                ? _value.sourceRoomIdentityHash
                : sourceRoomIdentityHash // ignore: cast_nullable_to_non_nullable
                      as String?,
            backupPath: freezed == backupPath
                ? _value.backupPath
                : backupPath // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LegacyRoomImportReportImplCopyWith<$Res>
    implements $LegacyRoomImportReportCopyWith<$Res> {
  factory _$$LegacyRoomImportReportImplCopyWith(
    _$LegacyRoomImportReportImpl value,
    $Res Function(_$LegacyRoomImportReportImpl) then,
  ) = __$$LegacyRoomImportReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int sourceRoomVersion,
    String fingerprint,
    bool replaced,
    bool skippedDuplicate,
    bool backupWritten,
    Map<String, int> counts,
    Map<String, int> conflictCounts,
    Map<String, int> preservedRows,
    List<String> warnings,
    Map<String, List<String>> unmappedColumns,
    List<String> archiveOnlyTables,
    String? sourceRoomIdentityHash,
    String? backupPath,
  });
}

/// @nodoc
class __$$LegacyRoomImportReportImplCopyWithImpl<$Res>
    extends
        _$LegacyRoomImportReportCopyWithImpl<$Res, _$LegacyRoomImportReportImpl>
    implements _$$LegacyRoomImportReportImplCopyWith<$Res> {
  __$$LegacyRoomImportReportImplCopyWithImpl(
    _$LegacyRoomImportReportImpl _value,
    $Res Function(_$LegacyRoomImportReportImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LegacyRoomImportReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceRoomVersion = null,
    Object? fingerprint = null,
    Object? replaced = null,
    Object? skippedDuplicate = null,
    Object? backupWritten = null,
    Object? counts = null,
    Object? conflictCounts = null,
    Object? preservedRows = null,
    Object? warnings = null,
    Object? unmappedColumns = null,
    Object? archiveOnlyTables = null,
    Object? sourceRoomIdentityHash = freezed,
    Object? backupPath = freezed,
  }) {
    return _then(
      _$LegacyRoomImportReportImpl(
        sourceRoomVersion: null == sourceRoomVersion
            ? _value.sourceRoomVersion
            : sourceRoomVersion // ignore: cast_nullable_to_non_nullable
                  as int,
        fingerprint: null == fingerprint
            ? _value.fingerprint
            : fingerprint // ignore: cast_nullable_to_non_nullable
                  as String,
        replaced: null == replaced
            ? _value.replaced
            : replaced // ignore: cast_nullable_to_non_nullable
                  as bool,
        skippedDuplicate: null == skippedDuplicate
            ? _value.skippedDuplicate
            : skippedDuplicate // ignore: cast_nullable_to_non_nullable
                  as bool,
        backupWritten: null == backupWritten
            ? _value.backupWritten
            : backupWritten // ignore: cast_nullable_to_non_nullable
                  as bool,
        counts: null == counts
            ? _value._counts
            : counts // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        conflictCounts: null == conflictCounts
            ? _value._conflictCounts
            : conflictCounts // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        preservedRows: null == preservedRows
            ? _value._preservedRows
            : preservedRows // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        warnings: null == warnings
            ? _value._warnings
            : warnings // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        unmappedColumns: null == unmappedColumns
            ? _value._unmappedColumns
            : unmappedColumns // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<String>>,
        archiveOnlyTables: null == archiveOnlyTables
            ? _value._archiveOnlyTables
            : archiveOnlyTables // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        sourceRoomIdentityHash: freezed == sourceRoomIdentityHash
            ? _value.sourceRoomIdentityHash
            : sourceRoomIdentityHash // ignore: cast_nullable_to_non_nullable
                  as String?,
        backupPath: freezed == backupPath
            ? _value.backupPath
            : backupPath // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$LegacyRoomImportReportImpl extends _LegacyRoomImportReport {
  const _$LegacyRoomImportReportImpl({
    required this.sourceRoomVersion,
    required this.fingerprint,
    required this.replaced,
    required this.skippedDuplicate,
    required this.backupWritten,
    required final Map<String, int> counts,
    required final Map<String, int> conflictCounts,
    required final Map<String, int> preservedRows,
    required final List<String> warnings,
    required final Map<String, List<String>> unmappedColumns,
    final List<String> archiveOnlyTables = const <String>[],
    this.sourceRoomIdentityHash,
    this.backupPath,
  }) : _counts = counts,
       _conflictCounts = conflictCounts,
       _preservedRows = preservedRows,
       _warnings = warnings,
       _unmappedColumns = unmappedColumns,
       _archiveOnlyTables = archiveOnlyTables,
       super._();

  @override
  final int sourceRoomVersion;
  @override
  final String fingerprint;
  @override
  final bool replaced;
  @override
  final bool skippedDuplicate;
  @override
  final bool backupWritten;
  final Map<String, int> _counts;
  @override
  Map<String, int> get counts {
    if (_counts is EqualUnmodifiableMapView) return _counts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_counts);
  }

  final Map<String, int> _conflictCounts;
  @override
  Map<String, int> get conflictCounts {
    if (_conflictCounts is EqualUnmodifiableMapView) return _conflictCounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_conflictCounts);
  }

  final Map<String, int> _preservedRows;
  @override
  Map<String, int> get preservedRows {
    if (_preservedRows is EqualUnmodifiableMapView) return _preservedRows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_preservedRows);
  }

  final List<String> _warnings;
  @override
  List<String> get warnings {
    if (_warnings is EqualUnmodifiableListView) return _warnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_warnings);
  }

  final Map<String, List<String>> _unmappedColumns;
  @override
  Map<String, List<String>> get unmappedColumns {
    if (_unmappedColumns is EqualUnmodifiableMapView) return _unmappedColumns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_unmappedColumns);
  }

  final List<String> _archiveOnlyTables;
  @override
  @JsonKey()
  List<String> get archiveOnlyTables {
    if (_archiveOnlyTables is EqualUnmodifiableListView)
      return _archiveOnlyTables;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_archiveOnlyTables);
  }

  @override
  final String? sourceRoomIdentityHash;
  @override
  final String? backupPath;

  @override
  String toString() {
    return 'LegacyRoomImportReport(sourceRoomVersion: $sourceRoomVersion, fingerprint: $fingerprint, replaced: $replaced, skippedDuplicate: $skippedDuplicate, backupWritten: $backupWritten, counts: $counts, conflictCounts: $conflictCounts, preservedRows: $preservedRows, warnings: $warnings, unmappedColumns: $unmappedColumns, archiveOnlyTables: $archiveOnlyTables, sourceRoomIdentityHash: $sourceRoomIdentityHash, backupPath: $backupPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LegacyRoomImportReportImpl &&
            (identical(other.sourceRoomVersion, sourceRoomVersion) ||
                other.sourceRoomVersion == sourceRoomVersion) &&
            (identical(other.fingerprint, fingerprint) ||
                other.fingerprint == fingerprint) &&
            (identical(other.replaced, replaced) ||
                other.replaced == replaced) &&
            (identical(other.skippedDuplicate, skippedDuplicate) ||
                other.skippedDuplicate == skippedDuplicate) &&
            (identical(other.backupWritten, backupWritten) ||
                other.backupWritten == backupWritten) &&
            const DeepCollectionEquality().equals(other._counts, _counts) &&
            const DeepCollectionEquality().equals(
              other._conflictCounts,
              _conflictCounts,
            ) &&
            const DeepCollectionEquality().equals(
              other._preservedRows,
              _preservedRows,
            ) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings) &&
            const DeepCollectionEquality().equals(
              other._unmappedColumns,
              _unmappedColumns,
            ) &&
            const DeepCollectionEquality().equals(
              other._archiveOnlyTables,
              _archiveOnlyTables,
            ) &&
            (identical(other.sourceRoomIdentityHash, sourceRoomIdentityHash) ||
                other.sourceRoomIdentityHash == sourceRoomIdentityHash) &&
            (identical(other.backupPath, backupPath) ||
                other.backupPath == backupPath));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    sourceRoomVersion,
    fingerprint,
    replaced,
    skippedDuplicate,
    backupWritten,
    const DeepCollectionEquality().hash(_counts),
    const DeepCollectionEquality().hash(_conflictCounts),
    const DeepCollectionEquality().hash(_preservedRows),
    const DeepCollectionEquality().hash(_warnings),
    const DeepCollectionEquality().hash(_unmappedColumns),
    const DeepCollectionEquality().hash(_archiveOnlyTables),
    sourceRoomIdentityHash,
    backupPath,
  );

  /// Create a copy of LegacyRoomImportReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LegacyRoomImportReportImplCopyWith<_$LegacyRoomImportReportImpl>
  get copyWith =>
      __$$LegacyRoomImportReportImplCopyWithImpl<_$LegacyRoomImportReportImpl>(
        this,
        _$identity,
      );
}

abstract class _LegacyRoomImportReport extends LegacyRoomImportReport {
  const factory _LegacyRoomImportReport({
    required final int sourceRoomVersion,
    required final String fingerprint,
    required final bool replaced,
    required final bool skippedDuplicate,
    required final bool backupWritten,
    required final Map<String, int> counts,
    required final Map<String, int> conflictCounts,
    required final Map<String, int> preservedRows,
    required final List<String> warnings,
    required final Map<String, List<String>> unmappedColumns,
    final List<String> archiveOnlyTables,
    final String? sourceRoomIdentityHash,
    final String? backupPath,
  }) = _$LegacyRoomImportReportImpl;
  const _LegacyRoomImportReport._() : super._();

  @override
  int get sourceRoomVersion;
  @override
  String get fingerprint;
  @override
  bool get replaced;
  @override
  bool get skippedDuplicate;
  @override
  bool get backupWritten;
  @override
  Map<String, int> get counts;
  @override
  Map<String, int> get conflictCounts;
  @override
  Map<String, int> get preservedRows;
  @override
  List<String> get warnings;
  @override
  Map<String, List<String>> get unmappedColumns;
  @override
  List<String> get archiveOnlyTables;
  @override
  String? get sourceRoomIdentityHash;
  @override
  String? get backupPath;

  /// Create a copy of LegacyRoomImportReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LegacyRoomImportReportImplCopyWith<_$LegacyRoomImportReportImpl>
  get copyWith => throw _privateConstructorUsedError;
}
