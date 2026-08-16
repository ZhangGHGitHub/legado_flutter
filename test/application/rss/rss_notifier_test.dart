import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/rss/rss_controller.dart';
import 'package:legado_flutter/application/rss/rss_notifier.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';

void main() {
  test('Riverpod notifier mirrors the shared RSS controller state', () async {
    final controller = RssSourceController();
    final container = ProviderContainer(
      overrides: [rssSourceControllerProvider.overrideWithValue(controller)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(rssNotifierProvider.notifier);
    await notifier.upsertSource(
      const RssSource(sourceUrl: 'https://example.com/rss', sourceName: '测试源'),
    );

    expect(
      container.read(rssNotifierProvider).sources.single.sourceName,
      '测试源',
    );
    expect(notifier.sources.single.sourceUrl, 'https://example.com/rss');
  });
}
