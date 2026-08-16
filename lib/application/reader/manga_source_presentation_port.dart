import '../../domain/book/book.dart';

/// 漫画阅读菜单展示当前书源名称所需的应用端口。
abstract interface class MangaSourcePresentationPort {
  String sourceNameForBook(Book book);
}

/// 独立宿主未提供书源展示能力时的原有回退。
final class EmptyMangaSourcePresentationPort
    implements MangaSourcePresentationPort {
  const EmptyMangaSourcePresentationPort();

  @override
  String sourceNameForBook(Book book) => '书源';
}
