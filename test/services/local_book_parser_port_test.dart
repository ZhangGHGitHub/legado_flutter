import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/local_book_parser_port.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/services/local_book_service.dart';

void main() {
  late Directory tempRoot;
  late _FakeBookRepository repository;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('legado_local_book_port_');
    repository = _FakeBookRepository();
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  test('TXT import forwards parsing through the replaceable port', () async {
    final parser = _FakeLocalBookParser(
      txtChapters: const [
        LocalBookChapterSnapshot(title: '第一章', content: '正文一'),
        LocalBookChapterSnapshot(title: '第二章', content: '正文二'),
      ],
    );
    final path = File('${tempRoot.path}\\book.txt')..writeAsStringSync('raw');

    final book = await LocalBookService(
      repository: repository,
      parser: parser,
    ).importFromPath(path.path);

    expect(parser.txtInput, 'raw');
    expect(book.name, 'book');
    expect(repository.chapters.map((chapter) => chapter.title), ['第一章', '第二章']);
    expect(repository.chapters.map((chapter) => chapter.content), [
      '正文一',
      '正文二',
    ]);
  });

  test('EPUB import forwards metadata and chapters through the port', () async {
    final parser = _FakeLocalBookParser(
      epub: const LocalBookEpubSnapshot(
        title: '解析书名',
        author: '解析作者',
        chapters: [LocalBookChapterSnapshot(title: '序章', content: '序章正文')],
      ),
    );
    final path = File('${tempRoot.path}\\book.epub')..writeAsBytesSync([1]);

    final book = await LocalBookService(
      repository: repository,
      parser: parser,
    ).importFromPath(path.path);

    expect(parser.epubInput, [1]);
    expect(book.name, '解析书名');
    expect(book.author, '解析作者');
    expect(repository.chapters.single.title, '序章');
    expect(repository.chapters.single.content, '序章正文');
  });
}

class _FakeLocalBookParser implements LocalBookParserPort {
  _FakeLocalBookParser({this.txtChapters = const [], this.epub});

  final List<LocalBookChapterSnapshot> txtChapters;
  final LocalBookEpubSnapshot? epub;

  String? txtInput;
  List<int>? epubInput;

  @override
  bool get isAvailable => true;

  @override
  List<LocalBookChapterSnapshot> parseTxtChapters(String content) {
    txtInput = content;
    return txtChapters;
  }

  @override
  LocalBookEpubSnapshot parseEpub(List<int> data) {
    epubInput = data;
    return epub!;
  }
}

class _FakeBookRepository implements BookRepository {
  final chapters = <Chapter>[];

  @override
  Future<void> insert(Book book) async {}

  @override
  Future<List<Book>> getAll() async => const [];

  @override
  Future<void> updateProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) async {}

  @override
  Future<void> delete(String bookId) async {}

  @override
  Future<void> updateCover(String bookId, String coverUrl) async {}

  @override
  Future<void> updateGroup(String bookId, String group) async {}

  @override
  Future<void> insertChapters(List<Chapter> chapters) async {
    this.chapters.addAll(chapters);
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async => chapters;

  @override
  Future<String?> getChapterContent(String chapterId) async => null;

  @override
  Future<void> saveChapterContent(String chapterId, String content) async {}

  @override
  Future<void> clearChapterContent(Chapter chapter) async {}
}
