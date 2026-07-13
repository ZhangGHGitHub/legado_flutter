import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/model/read_book.dart';

void main() {
  test('shouldSkipCache rejects empty placeholder and load failures', () {
    expect(ReadBook.shouldSkipCache('（此章节暂无内容）'), isTrue);
    expect(ReadBook.shouldSkipCache('（加载失败: timeout）'), isTrue);
    expect(ReadBook.shouldSkipCache('⚠️ 网络错误'), isTrue);
    expect(ReadBook.shouldSkipCache('真正的章节正文内容'), isFalse);
  });
}
