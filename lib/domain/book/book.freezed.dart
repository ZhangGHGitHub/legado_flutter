// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BookReadConfig {
  bool get reverseToc => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, dynamic> get extra => throw _privateConstructorUsedError;

  /// Create a copy of BookReadConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookReadConfigCopyWith<BookReadConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookReadConfigCopyWith<$Res> {
  factory $BookReadConfigCopyWith(
    BookReadConfig value,
    $Res Function(BookReadConfig) then,
  ) = _$BookReadConfigCopyWithImpl<$Res, BookReadConfig>;
  @useResult
  $Res call({
    bool reverseToc,
    @JsonKey(includeFromJson: false, includeToJson: false)
    Map<String, dynamic> extra,
  });
}

/// @nodoc
class _$BookReadConfigCopyWithImpl<$Res, $Val extends BookReadConfig>
    implements $BookReadConfigCopyWith<$Res> {
  _$BookReadConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookReadConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? reverseToc = null, Object? extra = null}) {
    return _then(
      _value.copyWith(
            reverseToc: null == reverseToc
                ? _value.reverseToc
                : reverseToc // ignore: cast_nullable_to_non_nullable
                      as bool,
            extra: null == extra
                ? _value.extra
                : extra // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookReadConfigImplCopyWith<$Res>
    implements $BookReadConfigCopyWith<$Res> {
  factory _$$BookReadConfigImplCopyWith(
    _$BookReadConfigImpl value,
    $Res Function(_$BookReadConfigImpl) then,
  ) = __$$BookReadConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool reverseToc,
    @JsonKey(includeFromJson: false, includeToJson: false)
    Map<String, dynamic> extra,
  });
}

/// @nodoc
class __$$BookReadConfigImplCopyWithImpl<$Res>
    extends _$BookReadConfigCopyWithImpl<$Res, _$BookReadConfigImpl>
    implements _$$BookReadConfigImplCopyWith<$Res> {
  __$$BookReadConfigImplCopyWithImpl(
    _$BookReadConfigImpl _value,
    $Res Function(_$BookReadConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookReadConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? reverseToc = null, Object? extra = null}) {
    return _then(
      _$BookReadConfigImpl(
        reverseToc: null == reverseToc
            ? _value.reverseToc
            : reverseToc // ignore: cast_nullable_to_non_nullable
                  as bool,
        extra: null == extra
            ? _value._extra
            : extra // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc

class _$BookReadConfigImpl extends _BookReadConfig {
  const _$BookReadConfigImpl({
    this.reverseToc = false,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final Map<String, dynamic> extra = const <String, dynamic>{},
  }) : _extra = extra,
       super._();

  @override
  @JsonKey()
  final bool reverseToc;
  final Map<String, dynamic> _extra;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, dynamic> get extra {
    if (_extra is EqualUnmodifiableMapView) return _extra;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_extra);
  }

  @override
  String toString() {
    return 'BookReadConfig(reverseToc: $reverseToc, extra: $extra)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookReadConfigImpl &&
            (identical(other.reverseToc, reverseToc) ||
                other.reverseToc == reverseToc) &&
            const DeepCollectionEquality().equals(other._extra, _extra));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    reverseToc,
    const DeepCollectionEquality().hash(_extra),
  );

  /// Create a copy of BookReadConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookReadConfigImplCopyWith<_$BookReadConfigImpl> get copyWith =>
      __$$BookReadConfigImplCopyWithImpl<_$BookReadConfigImpl>(
        this,
        _$identity,
      );
}

abstract class _BookReadConfig extends BookReadConfig {
  const factory _BookReadConfig({
    final bool reverseToc,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final Map<String, dynamic> extra,
  }) = _$BookReadConfigImpl;
  const _BookReadConfig._() : super._();

  @override
  bool get reverseToc;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, dynamic> get extra;

  /// Create a copy of BookReadConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookReadConfigImplCopyWith<_$BookReadConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Book {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get author => throw _privateConstructorUsedError;
  String get coverUrl => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;
  String? get currentChapter => throw _privateConstructorUsedError;
  String? get lastChapter => throw _privateConstructorUsedError;
  int get totalChapterNum => throw _privateConstructorUsedError;
  int get durChapterIndex => throw _privateConstructorUsedError;
  int get currentPageIndex => throw _privateConstructorUsedError;
  BookReadConfig get readConfig => throw _privateConstructorUsedError;
  bool get isFavorite => throw _privateConstructorUsedError;
  String get sourceUrl => throw _privateConstructorUsedError;
  String get tocUrl => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get bookSourceUrl => throw _privateConstructorUsedError;
  String get group => throw _privateConstructorUsedError;
  int get readIteration => throw _privateConstructorUsedError;
  bool get simReadEnabled => throw _privateConstructorUsedError;
  String get simReadStartDate => throw _privateConstructorUsedError;
  int get simReadStartChapter => throw _privateConstructorUsedError;
  int get simReadDailyChapters => throw _privateConstructorUsedError;
  String? get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookCopyWith<Book> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookCopyWith<$Res> {
  factory $BookCopyWith(Book value, $Res Function(Book) then) =
      _$BookCopyWithImpl<$Res, Book>;
  @useResult
  $Res call({
    String id,
    String name,
    String author,
    String coverUrl,
    String type,
    double progress,
    String? currentChapter,
    String? lastChapter,
    int totalChapterNum,
    int durChapterIndex,
    int currentPageIndex,
    BookReadConfig readConfig,
    bool isFavorite,
    String sourceUrl,
    String tocUrl,
    String description,
    String bookSourceUrl,
    String group,
    int readIteration,
    bool simReadEnabled,
    String simReadStartDate,
    int simReadStartChapter,
    int simReadDailyChapters,
    String? updatedAt,
  });

  $BookReadConfigCopyWith<$Res> get readConfig;
}

/// @nodoc
class _$BookCopyWithImpl<$Res, $Val extends Book>
    implements $BookCopyWith<$Res> {
  _$BookCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? author = null,
    Object? coverUrl = null,
    Object? type = null,
    Object? progress = null,
    Object? currentChapter = freezed,
    Object? lastChapter = freezed,
    Object? totalChapterNum = null,
    Object? durChapterIndex = null,
    Object? currentPageIndex = null,
    Object? readConfig = null,
    Object? isFavorite = null,
    Object? sourceUrl = null,
    Object? tocUrl = null,
    Object? description = null,
    Object? bookSourceUrl = null,
    Object? group = null,
    Object? readIteration = null,
    Object? simReadEnabled = null,
    Object? simReadStartDate = null,
    Object? simReadStartChapter = null,
    Object? simReadDailyChapters = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            author: null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as String,
            coverUrl: null == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            progress: null == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as double,
            currentChapter: freezed == currentChapter
                ? _value.currentChapter
                : currentChapter // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastChapter: freezed == lastChapter
                ? _value.lastChapter
                : lastChapter // ignore: cast_nullable_to_non_nullable
                      as String?,
            totalChapterNum: null == totalChapterNum
                ? _value.totalChapterNum
                : totalChapterNum // ignore: cast_nullable_to_non_nullable
                      as int,
            durChapterIndex: null == durChapterIndex
                ? _value.durChapterIndex
                : durChapterIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            currentPageIndex: null == currentPageIndex
                ? _value.currentPageIndex
                : currentPageIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            readConfig: null == readConfig
                ? _value.readConfig
                : readConfig // ignore: cast_nullable_to_non_nullable
                      as BookReadConfig,
            isFavorite: null == isFavorite
                ? _value.isFavorite
                : isFavorite // ignore: cast_nullable_to_non_nullable
                      as bool,
            sourceUrl: null == sourceUrl
                ? _value.sourceUrl
                : sourceUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            tocUrl: null == tocUrl
                ? _value.tocUrl
                : tocUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            bookSourceUrl: null == bookSourceUrl
                ? _value.bookSourceUrl
                : bookSourceUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            group: null == group
                ? _value.group
                : group // ignore: cast_nullable_to_non_nullable
                      as String,
            readIteration: null == readIteration
                ? _value.readIteration
                : readIteration // ignore: cast_nullable_to_non_nullable
                      as int,
            simReadEnabled: null == simReadEnabled
                ? _value.simReadEnabled
                : simReadEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            simReadStartDate: null == simReadStartDate
                ? _value.simReadStartDate
                : simReadStartDate // ignore: cast_nullable_to_non_nullable
                      as String,
            simReadStartChapter: null == simReadStartChapter
                ? _value.simReadStartChapter
                : simReadStartChapter // ignore: cast_nullable_to_non_nullable
                      as int,
            simReadDailyChapters: null == simReadDailyChapters
                ? _value.simReadDailyChapters
                : simReadDailyChapters // ignore: cast_nullable_to_non_nullable
                      as int,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BookReadConfigCopyWith<$Res> get readConfig {
    return $BookReadConfigCopyWith<$Res>(_value.readConfig, (value) {
      return _then(_value.copyWith(readConfig: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BookImplCopyWith<$Res> implements $BookCopyWith<$Res> {
  factory _$$BookImplCopyWith(
    _$BookImpl value,
    $Res Function(_$BookImpl) then,
  ) = __$$BookImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String author,
    String coverUrl,
    String type,
    double progress,
    String? currentChapter,
    String? lastChapter,
    int totalChapterNum,
    int durChapterIndex,
    int currentPageIndex,
    BookReadConfig readConfig,
    bool isFavorite,
    String sourceUrl,
    String tocUrl,
    String description,
    String bookSourceUrl,
    String group,
    int readIteration,
    bool simReadEnabled,
    String simReadStartDate,
    int simReadStartChapter,
    int simReadDailyChapters,
    String? updatedAt,
  });

  @override
  $BookReadConfigCopyWith<$Res> get readConfig;
}

/// @nodoc
class __$$BookImplCopyWithImpl<$Res>
    extends _$BookCopyWithImpl<$Res, _$BookImpl>
    implements _$$BookImplCopyWith<$Res> {
  __$$BookImplCopyWithImpl(_$BookImpl _value, $Res Function(_$BookImpl) _then)
    : super(_value, _then);

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? author = null,
    Object? coverUrl = null,
    Object? type = null,
    Object? progress = null,
    Object? currentChapter = freezed,
    Object? lastChapter = freezed,
    Object? totalChapterNum = null,
    Object? durChapterIndex = null,
    Object? currentPageIndex = null,
    Object? readConfig = null,
    Object? isFavorite = null,
    Object? sourceUrl = null,
    Object? tocUrl = null,
    Object? description = null,
    Object? bookSourceUrl = null,
    Object? group = null,
    Object? readIteration = null,
    Object? simReadEnabled = null,
    Object? simReadStartDate = null,
    Object? simReadStartChapter = null,
    Object? simReadDailyChapters = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$BookImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        author: null == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as String,
        coverUrl: null == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
        currentChapter: freezed == currentChapter
            ? _value.currentChapter
            : currentChapter // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastChapter: freezed == lastChapter
            ? _value.lastChapter
            : lastChapter // ignore: cast_nullable_to_non_nullable
                  as String?,
        totalChapterNum: null == totalChapterNum
            ? _value.totalChapterNum
            : totalChapterNum // ignore: cast_nullable_to_non_nullable
                  as int,
        durChapterIndex: null == durChapterIndex
            ? _value.durChapterIndex
            : durChapterIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        currentPageIndex: null == currentPageIndex
            ? _value.currentPageIndex
            : currentPageIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        readConfig: null == readConfig
            ? _value.readConfig
            : readConfig // ignore: cast_nullable_to_non_nullable
                  as BookReadConfig,
        isFavorite: null == isFavorite
            ? _value.isFavorite
            : isFavorite // ignore: cast_nullable_to_non_nullable
                  as bool,
        sourceUrl: null == sourceUrl
            ? _value.sourceUrl
            : sourceUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        tocUrl: null == tocUrl
            ? _value.tocUrl
            : tocUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        bookSourceUrl: null == bookSourceUrl
            ? _value.bookSourceUrl
            : bookSourceUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        group: null == group
            ? _value.group
            : group // ignore: cast_nullable_to_non_nullable
                  as String,
        readIteration: null == readIteration
            ? _value.readIteration
            : readIteration // ignore: cast_nullable_to_non_nullable
                  as int,
        simReadEnabled: null == simReadEnabled
            ? _value.simReadEnabled
            : simReadEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        simReadStartDate: null == simReadStartDate
            ? _value.simReadStartDate
            : simReadStartDate // ignore: cast_nullable_to_non_nullable
                  as String,
        simReadStartChapter: null == simReadStartChapter
            ? _value.simReadStartChapter
            : simReadStartChapter // ignore: cast_nullable_to_non_nullable
                  as int,
        simReadDailyChapters: null == simReadDailyChapters
            ? _value.simReadDailyChapters
            : simReadDailyChapters // ignore: cast_nullable_to_non_nullable
                  as int,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$BookImpl extends _Book {
  const _$BookImpl({
    required this.id,
    required this.name,
    this.author = '未知作者',
    this.coverUrl = '',
    this.type = 'online',
    this.progress = 0.0,
    this.currentChapter,
    this.lastChapter,
    this.totalChapterNum = 0,
    this.durChapterIndex = 0,
    this.currentPageIndex = 0,
    this.readConfig = const BookReadConfig(),
    this.isFavorite = false,
    this.sourceUrl = '',
    this.tocUrl = '',
    this.description = '',
    this.bookSourceUrl = '',
    this.group = '',
    this.readIteration = 0,
    this.simReadEnabled = false,
    this.simReadStartDate = '',
    this.simReadStartChapter = 0,
    this.simReadDailyChapters = 3,
    this.updatedAt,
  }) : super._();

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String author;
  @override
  @JsonKey()
  final String coverUrl;
  @override
  @JsonKey()
  final String type;
  @override
  @JsonKey()
  final double progress;
  @override
  final String? currentChapter;
  @override
  final String? lastChapter;
  @override
  @JsonKey()
  final int totalChapterNum;
  @override
  @JsonKey()
  final int durChapterIndex;
  @override
  @JsonKey()
  final int currentPageIndex;
  @override
  @JsonKey()
  final BookReadConfig readConfig;
  @override
  @JsonKey()
  final bool isFavorite;
  @override
  @JsonKey()
  final String sourceUrl;
  @override
  @JsonKey()
  final String tocUrl;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey()
  final String bookSourceUrl;
  @override
  @JsonKey()
  final String group;
  @override
  @JsonKey()
  final int readIteration;
  @override
  @JsonKey()
  final bool simReadEnabled;
  @override
  @JsonKey()
  final String simReadStartDate;
  @override
  @JsonKey()
  final int simReadStartChapter;
  @override
  @JsonKey()
  final int simReadDailyChapters;
  @override
  final String? updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.currentChapter, currentChapter) ||
                other.currentChapter == currentChapter) &&
            (identical(other.lastChapter, lastChapter) ||
                other.lastChapter == lastChapter) &&
            (identical(other.totalChapterNum, totalChapterNum) ||
                other.totalChapterNum == totalChapterNum) &&
            (identical(other.durChapterIndex, durChapterIndex) ||
                other.durChapterIndex == durChapterIndex) &&
            (identical(other.currentPageIndex, currentPageIndex) ||
                other.currentPageIndex == currentPageIndex) &&
            (identical(other.readConfig, readConfig) ||
                other.readConfig == readConfig) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.sourceUrl, sourceUrl) ||
                other.sourceUrl == sourceUrl) &&
            (identical(other.tocUrl, tocUrl) || other.tocUrl == tocUrl) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.bookSourceUrl, bookSourceUrl) ||
                other.bookSourceUrl == bookSourceUrl) &&
            (identical(other.group, group) || other.group == group) &&
            (identical(other.readIteration, readIteration) ||
                other.readIteration == readIteration) &&
            (identical(other.simReadEnabled, simReadEnabled) ||
                other.simReadEnabled == simReadEnabled) &&
            (identical(other.simReadStartDate, simReadStartDate) ||
                other.simReadStartDate == simReadStartDate) &&
            (identical(other.simReadStartChapter, simReadStartChapter) ||
                other.simReadStartChapter == simReadStartChapter) &&
            (identical(other.simReadDailyChapters, simReadDailyChapters) ||
                other.simReadDailyChapters == simReadDailyChapters) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    author,
    coverUrl,
    type,
    progress,
    currentChapter,
    lastChapter,
    totalChapterNum,
    durChapterIndex,
    currentPageIndex,
    readConfig,
    isFavorite,
    sourceUrl,
    tocUrl,
    description,
    bookSourceUrl,
    group,
    readIteration,
    simReadEnabled,
    simReadStartDate,
    simReadStartChapter,
    simReadDailyChapters,
    updatedAt,
  ]);

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookImplCopyWith<_$BookImpl> get copyWith =>
      __$$BookImplCopyWithImpl<_$BookImpl>(this, _$identity);
}

abstract class _Book extends Book {
  const factory _Book({
    required final String id,
    required final String name,
    final String author,
    final String coverUrl,
    final String type,
    final double progress,
    final String? currentChapter,
    final String? lastChapter,
    final int totalChapterNum,
    final int durChapterIndex,
    final int currentPageIndex,
    final BookReadConfig readConfig,
    final bool isFavorite,
    final String sourceUrl,
    final String tocUrl,
    final String description,
    final String bookSourceUrl,
    final String group,
    final int readIteration,
    final bool simReadEnabled,
    final String simReadStartDate,
    final int simReadStartChapter,
    final int simReadDailyChapters,
    final String? updatedAt,
  }) = _$BookImpl;
  const _Book._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String get author;
  @override
  String get coverUrl;
  @override
  String get type;
  @override
  double get progress;
  @override
  String? get currentChapter;
  @override
  String? get lastChapter;
  @override
  int get totalChapterNum;
  @override
  int get durChapterIndex;
  @override
  int get currentPageIndex;
  @override
  BookReadConfig get readConfig;
  @override
  bool get isFavorite;
  @override
  String get sourceUrl;
  @override
  String get tocUrl;
  @override
  String get description;
  @override
  String get bookSourceUrl;
  @override
  String get group;
  @override
  int get readIteration;
  @override
  bool get simReadEnabled;
  @override
  String get simReadStartDate;
  @override
  int get simReadStartChapter;
  @override
  int get simReadDailyChapters;
  @override
  String? get updatedAt;

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookImplCopyWith<_$BookImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
