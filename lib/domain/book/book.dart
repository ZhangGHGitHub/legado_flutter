// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';

/// Per-book reader settings persisted inside the Book `readConfig` record.
@freezed
class BookReadConfig with _$BookReadConfig {
  const BookReadConfig._();

  const factory BookReadConfig({
    @Default(false) bool reverseToc,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(<String, dynamic>{})
    Map<String, dynamic> extra,
  }) = _BookReadConfig;

  factory BookReadConfig.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final rawReverse = map.remove('reverseToc');
    return BookReadConfig(
      reverseToc: rawReverse is bool ? rawReverse : false,
      extra: Map<String, dynamic>.unmodifiable(map),
    );
  }

  factory BookReadConfig.fromLegacyJson(
    dynamic value, {
    bool? legacyTopLevelReverseToc,
  }) {
    final map = value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
    final rawReverse = map.remove('reverseToc');
    final reverse = rawReverse is bool
        ? rawReverse
        : legacyTopLevelReverseToc ?? false;
    return BookReadConfig.fromJson({...map, 'reverseToc': reverse});
  }

  Map<String, dynamic> toJson() => {...extra, 'reverseToc': reverseToc};
}

/// 书籍领域实体，对应 Legado 的一本书。
@freezed
class Book with _$Book {
  const Book._();

  const factory Book({
    required String id,
    required String name,
    @Default('未知作者') String author,
    @Default('') String coverUrl,
    @Default('online') String type,
    @Default(0.0) double progress,
    String? currentChapter,
    String? lastChapter,
    @Default(0) int totalChapterNum,
    @Default(0) int durChapterIndex,
    @Default(0) int currentPageIndex,
    @Default(BookReadConfig()) BookReadConfig readConfig,
    @Default(false) bool isFavorite,
    @Default('') String sourceUrl,
    @Default('') String tocUrl,
    @Default('') String description,
    @Default('') String bookSourceUrl,
    @Default('') String group,
    @Default(0) int readIteration,
    @Default(false) bool simReadEnabled,
    @Default('') String simReadStartDate,
    @Default(0) int simReadStartChapter,
    @Default(3) int simReadDailyChapters,
    String? updatedAt,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      name: json['name'] as String,
      author: json['author'] as String? ?? '未知作者',
      coverUrl: json['coverUrl'] as String? ?? '',
      type: json['type'] as String? ?? 'online',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      currentChapter: json['currentChapter'] as String?,
      lastChapter: json['lastChapter'] as String?,
      totalChapterNum: (json['totalChapterNum'] as num?)?.toInt() ?? 0,
      durChapterIndex: (json['durChapterIndex'] as num?)?.toInt() ?? 0,
      currentPageIndex: (json['currentPageIndex'] as num?)?.toInt() ?? 0,
      readConfig: BookReadConfig.fromLegacyJson(
        json['readConfig'],
        legacyTopLevelReverseToc: json['reverseToc'] as bool?,
      ),
      isFavorite: json['isFavorite'] as bool? ?? false,
      sourceUrl: json['sourceUrl'] as String? ?? '',
      tocUrl: json['tocUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      bookSourceUrl: json['bookSourceUrl'] as String? ?? '',
      group: json['group'] as String? ?? '',
      readIteration: (json['readIteration'] as num?)?.toInt() ?? 0,
      simReadEnabled: json['simReadEnabled'] as bool? ?? false,
      simReadStartDate: json['simReadStartDate'] as String? ?? '',
      simReadStartChapter: (json['simReadStartChapter'] as num?)?.toInt() ?? 0,
      simReadDailyChapters:
          ((json['simReadDailyChapters'] as num?)?.toInt() ?? 3).clamp(1, 999),
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'author': author,
      'coverUrl': coverUrl,
      'type': type,
      'progress': progress,
      'currentChapter': currentChapter,
      'lastChapter': lastChapter,
      'totalChapterNum': totalChapterNum,
      'durChapterIndex': durChapterIndex,
      'currentPageIndex': currentPageIndex,
      'readConfig': readConfig.toJson(),
      'isFavorite': isFavorite,
      'sourceUrl': sourceUrl,
      'tocUrl': tocUrl,
      'description': description,
      'bookSourceUrl': bookSourceUrl,
      'group': group,
      'readIteration': readIteration,
      'simReadEnabled': simReadEnabled,
      'simReadStartDate': simReadStartDate,
      'simReadStartChapter': simReadStartChapter,
      'simReadDailyChapters': simReadDailyChapters,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  @override
  String toString() => 'Book($name - $author)';
}
