import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/change_cover_controller.dart';
import 'package:legado_flutter/application/reader/reader_source_access_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/ports/book_source_search_port.dart';
import 'package:legado_flutter/domain/source/book_source.dart';

const _book = Book(id: 'book-1', name: '测试书', author: '作 者：甲 著');

BookSource _source(
  String name, {
  int order = 0,
  bool enabled = true,
  bool hasCoverRule = true,
}) => BookSource(
  bookSourceUrl: 'https://$name.test',
  bookSourceName: name,
  enabled: enabled,
  customOrder: order,
  ruleSearchCoverUrl: hasCoverRule ? 'cover' : '',
);

final class _SourceAccess implements ReaderSourceAccessPort {
  _SourceAccess(this.sources);

  final List<BookSource> sources;

  @override
  List<BookSource> get availableSources => sources;

  @override
  Future<Book?> autoChangeSource(
    Book book, {
    required List<BookSource> sources,
    int concurrency = 4,
  }) async => null;

  @override
  BookSource? sourceForBook(Book book) => null;
}

final class _SearchPort implements BookSourceSearchPort {
  final Map<String, List<Completer<List<Map<String, String>>>>> pending = {};
  final List<String> calls = [];
  int active = 0;
  int maxActive = 0;

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async {
    calls.add(source.bookSourceName);
    active++;
    if (active > maxActive) maxActive = active;
    final completer = Completer<List<Map<String, String>>>();
    pending.putIfAbsent(source.bookSourceName, () => []).add(completer);
    try {
      return await completer.future;
    } finally {
      active--;
    }
  }
}

final class _RulePort implements ChangeCoverRulePort {
  _RulePort(this.result);

  String? result;
  int calls = 0;

  @override
  Future<String?> searchCover(Book book) async {
    calls++;
    return result;
  }
}

final class _CachePort implements ChangeCoverCandidateCachePort {
  _CachePort(this.candidates);

  final List<ChangeCoverCandidate> candidates;
  final List<ChangeCoverCandidate> saved = [];

  @override
  Future<List<ChangeCoverCandidate>> load(Book book) async => candidates;

  @override
  Future<void> save(Book book, ChangeCoverCandidate candidate) async {
    saved.add(candidate);
  }
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('作者规范化与原版 AppPattern.authorRegex 一致', () {
    expect(ChangeCoverController.normalizeAuthor('  作 者：甲 著'), '甲');
    expect(ChangeCoverController.normalizeAuthor('作者 甲'), '甲');
    expect(ChangeCoverController.normalizeAuthor('甲'), '甲');
  });

  test('封面规则命中后先进入继续态，再搜索书源', () async {
    final search = _SearchPort();
    final rule = _RulePort('https://cover/rule');
    final controller = ChangeCoverController(
      book: _book,
      sourceAccessPort: _SourceAccess([_source('书源')]),
      sourceSearchPort: search,
      rulePort: rule,
    );

    await controller.initialize();

    expect(controller.state, ChangeCoverSearchState.continueWithSources);
    expect(controller.actionLabel, '继续');
    expect(controller.candidates.map((item) => item.sourceName), [
      '默认封面',
      '封面规则',
    ]);
    expect(search.calls, isEmpty);

    final continued = controller.startOrStop();
    await _flush();
    expect(search.calls, ['书源']);
    search.pending['书源']!.single.complete(const []);
    await continued;
    expect(controller.state, ChangeCoverSearchState.idle);
  });

  test('书源按顺序最多四并发，单源完成立即发布候选', () async {
    final search = _SearchPort();
    final sources = [
      _source('5', order: 5),
      _source('2', order: 2),
      _source('1', order: 1),
      _source('4', order: 4),
      _source('3', order: 3),
      _source('禁用', enabled: false),
      _source('无封面规则', hasCoverRule: false),
    ];
    final controller = ChangeCoverController(
      book: const Book(id: 'book-1', name: '测试书', author: '甲'),
      sourceAccessPort: _SourceAccess(sources),
      sourceSearchPort: search,
    );

    final initialized = controller.initialize();
    await _flush();

    expect(search.calls, ['1', '2', '3', '4']);
    expect(search.maxActive, 4);
    search.pending['2']!.single.complete([
      {'name': '测试书', 'author': '作者：甲 著', 'coverUrl': 'cover-2'},
    ]);
    await _flush();
    expect(controller.candidates.any((item) => item.url == 'cover-2'), isTrue);
    expect(search.calls, ['1', '2', '3', '4', '5']);
    expect(search.maxActive, 4);

    for (final name in ['1', '3', '4', '5']) {
      search.pending[name]!.single.complete(const []);
    }
    await initialized;
    expect(controller.state, ChangeCoverSearchState.idle);
  });

