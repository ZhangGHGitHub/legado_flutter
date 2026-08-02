import 'package:freezed_annotation/freezed_annotation.dart';

part 'rule_sub.freezed.dart';

/// 规则订阅领域实体，对齐 Legado `RuleSub` 的持久化字段。
@Freezed(equal: false, fromJson: false, toJson: false)
class RuleSub with _$RuleSub {
  const RuleSub._();

  const factory RuleSub({
    required int id,
    @Default('') String name,
    @Default('') String url,

    /// 0 书源 / 1 订阅源 / 2 替换规则。
    @Default(0) int type,
    @Default(0) int customOrder,
    @Default(false) bool autoUpdate,
    @Default(0) int update,
    @Default(0) int updateInterval,
    @Default(false) bool silentUpdate,
    String? js,
    String? showRule,
    String? sourceUrl,
  }) = _RuleSub;

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
