import '../../domain/book/book.dart';

/// 阅读器展示当前书源名称所需的应用端口。
abstract interface class ReaderSourcePresentationPort {
  String sourceNameForBook(Book book);
}

/// 独立宿主未提供书源展示能力时的空展示回退。
final class EmptyReaderSourcePresentationPort
    implements ReaderSourcePresentationPort {
  const EmptyReaderSourcePresentationPort();

  @override
  String sourceNameForBook(Book book) => '';
}
