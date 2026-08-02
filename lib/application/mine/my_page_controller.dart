import 'package:flutter/foundation.dart';

import 'my_page_port.dart';
import 'my_page_state.dart';

typedef MyPageStateListener = void Function(MyPageState state);

/// “我的”页面的 application 控制器。
///
/// Controller 持有唯一状态，Riverpod Notifier 只负责发布状态并转发命令。
/// 这样迁移期间仍可复用现有 MyPagePort，不改变备份或 Web 服务语义。
final class MyPageController {
  MyPageController({required MyPagePort port}) : _port = port;

  final MyPagePort _port;
  final Set<MyPageStateListener> _listeners = {};
  MyPageState _state = const MyPageState();
  int _webServiceRequest = 0;

  MyPagePort get port => _port;
  MyPageState get state => _state;

  void addListener(MyPageStateListener listener) => _listeners.add(listener);

  void removeListener(MyPageStateListener listener) =>
      _listeners.remove(listener);

  Future<void> loadWebService() async {
    final request = ++_webServiceRequest;
    _publish(
      _state.copyWith(
        webServiceLoadState: MyPageWebServiceLoadState.loading,
        webServiceError: null,
      ),
    );
    try {
      final status = await _port.loadWebService();
      if (request != _webServiceRequest) return;
      _publish(_readyState(status));
    } catch (error, stackTrace) {
      if (request != _webServiceRequest) return;
      debugPrint('MyPage Web 服务加载失败: $error');
      debugPrintStack(stackTrace: stackTrace);
      _publish(
        _state.copyWith(
          webServiceLoadState: MyPageWebServiceLoadState.failure,
          webServiceError: '$error',
        ),
      );
    }
  }

  Future<MyPageWebServiceStatus> toggleWebService() async {
    final request = ++_webServiceRequest;
    _publish(
      _state.copyWith(
        webServiceLoadState: MyPageWebServiceLoadState.loading,
        webServiceError: null,
      ),
    );
    try {
      final status = await _port.toggleWebService();
      if (request == _webServiceRequest) _publish(_readyState(status));
      return status;
    } catch (error, stackTrace) {
      if (request == _webServiceRequest) {
        debugPrint('MyPage Web 服务切换失败: $error');
        debugPrintStack(stackTrace: stackTrace);
        _publish(
          _state.copyWith(
            webServiceLoadState: MyPageWebServiceLoadState.failure,
            webServiceError: '$error',
          ),
        );
      }
      rethrow;
    }
  }

  Future<String?> backupLocally() async {
    if (_state.localBackupBusy) return null;
    if (!_port.isEngineAvailable || !_port.isDatabaseReady) {
      throw StateError('Rust 引擎或数据库未就绪');
    }

    _publish(
      _state.copyWith(
        backupState: MyPageBackupState.running,
        backupFileName: null,
        backupError: null,
      ),
    );
    try {
      final fileName = await _port.backupLocally();
      _publish(
        _state.copyWith(
          backupState: MyPageBackupState.success,
          backupFileName: fileName,
        ),
      );
      return fileName;
    } catch (error) {
      _publish(
        _state.copyWith(
          backupState: MyPageBackupState.failure,
          backupError: '$error',
        ),
      );
      rethrow;
    }
  }

  MyPageState _readyState(MyPageWebServiceStatus status) => _state.copyWith(
    webServiceLoadState: MyPageWebServiceLoadState.ready,
    webServiceOn: status.isActive,
    webServiceUrl: status.isActive ? status.baseUrl : '',
    webServiceError: null,
  );

  void _publish(MyPageState next) {
    if (next == _state) return;
    _state = next;
    for (final listener in List<MyPageStateListener>.of(_listeners)) {
      listener(_state);
    }
  }
}
