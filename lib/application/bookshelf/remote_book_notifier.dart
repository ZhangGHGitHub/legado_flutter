import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'remote_book_controller.dart';
import 'remote_book_state.dart';
import 'remote_book_sort_port.dart';
import '../../domain/remote/webdav_entry.dart';

/// 远程书籍页面局部覆盖的共享控制器入口。
final remoteBookControllerProvider = Provider<RemoteBookController>(
  (ref) => throw StateError('未提供 RemoteBookController'),
);

/// 远程书籍页面的 Riverpod 状态入口。
final remoteBookNotifierProvider =
    NotifierProvider<RemoteBookNotifier, RemoteBookState>(
      RemoteBookNotifier.new,
    );

/// 只发布共享控制器状态，并转发页面命令。
class RemoteBookNotifier extends Notifier<RemoteBookState> {
  late RemoteBookController _controller;

  RemoteBookController get controller => _controller;

  @override
  RemoteBookState build() {
    _controller = ref.watch(remoteBookControllerProvider);
    void onStateChanged(RemoteBookState next) => state = next;

    _controller.addListener(onStateChanged);
    ref.onDispose(() => _controller.removeListener(onStateChanged));
    return _controller.state;
  }

  Future<void> bootstrap() => _controller.bootstrap();
  Future<void> reload() => _controller.reload();
  Future<void> enterDirectory(WebDavEntry entry) =>
      _controller.enterDirectory(entry);
  bool goBackDirectory() => _controller.goBackDirectory();
  List<WebDavEntry> get visibleEntries => _controller.visibleEntries;
  void setFilter(String filter) => _controller.setFilter(filter);
  void setSearchOpen(bool open) => _controller.setSearchOpen(open);
  void setSort(RemoteBookSortMode mode) => _controller.setSort(mode);
  void toggleSelection(WebDavEntry entry) => _controller.toggleSelection(entry);
  void selectAllVisible(bool all) => _controller.selectAllVisible(all);
  void invertVisibleSelection() => _controller.invertVisibleSelection();
  void clearSelection() => _controller.clearSelection();
  void selectOnly(WebDavEntry entry) => _controller.selectOnly(entry);
  void setImporting(bool importing) => _controller.setImporting(importing);
  void recordImportResult({required int imported, required int failed}) =>
      _controller.recordImportResult(imported: imported, failed: failed);
}
