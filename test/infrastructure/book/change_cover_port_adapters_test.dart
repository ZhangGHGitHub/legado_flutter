import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/change_cover_controller.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/book/rust_change_cover_rule_port.dart';
import 'package:legado_flutter/infrastructure/book/shared_preferences_change_cover_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Rust cover rule adapter keeps JSON and normalized book arguments',
    () async {
      String? receivedRule;
      String? receivedName;
      String? receivedAuthor;
      final port = RustChangeCoverRulePort(
        loadRuleJson: () async => '{"enable":true}',
        executor: ({required ruleJson, required name, required author}) async {
          receivedRule = ruleJson;
          receivedName = name;
          receivedAuthor = author;
          return 'https://cover.test/result.jpg';
        },
      );

      final result = await port.searchCover(
        const Book(id: 'book-1', name: '书名', author: '作 者：甲 著'),
      );

      expect(receivedRule, '{"enable":true}');
      expect(receivedName, '书名');
      expect(receivedAuthor, '甲');
      expect(result, 'https://cover.test/result.jpg');
    },
  );

  test('default coverRule asset remains valid original-shaped JSON', () async {
    final raw = await rootBundle.loadString(
      'assets/default_data/coverRule.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;

    expect(json['enable'], isTrue);
    expect(json['searchUrl'], startsWith('data:;base64,'));
    expect(json['coverRule'], contains('java.ajaxAll([url1, url2])'));
  });

  test('candidate cache round-trips source identity and order', () async {
    SharedPreferences.setMockInitialValues({});
    const cache = SharedPreferencesChangeCoverCache();
    const book = Book(id: 'book-1', name: '书名', author: '作者：甲');
    const candidate = ChangeCoverCandidate(
      url: 'https://cover.test/one.jpg',
      sourceName: '书源',
      sourceOrder: 3,
      sourceUrl: 'https://source.test',
    );

    await cache.save(book, candidate);
    final restored = await cache.load(book);

    expect(restored.single.url, candidate.url);
    expect(restored.single.sourceName, candidate.sourceName);
    expect(restored.single.sourceOrder, candidate.sourceOrder);
    expect(restored.single.sourceUrl, candidate.sourceUrl);
  });
}
