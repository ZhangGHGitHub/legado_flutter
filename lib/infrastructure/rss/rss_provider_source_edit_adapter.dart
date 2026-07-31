import '../../application/rss/rss_source_edit_port.dart';
import '../../domain/rss/rss_source.dart';
import '../../providers/rss_provider.dart';

/// 通过 RSS provider 持久化编辑结果的基础设施适配器。
final class RssProviderSourceEditAdapter implements RssSourceEditPort {
  RssProviderSourceEditAdapter(this._provider);

  final RssProvider _provider;

  @override
  Future<void> save(RssSource source) => _provider.upsertSource(source);
}
