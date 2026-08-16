// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$NoteSnapshot {
  String get id => throw _privateConstructorUsedError;
  String get bookId => throw _privateConstructorUsedError;
  String get chapterTitle => throw _privateConstructorUsedError;
  String get selectedText => throw _privateConstructorUsedError;
  String get noteContent => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
  int get chapterPos => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of NoteSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NoteSnapshotCopyWith<NoteSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteSnapshotCopyWith<$Res> {
  factory $NoteSnapshotCopyWith(
    NoteSnapshot value,
    $Res Function(NoteSnapshot) then,
  ) = _$NoteSnapshotCopyWithImpl<$Res, NoteSnapshot>;
  @useResult
  $Res call({
    String id,
    String bookId,
    String chapterTitle,
    String selectedText,
    String noteContent,
    int position,
    int chapterPos,
    String createdAt,
  });
}

/// @nodoc
class _$NoteSnapshotCopyWithImpl<$Res, $Val extends NoteSnapshot>
    implements $NoteSnapshotCopyWith<$Res> {
  _$NoteSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NoteSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bookId = null,
    Object? chapterTitle = null,
    Object? selectedText = null,
    Object? noteContent = null,
    Object? position = null,
    Object? chapterPos = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            bookId: null == bookId
                ? _value.bookId
                : bookId // ignore: cast_nullable_to_non_nullable
                      as String,
            chapterTitle: null == chapterTitle
                ? _value.chapterTitle
                : chapterTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            selectedText: null == selectedText
                ? _value.selectedText
                : selectedText // ignore: cast_nullable_to_non_nullable
                      as String,
            noteContent: null == noteContent
                ? _value.noteContent
                : noteContent // ignore: cast_nullable_to_non_nullable
                      as String,
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as int,
            chapterPos: null == chapterPos
                ? _value.chapterPos
                : chapterPos // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NoteSnapshotImplCopyWith<$Res>
    implements $NoteSnapshotCopyWith<$Res> {
  factory _$$NoteSnapshotImplCopyWith(
    _$NoteSnapshotImpl value,
    $Res Function(_$NoteSnapshotImpl) then,
  ) = __$$NoteSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String bookId,
    String chapterTitle,
    String selectedText,
    String noteContent,
    int position,
    int chapterPos,
    String createdAt,
  });
}

/// @nodoc
class __$$NoteSnapshotImplCopyWithImpl<$Res>
    extends _$NoteSnapshotCopyWithImpl<$Res, _$NoteSnapshotImpl>
    implements _$$NoteSnapshotImplCopyWith<$Res> {
  __$$NoteSnapshotImplCopyWithImpl(
    _$NoteSnapshotImpl _value,
    $Res Function(_$NoteSnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bookId = null,
    Object? chapterTitle = null,
    Object? selectedText = null,
    Object? noteContent = null,
    Object? position = null,
    Object? chapterPos = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$NoteSnapshotImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        bookId: null == bookId
            ? _value.bookId
            : bookId // ignore: cast_nullable_to_non_nullable
                  as String,
        chapterTitle: null == chapterTitle
            ? _value.chapterTitle
            : chapterTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        selectedText: null == selectedText
            ? _value.selectedText
            : selectedText // ignore: cast_nullable_to_non_nullable
                  as String,
        noteContent: null == noteContent
            ? _value.noteContent
            : noteContent // ignore: cast_nullable_to_non_nullable
                  as String,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as int,
        chapterPos: null == chapterPos
            ? _value.chapterPos
            : chapterPos // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$NoteSnapshotImpl implements _NoteSnapshot {
  const _$NoteSnapshotImpl({
    required this.id,
    required this.bookId,
    required this.chapterTitle,
    required this.selectedText,
    required this.noteContent,
    required this.position,
    required this.chapterPos,
    required this.createdAt,
  });

  @override
  final String id;
  @override
  final String bookId;
  @override
  final String chapterTitle;
  @override
  final String selectedText;
  @override
  final String noteContent;
  @override
  final int position;
  @override
  final int chapterPos;
  @override
  final String createdAt;

  @override
  String toString() {
    return 'NoteSnapshot(id: $id, bookId: $bookId, chapterTitle: $chapterTitle, selectedText: $selectedText, noteContent: $noteContent, position: $position, chapterPos: $chapterPos, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteSnapshotImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.chapterTitle, chapterTitle) ||
                other.chapterTitle == chapterTitle) &&
            (identical(other.selectedText, selectedText) ||
                other.selectedText == selectedText) &&
            (identical(other.noteContent, noteContent) ||
                other.noteContent == noteContent) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.chapterPos, chapterPos) ||
                other.chapterPos == chapterPos) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    bookId,
    chapterTitle,
    selectedText,
    noteContent,
    position,
    chapterPos,
    createdAt,
  );

  /// Create a copy of NoteSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteSnapshotImplCopyWith<_$NoteSnapshotImpl> get copyWith =>
      __$$NoteSnapshotImplCopyWithImpl<_$NoteSnapshotImpl>(this, _$identity);
}

abstract class _NoteSnapshot implements NoteSnapshot {
  const factory _NoteSnapshot({
    required final String id,
    required final String bookId,
    required final String chapterTitle,
    required final String selectedText,
    required final String noteContent,
    required final int position,
    required final int chapterPos,
    required final String createdAt,
  }) = _$NoteSnapshotImpl;

  @override
  String get id;
  @override
  String get bookId;
  @override
  String get chapterTitle;
  @override
  String get selectedText;
  @override
  String get noteContent;
  @override
  int get position;
  @override
  int get chapterPos;
  @override
  String get createdAt;

  /// Create a copy of NoteSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoteSnapshotImplCopyWith<_$NoteSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
