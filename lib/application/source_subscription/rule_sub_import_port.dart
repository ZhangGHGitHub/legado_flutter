import '../../domain/content/replace_rule.dart';
import '../../domain/rss/rss_source.dart';
import '../../domain/source/book_source.dart';
import '../../domain/source_subscription/rule_sub.dart';

/// 规则订阅拉取与自动更新的应用层边界。
abstract interface class RuleSubImportPort {
  Future<RuleSubImportResult> fetchForImport(RuleSub sub);

  Future<List<RuleSub>> checkAutoUpdates();
}

enum RuleSubImportKind { bookSource, rssSource, replaceRule }

class RuleSubImportResult {
  const RuleSubImportResult._({
    required this.kind,
    this.bookSources = const [],
    this.rssSources = const [],
    this.replaceRules = const [],
  });

  final RuleSubImportKind kind;
  final List<BookSource> bookSources;
  final List<RssSource> rssSources;
  final List<ReplaceRule> replaceRules;

  factory RuleSubImportResult.bookSources(List<BookSource> values) =>
      RuleSubImportResult._(
        kind: RuleSubImportKind.bookSource,
        bookSources: values,
      );

  factory RuleSubImportResult.rssSources(List<RssSource> values) =>
      RuleSubImportResult._(
        kind: RuleSubImportKind.rssSource,
        rssSources: values,
      );

  factory RuleSubImportResult.replaceRules(List<ReplaceRule> values) =>
      RuleSubImportResult._(
        kind: RuleSubImportKind.replaceRule,
        replaceRules: values,
      );

  int get count => switch (kind) {
    RuleSubImportKind.bookSource => bookSources.length,
    RuleSubImportKind.rssSource => rssSources.length,
    RuleSubImportKind.replaceRule => replaceRules.length,
  };

  List<String> get labels => switch (kind) {
    RuleSubImportKind.bookSource =>
      bookSources.map((source) => source.bookSourceName).toList(),
    RuleSubImportKind.rssSource =>
      rssSources.map((source) => source.sourceName).toList(),
    RuleSubImportKind.replaceRule =>
      replaceRules
          .map((rule) => rule.name.isEmpty ? rule.pattern : rule.name)
          .toList(),
  };
}
