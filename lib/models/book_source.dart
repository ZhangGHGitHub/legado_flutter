import 'dart:convert';

/// 书源模型 - 兼容 legado 阅读3.0 书源 JSON 格式
class BookSource {
  final String bookSourceUrl;
  final String bookSourceName;
  final String bookSourceType;
  final String bookSourceGroup;
  final bool enabled;

  // ── 搜索规则 ──
  final String ruleSearchUrl;
  final String ruleSearchList;
  final String ruleSearchName;
  final String ruleSearchAuthor;
  final String ruleSearchCoverUrl;
  final String ruleSearchKind;
  final String ruleSearchNote;

  // ── 书籍详情规则 ──
  final String ruleBookUrlPattern;
  final String ruleBookName;
  final String ruleBookAuthor;
  final String ruleBookCoverUrl;
  final String ruleBookKind;
  final String ruleBookNote;
  final String ruleBookLastChapter;

  // ── 目录规则 ──
  final String ruleChapterList;
  final String ruleChapterName;
  final String ruleChapterUrl;
  final String ruleChapterUrlIsFull;

  // ── 正文规则 ──
  final String ruleContentUrl;
  final String ruleContent;
  final String ruleContentRemove;

  // ── 翻页规则 ──
  final String rulePageUrl;
  final String rulePageNext;

  // ── 元信息 ──
  final String bookSourceComment;

  /// 完整 Legado 原始 JSON（保留后端规则，用于 JSON API 书源）
  final String rawSourceJson;

  BookSource({
    required this.bookSourceUrl,
    required this.bookSourceName,
    this.bookSourceType = '0',
    this.bookSourceGroup = '',
    this.enabled = true,
    this.ruleSearchUrl = '',
    this.ruleSearchList = '',
    this.ruleSearchName = '',
    this.ruleSearchAuthor = '',
    this.ruleSearchCoverUrl = '',
    this.ruleSearchKind = '',
    this.ruleSearchNote = '',
    this.ruleBookUrlPattern = '',
    this.ruleBookName = '',
    this.ruleBookAuthor = '',
    this.ruleBookCoverUrl = '',
    this.ruleBookKind = '',
    this.ruleBookNote = '',
    this.ruleBookLastChapter = '',
    this.ruleChapterList = '',
    this.ruleChapterName = '',
    this.ruleChapterUrl = '',
    this.ruleChapterUrlIsFull = '',
    this.ruleContentUrl = '',
    this.ruleContent = '',
    this.ruleContentRemove = '',
    this.rulePageUrl = '',
    this.rulePageNext = '',
    this.bookSourceComment = '',
    this.rawSourceJson = '',
  });

  /// 是否为 JSON API 书源（有 rawSourceJson 且包含 JSON 路径规则）
  bool get isJsonApiSource {
    if (rawSourceJson.isEmpty) return false;
    try {
      final obj = jsonDecode(rawSourceJson) as Map<String, dynamic>;
      // 检查是否有 JSON 路径规则（以 $ 开头的规则字段）
      bool hasJsonRule(String key) {
        final val = obj[key];
        if (val is String) return val.startsWith(r'$');
        if (val is Map) return val.values.any((v) => v is String && v.startsWith(r'$'));
        return false;
      }
      return hasJsonRule('ruleSearch') || hasJsonRule('ruleContent') || hasJsonRule('ruleToc');
    } catch (_) {
      return false;
    }
  }

  /// 从 rawSourceJson 中提取某个 JSON 路径下的值
  String _rawExtract(String key, String subKey) {
    if (rawSourceJson.isEmpty) return '';
    try {
      final obj = jsonDecode(rawSourceJson) as Map<String, dynamic>;
      final inner = obj[key];
      if (inner is Map) {
        final val = inner[subKey];
        if (val is String) return val;
        if (val != null) return const JsonEncoder().convert(val);
      }
    } catch (_) {}
    return '';
  }

