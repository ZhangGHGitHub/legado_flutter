import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_market/source_market_mapper.dart';
import 'package:legado_flutter/domain/source/book_source.dart';

void main() {
  test('groups sources while preserving source and group order', () {
    final first = BookSource(
      bookSourceUrl: 'https://one.example',
      bookSourceName: '第一个',
      bookSourceGroup: '推荐',
    );
    final second = BookSource(
      bookSourceUrl: 'https://two.example',
      bookSourceName: '第二个',
      bookSourceGroup: '收藏',
    );
    final third = BookSource(
      bookSourceUrl: 'https://three.example',
      bookSourceName: '第三个',
      bookSourceGroup: '推荐',
    );

    final market = SourceMarketMapper.fromSources([first, second, third]);

    expect(market.keys.toList(), ['推荐', '收藏', '📥 从社区导入']);
    expect(market['推荐'], [first, third]);
    expect(market['收藏'], [second]);
    expect(market[SourceMarketMapper.communityImportGroup], isEmpty);
  });

  test('always includes the empty community import group', () {
    final market = SourceMarketMapper.fromSources(const []);

    expect(market, {SourceMarketMapper.communityImportGroup: <BookSource>[]});
  });
}
