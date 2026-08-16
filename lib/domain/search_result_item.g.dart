// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SearchResultItemImpl _$$SearchResultItemImplFromJson(
  Map<String, dynamic> json,
) => _$SearchResultItemImpl(
  name: json['name'] as String,
  author: json['author'] as String,
  bookUrl: json['bookUrl'] as String,
  coverUrl: json['coverUrl'] as String? ?? '',
  kind: json['kind'] as String? ?? '',
  note: json['note'] as String? ?? '',
);

Map<String, dynamic> _$$SearchResultItemImplToJson(
  _$SearchResultItemImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'author': instance.author,
  'bookUrl': instance.bookUrl,
  'coverUrl': instance.coverUrl,
  'kind': instance.kind,
  'note': instance.note,
};
