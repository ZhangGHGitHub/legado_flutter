import '../../application/source_subscription/rule_sub_import_port.dart';
import '../../domain/ports/public_text_fetch_port.dart';
import '../../domain/source_subscription/rule_sub.dart';
import '../../providers/replace_provider.dart';
import '../../providers/rss_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/book_source_service.dart';
import '../../services/rule_sub_import_service.dart';

/// 委托既有规则订阅服务的基础设施适配器。
final class RuleSubImportPortAdapter implements RuleSubImportPort {
  const RuleSubImportPortAdapter({
    required BookSourceService sourceService,
    required SourceProvider sourceProvider,
    required RssProvider rssProvider,
    required ReplaceProvider replaceProvider,
    required PublicTextFetchPort fetchPort,
  }) : _sourceService = sourceService,
       _sourceProvider = sourceProvider,
       _rssProvider = rssProvider,
       _replaceProvider = replaceProvider,
       _fetchPort = fetchPort;

  final BookSourceService _sourceService;
  final SourceProvider _sourceProvider;
  final RssProvider _rssProvider;
  final ReplaceProvider _replaceProvider;
  final PublicTextFetchPort _fetchPort;

  @override
  Future<RuleSubImportResult> fetchForImport(RuleSub sub) async {
    final fetched = await RuleSubImportService.fetchForImport(
      sub,
      sourceService: _sourceService,
      fetchPort: _fetchPort,
    );
    return switch (fetched.kind) {
      RuleSubFetchKind.bookSource => RuleSubImportResult.bookSources(
        fetched.bookSources,
      ),
      RuleSubFetchKind.rssSource => RuleSubImportResult.rssSources(
        fetched.rssSources,
      ),
      RuleSubFetchKind.replaceRule => RuleSubImportResult.replaceRules(
        fetched.replaceRules,
      ),
    };
  }

  @override
  Future<List<RuleSub>> checkAutoUpdates() =>
      RuleSubImportService.checkAutoUpdates(
        sourceService: _sourceService,
        sourceProvider: _sourceProvider,
        rssProvider: _rssProvider,
        replaceProvider: _replaceProvider,
        fetchPort: _fetchPort,
      );
}
