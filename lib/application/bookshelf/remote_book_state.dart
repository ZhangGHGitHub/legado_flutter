import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/remote/webdav_entry.dart';
import 'remote_book_sort_port.dart';
import 'webdav_prefs_port.dart';

part 'remote_book_state.freezed.dart';

enum RemoteBookStatus { initial, loading, success, failure }

/// 远程书籍页面的不可变状态快照。
@freezed
class RemoteBookState with _$RemoteBookState {
  const RemoteBookState._();

  const factory RemoteBookState({
    @Default(RemoteBookStatus.initial) RemoteBookStatus status,
    WebDavConfig? config,
    @Default('') String booksRoot,
    @Default('') String path,
    @Default(<WebDavEntry>[]) List<WebDavEntry> dirStack,
    @Default(<WebDavEntry>[]) List<WebDavEntry> entries,
    @Default(<String>{}) Set<String> selected,
    @Default('') String filter,
    @Default(RemoteBookSortMode.time) RemoteBookSortMode sortMode,
    @Default(false) bool sortAscending,
    @Default(false) bool searchOpen,
    @Default(false) bool isImporting,
    @Default(0) int importedCount,
    @Default(0) int failedCount,
    String? error,
    @Default(false) bool needsConfig,
    @Default(false) bool booksRootEnsured,
  }) = _RemoteBookState;

  factory RemoteBookState.initial() => const RemoteBookState();

  bool get isLoading => status == RemoteBookStatus.loading;

  bool get hasError => status == RemoteBookStatus.failure;

  bool get canGoBack => dirStack.isNotEmpty;
}
