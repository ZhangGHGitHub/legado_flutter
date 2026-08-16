// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chapter.freezed.dart';
part 'chapter.g.dart';

/// 章节领域实体。
@Freezed(copyWith: false)
class Chapter with _$Chapter {
  const Chapter._();

  const factory Chapter({
    required String id,
    required String bookId,
    required String title,
    @JsonKey(fromJson: _chapterIndexFromJson) required int index,
    @JsonKey(defaultValue: '') required String url,
    @Default(false) bool isVolume,
    @Default(false) bool isVip,
    @Default(false) bool isPay,
    @Default('') String tag,
    @Default('') String baseUrl,
    @Default(false) bool isDownloaded,
    String? content,
  }) = _Chapter;

  static String idFor({
    required String bookId,
    required String url,
    required int index,
  }) {
    if (url.isEmpty) return '${bookId}_ch_$index';
    var hash = 2166136261;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return '${bookId}_url_${hash.toRadixString(16).padLeft(8, '0')}';
  }

  static List<Chapter> mergeWithLocal(
    List<Chapter> remote,
    List<Chapter> local,
  ) {
    final byUrl = <String, Chapter>{
      for (final chapter in local)
        if (chapter.url.isNotEmpty) chapter.url: chapter,
    };
    final byId = <String, Chapter>{
      for (final chapter in local) chapter.id: chapter,
    };

    return remote.map((chapter) {
      final old =
          (chapter.url.isNotEmpty ? byUrl[chapter.url] : null) ??
          byId[chapter.id];
      if (old == null) return chapter;
      return Chapter(
        id: old.id,
        bookId: chapter.bookId,
        title: chapter.title,
        index: chapter.index,
        url: chapter.url,
        isVolume: chapter.isVolume,
        isVip: chapter.isVip,
        isPay: chapter.isPay,
        tag: chapter.tag,
        baseUrl: chapter.baseUrl,
        isDownloaded:
            old.isDownloaded ||
            (old.content != null && old.content!.isNotEmpty),
        content: old.content ?? chapter.content,
      );
    }).toList();
  }

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(_normalizeChapterJson(json));
}

int _chapterIndexFromJson(Object? value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

Map<String, dynamic> _normalizeChapterJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);
  normalized['index'] = json['index'] ?? json['idx'];
  return normalized;
}
