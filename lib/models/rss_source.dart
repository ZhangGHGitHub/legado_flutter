import 'dart:convert';

/// RSS 订阅源 — 对齐 Jingshiro [RssSource.kt] 完整字段。
class RssSource {
  final String sourceUrl;
  final String sourceName;
  final String sourceIcon;
  final String sourceGroup;
  final String sourceComment;
  final bool enabled;
  final String variableComment;
  final String jsLib;
  final bool enabledCookieJar;
  final String concurrentRate;
  final String header;
  final String? loginUrl;
  final String loginUi;
  final String loginCheckJs;
  final String coverDecodeJs;
  final String sortUrl;
  final bool singleUrl;
  final int articleStyle;
  final String ruleArticles;
  final String ruleNextPage;
  final String ruleTitle;
  final String rulePubDate;
  final String ruleDescription;
  final String ruleImage;
  final String ruleLink;
  final String ruleContent;
  final String contentWhitelist;
  final String contentBlacklist;
  final String shouldOverrideUrlLoading;
  final String style;
  final bool enableJs;
  final bool loadWithBaseUrl;
  final String injectJs;
  final String preloadJs;
  final String startHtml;
  final String startStyle;
  final String startJs;
  final bool showWebLog;
  final int lastUpdateTime;
  final int customOrder;
  final int type;
  final bool preload;
  final bool cacheFirst;
  final String searchUrl;

  /// 原始 JSON（保留未映射字段）
  final Map<String, dynamic> raw;

  const RssSource({
    required this.sourceUrl,
    required this.sourceName,
    this.sourceIcon = '',
    this.sourceGroup = '',
    this.sourceComment = '',
    this.enabled = true,
    this.variableComment = '',
    this.jsLib = '',
    this.enabledCookieJar = true,
    this.concurrentRate = '',
    this.header = '',
    this.loginUrl,
    this.loginUi = '',
    this.loginCheckJs = '',
    this.coverDecodeJs = '',
    this.sortUrl = '',
    this.singleUrl = false,
    this.articleStyle = 0,
    this.ruleArticles = '',
    this.ruleNextPage = '',
    this.ruleTitle = '',
    this.rulePubDate = '',
    this.ruleDescription = '',
    this.ruleImage = '',
    this.ruleLink = '',
    this.ruleContent = '',
    this.contentWhitelist = '',
    this.contentBlacklist = '',
    this.shouldOverrideUrlLoading = '',
    this.style = '',
    this.enableJs = true,
    this.loadWithBaseUrl = true,
    this.injectJs = '',
    this.preloadJs = '',
    this.startHtml = '',
    this.startStyle = '',
    this.startJs = '',
    this.showWebLog = false,
    this.lastUpdateTime = 0,
    this.customOrder = 0,
    this.type = 0,
    this.preload = false,
    this.cacheFirst = false,
    this.searchUrl = '',
    this.raw = const {},
  });

  RssSource copyWith({
    String? sourceUrl,
    String? sourceName,
    String? sourceIcon,
    String? sourceGroup,
    bool? enabled,
    String? loginUrl,
    int? customOrder,
    Map<String, dynamic>? raw,
  }) {
    return RssSource(
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceName: sourceName ?? this.sourceName,
      sourceIcon: sourceIcon ?? this.sourceIcon,
      sourceGroup: sourceGroup ?? this.sourceGroup,
      sourceComment: sourceComment,
      enabled: enabled ?? this.enabled,
      variableComment: variableComment,
      jsLib: jsLib,
      enabledCookieJar: enabledCookieJar,
      concurrentRate: concurrentRate,
      header: header,
      loginUrl: loginUrl ?? this.loginUrl,
      loginUi: loginUi,
      loginCheckJs: loginCheckJs,
      coverDecodeJs: coverDecodeJs,
      sortUrl: sortUrl,
      singleUrl: singleUrl,
      articleStyle: articleStyle,
      ruleArticles: ruleArticles,
      ruleNextPage: ruleNextPage,
      ruleTitle: ruleTitle,
      rulePubDate: rulePubDate,
      ruleDescription: ruleDescription,
      ruleImage: ruleImage,
      ruleLink: ruleLink,
      ruleContent: ruleContent,
      contentWhitelist: contentWhitelist,
      contentBlacklist: contentBlacklist,
      shouldOverrideUrlLoading: shouldOverrideUrlLoading,
      style: style,
      enableJs: enableJs,
      loadWithBaseUrl: loadWithBaseUrl,
      injectJs: injectJs,
      preloadJs: preloadJs,
      startHtml: startHtml,
      startStyle: startStyle,
      startJs: startJs,
      showWebLog: showWebLog,
      lastUpdateTime: lastUpdateTime,
      customOrder: customOrder ?? this.customOrder,
      type: type,
      preload: preload,
      cacheFirst: cacheFirst,
      searchUrl: searchUrl,
      raw: raw ?? this.raw,
    );
  }

  static String _str(Map<String, dynamic> json, String key) =>
      json[key]?.toString() ?? '';

