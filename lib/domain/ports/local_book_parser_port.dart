import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_book_parser_port.freezed.dart';

/// 本地书籍解析结果中的章节。
@freezed
class LocalBookChapterSnapshot with _$LocalBookChapterSnapshot {
  const factory LocalBookChapterSnapshot({
    required String title,
    required String content,
  }) = _LocalBookChapterSnapshot;
}

/// EPUB 元数据和章节解析结果。
@freezed
class LocalBookEpubSnapshot with _$LocalBookEpubSnapshot {
  const factory LocalBookEpubSnapshot({
    required String title,
    required String author,
    required List<LocalBookChapterSnapshot> chapters,
  }) = _LocalBookEpubSnapshot;
}

/// 本地 TXT/EPUB 解析所需的最小引擎端口。
abstract interface class LocalBookParserPort {
  bool get isAvailable;

  List<LocalBookChapterSnapshot> parseTxtChapters(String content);

  LocalBookEpubSnapshot parseEpub(List<int> data);
}
