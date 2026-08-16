import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_api.dart';
import 'mock_core_api.dart';

/// Injectable CoreApi state for the incremental Riverpod migration.
///
/// The default keeps the application Rust-free until the composition root
/// explicitly replaces it with [RealCoreApi]. Existing Provider consumers are
/// intentionally left untouched while new code can depend on this provider.
final coreApiNotifierProvider = NotifierProvider<CoreApiNotifier, CoreApi>(
  CoreApiNotifier.new,
);

/// Stable dependency entry point for consumers and ProviderScope overrides.
final coreApiProvider = Provider<CoreApi>(
  (ref) => ref.watch(coreApiNotifierProvider),
);

class CoreApiNotifier extends Notifier<CoreApi> {
  @override
  CoreApi build() => MockCoreApi();

  /// Replaces the current implementation at the composition boundary.
  void replace(CoreApi api) {
    state = api;
  }
}
