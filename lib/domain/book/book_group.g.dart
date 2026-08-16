// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookGroupImpl _$$BookGroupImplFromJson(Map<String, dynamic> json) =>
    _$BookGroupImpl(
      groupId: (json['groupId'] as num?)?.toInt() ?? 0,
      groupName: json['groupName'] as String? ?? '',
      cover: json['cover'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      enableRefresh: json['enableRefresh'] as bool? ?? true,
      show: json['show'] as bool? ?? true,
      bookSort: (json['bookSort'] as num?)?.toInt() ?? -1,
      onlyUpdateRead: json['onlyUpdateRead'] as bool? ?? false,
    );

Map<String, dynamic> _$$BookGroupImplToJson(_$BookGroupImpl instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'groupName': instance.groupName,
      'cover': instance.cover,
      'order': instance.order,
      'enableRefresh': instance.enableRefresh,
      'show': instance.show,
      'bookSort': instance.bookSort,
      'onlyUpdateRead': instance.onlyUpdateRead,
    };