  test('停止后旧一代结果不发布，刷新等旧批次结束后再启动', () async {
    final search = _SearchPort();
    final controller = ChangeCoverController(
      book: const Book(id: 'book-1', name: '测试书', author: '甲'),
      sourceAccessPort: _SourceAccess([_source('书源')]),
      sourceSearchPort: search,
    );

    final first = controller.initialize();
    await _flush();
    await controller.stop();
    final refreshed = controller.start();
    await _flush();
    expect(search.calls, ['书源']);

    search.pending['书源']!.first.complete([
      {'name': '测试书', 'author': '甲', 'coverUrl': 'old-cover'},
    ]);
    await first;
    await _flush();
    expect(search.calls, ['书源', '书源']);
    expect(
      controller.candidates.any((item) => item.url == 'old-cover'),
      isFalse,
    );

    search.pending['书源']![1].complete([
      {'name': '测试书', 'author': '甲', 'coverUrl': 'new-cover'},
    ]);
    await refreshed;
    expect(
      controller.candidates.any((item) => item.url == 'new-cover'),
      isTrue,
    );
    expect(search.maxActive, 1);
  });

  test('缓存只恢复当前启用书源候选并按书源顺序排列', () async {
    final search = _SearchPort();
    final firstEnabled = _source('启用一', order: 3);
    final secondEnabled = _source('启用二', order: 4);
    final disabled = _source('禁用', order: 1, enabled: false);
    final cache = _CachePort([
      ChangeCoverCandidate(
        url: 'disabled-cover',
        sourceName: disabled.bookSourceName,
        sourceOrder: disabled.customOrder,
        sourceUrl: disabled.bookSourceUrl,
      ),
      const ChangeCoverCandidate(
        url: 'deleted-cover',
        sourceName: '已删除',
        sourceOrder: 2,
        sourceUrl: 'https://deleted.test',
      ),
      ChangeCoverCandidate(
        url: 'second-enabled-cover',
        sourceName: secondEnabled.bookSourceName,
        sourceOrder: secondEnabled.customOrder,
        sourceUrl: secondEnabled.bookSourceUrl,
      ),
      ChangeCoverCandidate(
        url: 'first-enabled-cover',
        sourceName: firstEnabled.bookSourceName,
        sourceOrder: firstEnabled.customOrder,
        sourceUrl: firstEnabled.bookSourceUrl,
      ),
    ]);
    final controller = ChangeCoverController(
      book: _book,
      sourceAccessPort: _SourceAccess([disabled, secondEnabled, firstEnabled]),
      sourceSearchPort: search,
      cachePort: cache,
    );

    await controller.initialize();

    expect(controller.candidates.map((candidate) => candidate.url), [
      legadoDefaultCoverMarker,
      'first-enabled-cover',
      'second-enabled-cover',
    ]);
    expect(controller.candidates.map((candidate) => candidate.sourceOrder), [
      -2,
      3,
      4,
    ]);
    expect(search.calls, isEmpty);
  });

  test('两个有效缓存候选按书源顺序恢复且不自动联网', () async {
    final search = _SearchPort();
    final first = _source('第一', order: 1);
    final second = _source('第二', order: 2);
    final cache = _CachePort([
      ChangeCoverCandidate(
        url: 'second-cover',
        sourceName: second.bookSourceName,
        sourceOrder: second.customOrder,
        sourceUrl: second.bookSourceUrl,
      ),
      ChangeCoverCandidate(
        url: 'first-cover',
        sourceName: first.bookSourceName,
        sourceOrder: first.customOrder,
        sourceUrl: first.bookSourceUrl,
      ),
    ]);
    final controller = ChangeCoverController(
      book: _book,
      sourceAccessPort: _SourceAccess([second, first]),
      sourceSearchPort: search,
      cachePort: cache,
    );

    await controller.initialize();

    expect(controller.candidates.map((candidate) => candidate.url), [
      legadoDefaultCoverMarker,
      'first-cover',
      'second-cover',
    ]);
    expect(search.calls, isEmpty);
    expect(controller.state, ChangeCoverSearchState.idle);
  });
}
