/// Per-book reader settings persisted inside the Book `readConfig` record.
class BookReadConfig {
  final bool reverseToc;
  final Map<String, dynamic> _extra;

  const BookReadConfig({
    this.reverseToc = false,
    Map<String, dynamic> extra = const {},
  }) : _extra = extra;

  factory BookReadConfig.fromJson(
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
    return BookReadConfig(
      reverseToc: reverse,
      extra: Map<String, dynamic>.unmodifiable(map),
    );
  }

  BookReadConfig copyWith({bool? reverseToc}) {
    return BookReadConfig(
      reverseToc: reverseToc ?? this.reverseToc,
      extra: _extra,
    );
  }

  Map<String, dynamic> toJson() {
    return {..._extra, 'reverseToc': reverseToc};
  }
}

/// 书籍模型 - 对应 legado 的一本书
class Book {
  final String id;
  final String name;
  final String author;
  final String coverUrl;
  final String type; // 来源类型: local / online
  final double progress; // 阅读进度 0.0 ~ 1.0
  final String? currentChapter; // 已读到章节名
  final String? lastChapter; // 最新章节名（从书源获取的最新更新）
  /// 目录总章数（对齐 legado `totalChapterNum`）
  final int totalChapterNum;

  /// 当前阅读章 0-based 索引（对齐 legado `durChapterIndex`）
  final int durChapterIndex;
  final int currentPageIndex; // 当前章节内阅读到的页面索引
  /// Per-book reader settings. `reverseToc` lives inside this record in the
  /// original app rather than as a top-level Book field.
  final BookReadConfig readConfig;
  final bool isFavorite;
  final String sourceUrl; // 书籍来源链接（如章节列表 URL）
  /// 目录链接（对齐 legado `tocUrl`）
  final String tocUrl;
  final String description; // 书籍简介
  final String bookSourceUrl; // 搜索到此书的书源 URL（用于匹配书源规则）
  final String group; // 书架分组
  /// 阅读轮次（对齐 Jingshiro `readIteration`）：
  /// 0=未读完，1=读完，2=二刷，3=二刷完，依此类推。
  final int readIteration;

  /// 模拟追读：开关
  final bool simReadEnabled;

  /// 模拟追读：开始日期（YYYY-MM-DD）；空表示未写入 DB
  final String simReadStartDate;

  /// 模拟追读：0-based 起始章节
  final int simReadStartChapter;

  /// 模拟追读：每日解锁章数
  final int simReadDailyChapters;

  /// SQLite `updatedAt`（阅读/更新时间排序用）
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

  /// 「读完」「N刷」「N刷完」标签文案；无标记时返回 null
  String? get readStatusLabel => labelForReadIteration(readIteration);

  /// 0=无，1=读完，2=二刷，3=二刷完…
  static String? labelForReadIteration(int readIteration) {
    if (readIteration <= 0) return null;
    if (readIteration == 1) return '读完';
    if (readIteration.isOdd) {
      return '${(readIteration + 1) ~/ 2}刷完';
    }
    return '${readIteration ~/ 2 + 1}刷';
  }

  /// 复制并修改部分字段
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

  /// 从 JSON 创建
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
      readConfig: BookReadConfig.fromJson(
        json['readConfig'],
        // Compatibility with an intermediate Flutter build that briefly
        // emitted a top-level field; new records are always nested.
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

  /// 转为 JSON
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
