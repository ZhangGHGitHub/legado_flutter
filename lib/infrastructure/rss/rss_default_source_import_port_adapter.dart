import 'package:flutter/services.dart';

import '../../application/rss/rss_controller.dart';
import '../../application/rss/rss_default_source_import_port.dart';

/// 从打包资产读取原版默认 RSS 源，并交由 application controller 导入。
final class RssDefaultSourceImportPortAdapter
    implements RssDefaultSourceImportPort {
  RssDefaultSourceImportPortAdapter(
    this._controller, {
    AssetBundle? assetBundle,
  }) : _assetBundle = assetBundle ?? rootBundle;

  static const assetPath = 'assets/default_data/rssSources.json';

  final RssSourceController _controller;
  final AssetBundle _assetBundle;

  @override
  Future<bool> importDefaults() async {
    final jsonText = await _assetBundle.loadString(assetPath);
    return _controller.importDefaultSources(jsonText);
  }
}
