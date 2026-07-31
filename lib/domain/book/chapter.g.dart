// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChapterImpl _$$ChapterImplFromJson(Map<String, dynamic> json) =>
    _$ChapterImpl(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      title: json['title'] as String,
      index: _chapterIndexFromJson(json['index']),
      url: json['url'] as String? ?? '',
      isVolume: json['isVolume'] as bool? ?? false,
      isVip: json['isVip'] as bool? ?? false,
      isPay: json['isPay'] as bool? ?? false,
      tag: json['tag'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      content: json['content'] as String?,
    );

Map<String, dynamic> _$$ChapterImplToJson(_$ChapterImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookId': instance.bookId,
      'title': instance.title,
      'index': instance.index,
      'url': instance.url,
      'isVolume': instance.isVolume,
      'isVip': instance.isVip,
      'isPay': instance.isPay,
      'tag': instance.tag,
      'baseUrl': instance.baseUrl,
      'isDownloaded': instance.isDownloaded,
      'content': instance.content,
    };
