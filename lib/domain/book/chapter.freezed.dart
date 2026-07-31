// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chapter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Chapter _$ChapterFromJson(Map<String, dynamic> json) {
  return _Chapter.fromJson(json);
}

/// @nodoc
mixin _$Chapter {
  String get id => throw _privateConstructorUsedError;
  String get bookId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _chapterIndexFromJson)
  int get index => throw _privateConstructorUsedError;
  @JsonKey(defaultValue: '')
  String get url => throw _privateConstructorUsedError;
  bool get isVolume => throw _privateConstructorUsedError;
  bool get isVip => throw _privateConstructorUsedError;
  bool get isPay => throw _privateConstructorUsedError;
  String get tag => throw _privateConstructorUsedError;
  String get baseUrl => throw _privateConstructorUsedError;
  bool get isDownloaded => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;

  /// Serializes this Chapter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
@JsonSerializable()
class _$ChapterImpl extends _Chapter {
  const _$ChapterImpl({
    required this.id,
    required this.bookId,
    required this.title,
    @JsonKey(fromJson: _chapterIndexFromJson) required this.index,
    @JsonKey(defaultValue: '') required this.url,
    this.isVolume = false,
    this.isVip = false,
    this.isPay = false,
    this.tag = '',
    this.baseUrl = '',
    this.isDownloaded = false,
    this.content,
  }) : super._();

  factory _$ChapterImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChapterImplFromJson(json);

  @override
  final String id;
  @override
  final String bookId;
  @override
  final String title;
  @override
  @JsonKey(fromJson: _chapterIndexFromJson)
  final int index;
  @override
  @JsonKey(defaultValue: '')
  final String url;
  @override
  @JsonKey()
  final bool isVolume;
  @override
  @JsonKey()
  final bool isVip;
  @override
  @JsonKey()
  final bool isPay;
  @override
  @JsonKey()
  final String tag;
  @override
  @JsonKey()
  final String baseUrl;
  @override
  @JsonKey()
  final bool isDownloaded;
  @override
  final String? content;

  @override
  String toString() {
    return 'Chapter(id: $id, bookId: $bookId, title: $title, index: $index, url: $url, isVolume: $isVolume, isVip: $isVip, isPay: $isPay, tag: $tag, baseUrl: $baseUrl, isDownloaded: $isDownloaded, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChapterImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.isVolume, isVolume) ||
                other.isVolume == isVolume) &&
            (identical(other.isVip, isVip) || other.isVip == isVip) &&
            (identical(other.isPay, isPay) || other.isPay == isPay) &&
            (identical(other.tag, tag) || other.tag == tag) &&
            (identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl) &&
            (identical(other.isDownloaded, isDownloaded) ||
                other.isDownloaded == isDownloaded) &&
            (identical(other.content, content) || other.content == content));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    bookId,
    title,
    index,
    url,
    isVolume,
    isVip,
    isPay,
    tag,
    baseUrl,
    isDownloaded,
    content,
  );

  @override
  Map<String, dynamic> toJson() {
    return _$$ChapterImplToJson(this);
  }
}

abstract class _Chapter extends Chapter {
  const factory _Chapter({
    required final String id,
    required final String bookId,
    required final String title,
    @JsonKey(fromJson: _chapterIndexFromJson) required final int index,
    @JsonKey(defaultValue: '') required final String url,
    final bool isVolume,
    final bool isVip,
    final bool isPay,
    final String tag,
    final String baseUrl,
    final bool isDownloaded,
    final String? content,
  }) = _$ChapterImpl;
  const _Chapter._() : super._();

  factory _Chapter.fromJson(Map<String, dynamic> json) = _$ChapterImpl.fromJson;

  @override
  String get id;
  @override
  String get bookId;
  @override
  String get title;
  @override
  @JsonKey(fromJson: _chapterIndexFromJson)
  int get index;
  @override
  @JsonKey(defaultValue: '')
  String get url;
  @override
  bool get isVolume;
  @override
  bool get isVip;
  @override
  bool get isPay;
  @override
  String get tag;
  @override
  String get baseUrl;
  @override
  bool get isDownloaded;
  @override
  String? get content;
}
