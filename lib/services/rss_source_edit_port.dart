import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/rss_source.dart';
import '../providers/rss_provider.dart';

/// Persistence boundary used by the RSS source editor.
abstract interface class RssSourceEditPort {
  Future<void> save(RssSource source);
}

/// Production adapter that keeps the editor independent from provider details.
class RssProviderSourceEditAdapter implements RssSourceEditPort {
  RssProviderSourceEditAdapter(this._provider);

  final RssProvider _provider;

  factory RssProviderSourceEditAdapter.fromContext(BuildContext context) {
    return RssProviderSourceEditAdapter(context.read<RssProvider>());
  }

  @override
  Future<void> save(RssSource source) => _provider.upsertSource(source);
}
