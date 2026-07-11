import 'dart:convert';

/// RSS 订阅源 — 对齐 Jingshiro [RssSource](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/data/entities/RssSource.kt)
class RssSource {
  final String sourceUrl;
  final String sourceName;
  final String sourceIcon;
  final String sourceGroup;
  final bool enabled;
  final String? loginUrl;
  final int customOrder;

  const RssSource({
    required this.sourceUrl,
    required this.sourceName,
    this.sourceIcon = '',
    this.sourceGroup = '',
    this.enabled = true,
    this.loginUrl,
    this.customOrder = 0,
  });

  RssSource copyWith({
    String? sourceUrl,
    String? sourceName,
    String? sourceIcon,
    String? sourceGroup,
    bool? enabled,
    String? loginUrl,
    int? customOrder,
  }) {
    return RssSource(
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceName: sourceName ?? this.sourceName,
      sourceIcon: sourceIcon ?? this.sourceIcon,
      sourceGroup: sourceGroup ?? this.sourceGroup,
      enabled: enabled ?? this.enabled,
      loginUrl: loginUrl ?? this.loginUrl,
      customOrder: customOrder ?? this.customOrder,
    );
  }

  factory RssSource.fromJson(Map<String, dynamic> json) {
    return RssSource(
      sourceUrl: json['sourceUrl'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? '',
      sourceIcon: json['sourceIcon'] as String? ?? '',
      sourceGroup: json['sourceGroup'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      loginUrl: json['loginUrl'] as String?,
      customOrder: json['customOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceUrl': sourceUrl,
        'sourceName': sourceName,
        'sourceIcon': sourceIcon,
        'sourceGroup': sourceGroup,
        'enabled': enabled,
        if (loginUrl != null) 'loginUrl': loginUrl,
        'customOrder': customOrder,
      };

  static List<RssSource> listFromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(RssSource.fromJson)
        .where((s) => s.sourceUrl.isNotEmpty)
        .toList();
  }
}