  /// 从 rawSourceJson 中提取某个 JSON 子对象（序列化为字符串）
  String _rawSubObject(String key) {
    if (rawSourceJson.isEmpty) return '';
    try {
      final obj = jsonDecode(rawSourceJson) as Map<String, dynamic>;
      final inner = obj[key];
      if (inner is Map) return const JsonEncoder().convert(inner);
    } catch (_) {}
    return '';
  }

  /// ruleSearch JSON 对象
  String get ruleSearchJson => _rawSubObject('ruleSearch');
  /// ruleBookInfo JSON 对象
  String get ruleBookInfoJson => _rawSubObject('ruleBookInfo');
  /// ruleToc JSON 对象
  String get ruleTocJson => _rawSubObject('ruleToc');
  /// ruleContent JSON 对象
  String get ruleContentRuleJson => _rawSubObject('ruleContent');

  /// 获取 ruleToc 的某个子字段值（从 rawSourceJson 直接取）
  String get ruleTocChapterList => _rawExtract('ruleToc', 'chapterList');
  String get ruleTocChapterName => _rawExtract('ruleToc', 'chapterName');
  String get ruleTocChapterUrl => _rawExtract('ruleToc', 'chapterUrl');
  /// 获取 ruleBookInfo 的 tocUrl
  String get ruleBookInfoTocUrl => _rawExtract('ruleBookInfo', 'tocUrl');
  /// 获取 ruleContent 的 content 路径
  String get ruleContentPath => _rawExtract('ruleContent', 'content');

  /// 获取 ruleSearch 的 bookUrl（搜索结果中书本链接的提取规则）
  String get ruleSearchBookUrl => _rawExtract('ruleSearch', 'bookUrl');

