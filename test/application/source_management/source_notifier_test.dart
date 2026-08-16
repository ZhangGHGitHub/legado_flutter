import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_management/source_controller.dart';
import 'package:legado_flutter/application/source_management/source_notifier.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'source_controller_test.dart' as fixtures;

void main() {
  test('SourceNotifier 与共享 Controller 保持同一状态且单次发布只通知一次', () async {
    final controller = SourceController(
      repository: fixtures.createRepositoryForNotifierTest(),
      validationPort: fixtures.createValidationPortForNotifierTest(),
      sourceService: fixtures.createSourceServiceForNotifierTest(),
    );
    final container = ProviderContainer(
      overrides: [sourceControllerProvider.overrideWithValue(controller)],
    );
    addTearDown(container.dispose);

    var notifications = 0;
    final subscription = container.listen(
      sourceNotifierProvider,
      (_, _) => notifications++,
    );
    addTearDown(subscription.close);
    final source = const BookSource(
      bookSourceUrl: 'https://source.example/notifier',
      bookSourceName: 'Notifier 源',
    );

    await controller.addSource(source);

    expect(container.read(sourceNotifierProvider).sources, [source]);
    expect(container.read(sourceNotifierProvider), controller.state);
    expect(notifications, 1);
  });
}
