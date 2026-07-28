import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/features/explore/explore_utils.dart';

void main() {
  BookSource src({
    bool enabled = true,
    bool enabledExplore = true,
    String exploreUrl = '[{"title":"a","url":"/"}]',
  }) {
    return BookSource.fromJson({
      'bookSourceUrl': 'https://x',
      'bookSourceName': 'X',
      'enabled': enabled,
      'enabledExplore': enabledExplore,
      'exploreUrl': exploreUrl,
    });
  }

  test('manage explore_on ignores source.enabled', () {
    final s = src(enabled: false, enabledExplore: true);
    expect(hasExploreUrl(s), true);
    expect(isExploreEnabled(s), true);
    expect(sourceHasExplore(s), false); // tab still requires enabled
  });

  test('explore_off is hasUrl && !enabledExplore', () {
    final s = src(enabledExplore: false);
    expect(hasExploreUrl(s) && !isExploreEnabled(s), true);
  });
}