  static bool _bool(Map<String, dynamic> json, String key, [bool def = false]) {
    final v = json[key];
    if (v is bool) return v;
    if (v == null) return def;
    return v.toString() == 'true' || v.toString() == '1';
  }

  static int _int(Map<String, dynamic> json, String key, [int def = 0]) {
    final v = json[key];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? def;
  }

  factory RssSource.fromJson(Map<String, dynamic> json) {
    return RssSource(
      sourceUrl: _str(json, 'sourceUrl'),
      sourceName: _str(json, 'sourceName'),
      sourceIcon: _str(json, 'sourceIcon'),
      sourceGroup: _str(json, 'sourceGroup'),
      sourceComment: _str(json, 'sourceComment'),
      enabled: _bool(json, 'enabled', true),
      variableComment: _str(json, 'variableComment'),
      jsLib: _str(json, 'jsLib'),
      enabledCookieJar: _bool(json, 'enabledCookieJar', true),
      concurrentRate: _str(json, 'concurrentRate'),
      header: _str(json, 'header'),
      loginUrl: json['loginUrl']?.toString(),
      loginUi: _str(json, 'loginUi'),
      loginCheckJs: _str(json, 'loginCheckJs'),
      coverDecodeJs: _str(json, 'coverDecodeJs'),
      sortUrl: _str(json, 'sortUrl'),
      singleUrl: _bool(json, 'singleUrl'),
      articleStyle: _int(json, 'articleStyle'),
      ruleArticles: _str(json, 'ruleArticles'),
      ruleNextPage: _str(json, 'ruleNextPage'),
      ruleTitle: _str(json, 'ruleTitle'),
      rulePubDate: _str(json, 'rulePubDate'),
      ruleDescription: _str(json, 'ruleDescription'),
      ruleImage: _str(json, 'ruleImage'),
      ruleLink: _str(json, 'ruleLink'),
      ruleContent: _str(json, 'ruleContent'),
      contentWhitelist: _str(json, 'contentWhitelist'),
      contentBlacklist: _str(json, 'contentBlacklist'),
      shouldOverrideUrlLoading: _str(json, 'shouldOverrideUrlLoading'),
      style: _str(json, 'style'),
      enableJs: _bool(json, 'enableJs', true),
      loadWithBaseUrl: _bool(json, 'loadWithBaseUrl', true),
      injectJs: _str(json, 'injectJs'),
      preloadJs: _str(json, 'preloadJs'),
      startHtml: _str(json, 'startHtml'),
      startStyle: _str(json, 'startStyle'),
      startJs: _str(json, 'startJs'),
      showWebLog: _bool(json, 'showWebLog'),
      lastUpdateTime: _int(json, 'lastUpdateTime'),
      customOrder: _int(json, 'customOrder'),
      type: _int(json, 'type'),
      preload: _bool(json, 'preload'),
      cacheFirst: _bool(json, 'cacheFirst'),
      searchUrl: _str(json, 'searchUrl'),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    final map = Map<String, dynamic>.from(raw);
    map.addAll({
      'sourceUrl': sourceUrl,
      'sourceName': sourceName,
      'sourceIcon': sourceIcon,
      'sourceGroup': sourceGroup,
      'sourceComment': sourceComment,
      'enabled': enabled,
      'variableComment': variableComment,
      'jsLib': jsLib,
      'enabledCookieJar': enabledCookieJar,
      'concurrentRate': concurrentRate,
      'header': header,
      if (loginUrl != null) 'loginUrl': loginUrl,
      'loginUi': loginUi,
      'loginCheckJs': loginCheckJs,
      'coverDecodeJs': coverDecodeJs,
      'sortUrl': sortUrl,
      'singleUrl': singleUrl,
      'articleStyle': articleStyle,
      'ruleArticles': ruleArticles,
      'ruleNextPage': ruleNextPage,
      'ruleTitle': ruleTitle,
      'rulePubDate': rulePubDate,
      'ruleDescription': ruleDescription,
      'ruleImage': ruleImage,
      'ruleLink': ruleLink,
      'ruleContent': ruleContent,
      'contentWhitelist': contentWhitelist,
      'contentBlacklist': contentBlacklist,
      'shouldOverrideUrlLoading': shouldOverrideUrlLoading,
      'style': style,
      'enableJs': enableJs,
      'loadWithBaseUrl': loadWithBaseUrl,
      'injectJs': injectJs,
      'preloadJs': preloadJs,
      'startHtml': startHtml,
      'startStyle': startStyle,
      'startJs': startJs,
      'showWebLog': showWebLog,
      'lastUpdateTime': lastUpdateTime,
      'customOrder': customOrder,
      'type': type,
      'preload': preload,
      'cacheFirst': cacheFirst,
      'searchUrl': searchUrl,
    });
    return map;
  }

  /// 供 Rust 引擎使用的 JSON
  String toEngineJson() => jsonEncode(toJson());

  static List<RssSource> listFromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => RssSource.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.sourceUrl.isNotEmpty)
        .toList();
  }
}
