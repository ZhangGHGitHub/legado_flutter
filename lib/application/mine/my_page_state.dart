import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_page_state.freezed.dart';

/// Web 服务状态加载阶段。
enum MyPageWebServiceLoadState { initial, loading, ready, failure }

/// 本地备份最近一次操作的状态。
enum MyPageBackupState { idle, running, success, failure }

/// “我的”页面的不可变状态快照。
@freezed
class MyPageState with _$MyPageState {
  const MyPageState._();

  const factory MyPageState({
    @Default(MyPageWebServiceLoadState.initial)
    MyPageWebServiceLoadState webServiceLoadState,
    @Default(false) bool webServiceOn,
    @Default('') String webServiceUrl,
    String? webServiceError,
    @Default(MyPageBackupState.idle) MyPageBackupState backupState,
    String? backupFileName,
    String? backupError,
  }) = _MyPageState;

  bool get isWebServiceLoading =>
      webServiceLoadState == MyPageWebServiceLoadState.loading;

  bool get hasWebServiceError =>
      webServiceLoadState == MyPageWebServiceLoadState.failure;

  bool get localBackupBusy => backupState == MyPageBackupState.running;
}