  /// 获取书源自定义请求头（header 字段）
  Map<String, String> get customHeaders {
    if (rawSourceJson.isEmpty) return {};
    try {
      final obj = jsonDecode(rawSourceJson) as Map<String, dynamic>;
      final header = obj['header'];
      if (header is Map) {
        return header.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return {};
  }

  factory BookSource.fromJson(Map<String, dynamic> json) {
    String? safeString(dynamic v) => (v is String) && v.isNotEmpty ? v : null;
    bool safeBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      return true;
    }

    // Legado 兼容: searchUrl → ruleSearchUrl
    final resolvedSearchUrl =
        safeString(json['ruleSearchUrl']) ?? safeString(json['searchUrl']) ?? '';

    // 兼容 Legado 嵌套格式: ruleSearch.bookList → ruleSearchList
    String? nested(String outerKey, String innerKey, {String? flatKey}) {
      // 优先用顶层字段
      if (flatKey != null) {
        final flat = safeString(json[flatKey]);
        if (flat != null && flat.isNotEmpty) return flat;
      }
      // 再从嵌套对象提取
      final outer = json[outerKey];
      if (outer is Map) {
        final val = outer[innerKey];
        if (val is String && val.isNotEmpty) return val;
      }
      return null;
    }

    // 保留完整原始 JSON
    String rawJson = '';
    try {
      rawJson = const JsonEncoder().convert(json);
    } catch (_) {}

    return BookSource(
      bookSourceUrl: safeString(json['bookSourceUrl']) ?? '',
      bookSourceName: safeString(json['bookSourceName']) ?? '未命名书源',
      bookSourceType: safeString(json['bookSourceType']) ?? '0',
      bookSourceGroup: safeString(json['bookSourceGroup']) ?? '',
      enabled: safeBool(json['enabled']),
      ruleSearchUrl: resolvedSearchUrl,
      ruleSearchList: nested('ruleSearch', 'bookList', flatKey: 'ruleSearchList') ?? '',
      ruleSearchName: nested('ruleSearch', 'name', flatKey: 'ruleSearchName') ?? '',
      ruleSearchAuthor: nested('ruleSearch', 'author', flatKey: 'ruleSearchAuthor') ?? '',
      ruleSearchCoverUrl: nested('ruleSearch', 'coverUrl', flatKey: 'ruleSearchCoverUrl') ?? '',
      ruleSearchKind: nested('ruleSearch', 'kind', flatKey: 'ruleSearchKind') ?? '',
      ruleSearchNote: nested('ruleSearch', 'note', flatKey: 'ruleSearchNote') ?? '',
      ruleBookUrlPattern: safeString(json['ruleBookUrlPattern']) ?? '',
      ruleBookName: nested('ruleBookInfo', 'name', flatKey: 'ruleBookName') ?? '',
      ruleBookAuthor: nested('ruleBookInfo', 'author', flatKey: 'ruleBookAuthor') ?? '',
      ruleBookCoverUrl: nested('ruleBookInfo', 'coverUrl', flatKey: 'ruleBookCoverUrl') ?? '',
      ruleBookKind: safeString(json['ruleBookKind']) ?? '',
      ruleBookNote: safeString(json['ruleBookNote']) ?? '',
      ruleBookLastChapter: safeString(json['ruleBookLastChapter']) ?? '',
      ruleChapterList: nested('ruleToc', 'chapterList', flatKey: 'ruleChapterList') ?? '',
      ruleChapterName: nested('ruleToc', 'chapterName', flatKey: 'ruleChapterName') ?? '',
      ruleChapterUrl: nested('ruleToc', 'chapterUrl', flatKey: 'ruleChapterUrl') ?? '',
      ruleChapterUrlIsFull: safeString(json['ruleChapterUrlIsFull']) ?? '',
      ruleContentUrl: safeString(json['ruleContentUrl']) ?? '',
      ruleContent: nested('ruleContent', 'content', flatKey: 'ruleContent') ?? '',
      ruleContentRemove: safeString(json['ruleContentRemove']) ?? '',
      rulePageUrl: safeString(json['rulePageUrl']) ?? '',
      rulePageNext: safeString(json['rulePageNext']) ?? '',
      bookSourceComment: safeString(json['bookSourceComment']) ?? '',
      rawSourceJson: rawJson,
    );
  }

  Map<String, dynamic> toJson() => {
    'bookSourceUrl': bookSourceUrl,
    'bookSourceName': bookSourceName,
    'bookSourceType': bookSourceType,
    'bookSourceGroup': bookSourceGroup,
    'enabled': enabled,
    'ruleSearchUrl': ruleSearchUrl,
    'ruleSearchList': ruleSearchList,
    'ruleSearchName': ruleSearchName,
    'ruleSearchAuthor': ruleSearchAuthor,
    'ruleSearchCoverUrl': ruleSearchCoverUrl,
    'ruleSearchKind': ruleSearchKind,
    'ruleSearchNote': ruleSearchNote,
    'ruleBookUrlPattern': ruleBookUrlPattern,
    'ruleBookName': ruleBookName,
    'ruleBookAuthor': ruleBookAuthor,
    'ruleBookCoverUrl': ruleBookCoverUrl,
    'ruleBookKind': ruleBookKind,
    'ruleBookNote': ruleBookNote,
    'ruleBookLastChapter': ruleBookLastChapter,
    'ruleChapterList': ruleChapterList,
    'ruleChapterName': ruleChapterName,
    'ruleChapterUrl': ruleChapterUrl,
    'ruleChapterUrlIsFull': ruleChapterUrlIsFull,
    'ruleContentUrl': ruleContentUrl,
    'ruleContent': ruleContent,
    'ruleContentRemove': ruleContentRemove,
    'rulePageUrl': rulePageUrl,
    'rulePageNext': rulePageNext,
    'bookSourceComment': bookSourceComment,
    'rawSourceJson': rawSourceJson,
  };

  @override
  String toString() => 'BookSource($bookSourceName)';
}
