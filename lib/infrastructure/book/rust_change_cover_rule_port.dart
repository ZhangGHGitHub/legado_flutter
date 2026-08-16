import 'package:flutter/services.dart';

import '../../application/book/change_cover_controller.dart';
import '../../domain/book/book.dart';
import '../../src/rust/api/cover.dart' as rust_cover;

typedef ChangeCoverRuleExecutor =
    Future<String?> Function({
      required String ruleJson,
      required String name,
      required String author,
    });

final class RustChangeCoverRulePort implements ChangeCoverRulePort {
  RustChangeCoverRulePort({
    Future<String> Function()? loadRuleJson,
    ChangeCoverRuleExecutor executor = rust_cover.searchCoverByRule,
  }) : _loadRuleJson = loadRuleJson ?? _loadDefaultRule,
       _executor = executor;

  final Future<String> Function() _loadRuleJson;
  final ChangeCoverRuleExecutor _executor;

  static Future<String> _loadDefaultRule() =>
      rootBundle.loadString('assets/default_data/coverRule.json');

  @override
  Future<String?> searchCover(Book book) async {
    return _executor(
      ruleJson: await _loadRuleJson(),
      name: book.name,
      author: ChangeCoverController.normalizeAuthor(book.author),
    );
  }
}
