import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/model/read_book.dart';

void main() {
  test('isEmptyContentPlaceholder detects engine empty placeholders', () {
    expect(ReadBook.isEmptyContentPlaceholder('（此章节暂无内容）'), isTrue);
    expect(ReadBook.isEmptyContentPlaceholder('  （此章节暂无内容）  '), isTrue);
    expect(ReadBook.isEmptyContentPlaceholder(''), isTrue);
    expect(ReadBook.isEmptyContentPlaceholder('真正的段落正文内容……'), isFalse);
  });

  test('shouldSkipCache covers failures but keeps normal text', () {
    expect(ReadBook.shouldSkipCache('（加载失败：超时）'), isTrue);
    expect(ReadBook.shouldSkipCache('⚠️ 网络错误'), isTrue);
    expect(ReadBook.shouldSkipCache('真正的段落正文内容……'), isFalse);
  });
}
