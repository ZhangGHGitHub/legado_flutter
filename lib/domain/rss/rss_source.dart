import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'rss_source.freezed.dart';

/// RSS 订阅源 — 对齐 Jingshiro [RssSource.kt] 完整字段。
@freezed
class RssSource with _$RssSource {
  const RssSource._();

  const factory RssSource({
    required String sourceUrl,
    required String sourceName,
    @Default('') String sourceIcon,
    @Default('') String sourceGroup,
    @Default('') String sourceComment,
    @Default(true) bool enabled,
    @Default('') String variableComment,
    @Default('') String jsLib,
    @Default(true) bool enabledCookieJar,
    @Default('') String concurrentRate,
    @Default('') String header,
    String? loginUrl,
    @Default('') String loginUi,
    @Default('') String loginCheckJs,
    @Default('') String coverDecodeJs,
    @Default('') String sortUrl,
    @Default(false) bool singleUrl,
    @Default(0) int articleStyle,
    @Default('') String ruleArticles,
    @Default('') String ruleNextPage,
    @Default('') String ruleTitle,
    @Default('') String rulePubDate,
    @Default('') String ruleDescription,
    @Default('') String ruleImage,
    @Default('') String ruleLink,
    @Default('') String ruleContent,
    @Default('') String contentWhitelist,
    @Default('') String contentBlacklist,
    @Default('') String shouldOverrideUrlLoading,
    @Default('') String style,
    @Default(true) bool enableJs,
    @Default(true) bool loadWithBaseUrl,
    @Default('') String injectJs,
    @Default('') String preloadJs,
    @Default('') String startHtml,
    @Default('') String startStyle,
    @Default('') String startJs,
    @Default(false) bool showWebLog,
    @Default(0) int lastUpdateTime,
    @Default(0) int customOrder,
    @Default(0) int type,
    @Default(false) bool preload,
    @Default(false) bool cacheFirst,
    @Default('') String searchUrl,

    /// 原始 JSON（保留未映射字段）。
    @Default(<String, dynamic>{}) Map<String, dynamic> raw,
  }) = _RssSource;

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

  /// 供 Rust 引擎使用的 JSON。
  String toEngineJson() => jsonEncode(toJson());

  static List<RssSource> listFromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => RssSource.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.sourceUrl.isNotEmpty)
        .toList(growable: false);
  }
}
