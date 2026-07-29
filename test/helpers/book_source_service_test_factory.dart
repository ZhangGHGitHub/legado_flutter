import 'package:legado_flutter/domain/ports/book_source_book_info_port.dart';
import 'package:legado_flutter/domain/ports/book_source_content_port.dart';
import 'package:legado_flutter/domain/ports/book_source_explore_port.dart';
import 'package:legado_flutter/domain/ports/book_source_search_port.dart';
import 'package:legado_flutter/domain/ports/book_source_toc_port.dart';
import 'package:legado_flutter/domain/ports/public_text_fetch_port.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_book_info_port.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_content_port.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_explore_port.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_search_port.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_toc_port.dart';
import 'package:legado_flutter/infrastructure/network/frb_public_text_fetch_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/services/book_source_service.dart';

BookSourceService createTestBookSourceService({
  BookSourceSearchPort? searchPort,
  BookSourceBookInfoPort? bookInfoPort,
  BookSourceContentPort? contentPort,
  BookSourceExplorePort? explorePort,
  BookSourceTocPort? tocPort,
  PublicTextFetchPort? publicTextPort,
}) {
  return BookSourceService(
    searchPort: searchPort ?? const StubBookSourcePorts(),
    bookInfoPort: bookInfoPort ?? const StubBookSourcePorts(),
    contentPort: contentPort ?? const StubBookSourcePorts(),
    explorePort: explorePort ?? const StubBookSourcePorts(),
    tocPort: tocPort ?? const StubBookSourcePorts(),
    publicTextPort: publicTextPort ?? const StubBookSourcePorts(),
  );
}

BookSourceService createFrbBookSourceService() {
  return BookSourceService(
    searchPort: FrbBookSourceSearchPort(),
    bookInfoPort: FrbBookSourceBookInfoPort(),
    contentPort: FrbBookSourceContentPort(),
    explorePort: FrbBookSourceExplorePort(),
    tocPort: FrbBookSourceTocPort(),
    publicTextPort: const FrbPublicTextFetchPort(),
  );
}

class TestBookSourceService extends BookSourceService {
  TestBookSourceService()
    : super(
        searchPort: const StubBookSourcePorts(),
        bookInfoPort: const StubBookSourcePorts(),
        contentPort: const StubBookSourcePorts(),
        explorePort: const StubBookSourcePorts(),
        tocPort: const StubBookSourcePorts(),
        publicTextPort: const StubBookSourcePorts(),
      );
}

class StubBookSourcePorts
    implements
        BookSourceSearchPort,
        BookSourceBookInfoPort,
        BookSourceContentPort,
        BookSourceExplorePort,
        BookSourceTocPort,
        PublicTextFetchPort {
  const StubBookSourcePorts();

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async => const [];

  @override
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async => const {};

  @override
  Future<String> getContent(BookSource source, String chapterUrl) async => '';

  @override
  Future<List<Map<String, String>>> explore(
    BookSource source,
    String exploreUrl, {
    int page = 1,
  }) async => const [];

  @override
  Future<List<Chapter>> getToc(BookSource source, Book book) async => const [];

  @override
  Future<String> fetch(String url, {String userAgent = ''}) async => '';
}
