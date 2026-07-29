const _ruleSubCopyWithUnset = Object();

/// 规则订阅领域实体，对齐 Legado `RuleSub` 的持久化字段。
class RuleSub {
  const RuleSub({
    required this.id,
    this.name = '',
    this.url = '',
    this.type = 0,
    this.customOrder = 0,
    this.autoUpdate = false,
    this.update = 0,
    this.updateInterval = 0,
    this.silentUpdate = false,
    this.js,
    this.showRule,
    this.sourceUrl,
  });

  final int id;
  final String name;
  final String url;

  /// 0 书源 / 1 订阅源 / 2 替换规则。
  final int type;
  final int customOrder;
  final bool autoUpdate;
  final int update;
  final int updateInterval;
  final bool silentUpdate;
  final String? js;
  final String? showRule;
  final String? sourceUrl;

  RuleSub copyWith({
    int? id,
    String? name,
    String? url,
    int? type,
    int? customOrder,
    bool? autoUpdate,
    int? update,
    int? updateInterval,
    bool? silentUpdate,
    Object? js = _ruleSubCopyWithUnset,
    Object? showRule = _ruleSubCopyWithUnset,
    Object? sourceUrl = _ruleSubCopyWithUnset,
  }) {
    return RuleSub(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      customOrder: customOrder ?? this.customOrder,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      update: update ?? this.update,
      updateInterval: updateInterval ?? this.updateInterval,
      silentUpdate: silentUpdate ?? this.silentUpdate,
      js: identical(js, _ruleSubCopyWithUnset) ? this.js : js as String?,
      showRule: identical(showRule, _ruleSubCopyWithUnset)
          ? this.showRule
          : showRule as String?,
      sourceUrl: identical(sourceUrl, _ruleSubCopyWithUnset)
          ? this.sourceUrl
          : sourceUrl as String?,
    );
  }

  factory RuleSub.fromJson(Map<String, dynamic> json, {int fallbackId = 0}) {
    return RuleSub(
      id: (json['id'] as num?)?.toInt() ?? fallbackId,
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      type: (json['type'] as num?)?.toInt() ?? 0,
      customOrder: (json['customOrder'] as num?)?.toInt() ?? 0,
      autoUpdate: json['autoUpdate'] as bool? ?? false,
      update: (json['update'] as num?)?.toInt() ?? 0,
      updateInterval: (json['updateInterval'] as num?)?.toInt() ?? 0,
      silentUpdate: json['silentUpdate'] as bool? ?? false,
      js: json['js'] as String?,
      showRule: json['showRule'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'type': type,
    'customOrder': customOrder,
    'autoUpdate': autoUpdate,
    'update': update,
    'updateInterval': updateInterval,
    'silentUpdate': silentUpdate,
    'js': js,
    'showRule': showRule,
    'sourceUrl': sourceUrl,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RuleSub && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
