/// 规则订阅 — 对齐 Jingshiro [RuleSub]
const _ruleSubCopyWithUnset = Object();

class RuleSub {
  final int id;
  final String name;
  final String url;

  /// 0 书源 / 1 订阅源 / 2 替换规则
  final int type;
  final int customOrder;
  final bool autoUpdate;
  final int update;
  final int updateInterval;
  final bool silentUpdate;

  /// 访问订阅链接前执行的 JS 规则。
  final String? js;

  /// 订阅内容的显示规则。
  final String? showRule;

  /// 可调用资源所属的书源链接。
  final String? sourceUrl;

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

  static const typeLabels = ['书源', '订阅源', '替换规则'];

  String get typeLabel =>
      type >= 0 && type < typeLabels.length ? typeLabels[type] : typeLabels[0];

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

  factory RuleSub.fromJson(Map<String, dynamic> json) {
    return RuleSub(
      id:
          (json['id'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
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
