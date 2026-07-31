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
class Book {
  final String id;
  final String name;
  final String author;
  final String coverUrl;
  final String type;
  final double progress;
  final String? currentChapter;
  final String? lastChapter;
  final int totalChapterNum;
  final int durChapterIndex;
  final int currentPageIndex;
  final BookReadConfig readConfig;
  final bool isFavorite;
  final String sourceUrl;
  final String tocUrl;
  final String description;
  final String bookSourceUrl;
  final String group;
  final int readIteration;
  final bool simReadEnabled;
  final String simReadStartDate;
  final int simReadStartChapter;
  final int simReadDailyChapters;
  final String? updatedAt;

  Book({
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
  });

  Book copyWith({
    String? id,
    String? name,
    String? author,
    String? coverUrl,
    String? type,
    double? progress,
    String? currentChapter,
    String? lastChapter,
    int? totalChapterNum,
    int? durChapterIndex,
    int? currentPageIndex,
    BookReadConfig? readConfig,
    bool? isFavorite,
    String? sourceUrl,
    String? tocUrl,
    String? description,
    String? bookSourceUrl,
    String? group,
    int? readIteration,
    bool? simReadEnabled,
    String? simReadStartDate,
    int? simReadStartChapter,
    int? simReadDailyChapters,
    String? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      currentChapter: currentChapter ?? this.currentChapter,
      lastChapter: lastChapter ?? this.lastChapter,
      totalChapterNum: totalChapterNum ?? this.totalChapterNum,
      durChapterIndex: durChapterIndex ?? this.durChapterIndex,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      readConfig: readConfig ?? this.readConfig,
      isFavorite: isFavorite ?? this.isFavorite,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      tocUrl: tocUrl ?? this.tocUrl,
      description: description ?? this.description,
      bookSourceUrl: bookSourceUrl ?? this.bookSourceUrl,
      group: group ?? this.group,
      readIteration: readIteration ?? this.readIteration,
      simReadEnabled: simReadEnabled ?? this.simReadEnabled,
      simReadStartDate: simReadStartDate ?? this.simReadStartDate,
      simReadStartChapter: simReadStartChapter ?? this.simReadStartChapter,
      simReadDailyChapters: simReadDailyChapters ?? this.simReadDailyChapters,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
