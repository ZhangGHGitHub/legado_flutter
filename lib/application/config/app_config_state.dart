import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config_state.freezed.dart';

/// 应用配置的加载阶段。
enum AppConfigLoadStatus { initial, loading, loaded, failure }

/// AppConfig 的不可变 Riverpod 状态快照。
///
/// [AppConfig] 仍是唯一配置事实源；此类型只向 application/UI 边界发布
/// 当前快照，不提供可变集合或独立的持久化副本。
@freezed
class AppConfigState with _$AppConfigState {
  const AppConfigState._();

  const factory AppConfigState({
    @Default(true) bool showDiscovery,
    @Default(true) bool showRSS,
    @Default('bookshelf') String defaultHomePage,
    @Default(true) bool syncBookProgress,
    @Default(AppConfigLoadStatus.initial) AppConfigLoadStatus loadStatus,
    Object? loadError,
  }) = _AppConfigState;

  bool get isLoaded => loadStatus == AppConfigLoadStatus.loaded;

  bool get isLoading => loadStatus == AppConfigLoadStatus.loading;

  bool get hasLoadError => loadStatus == AppConfigLoadStatus.failure;
}
