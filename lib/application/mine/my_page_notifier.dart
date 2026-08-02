import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'my_page_controller.dart';
import 'my_page_port.dart';
import 'my_page_state.dart';

/// MyPage 局部 ProviderScope 覆盖的共享端口。
final myPagePortProvider = Provider<MyPagePort>(
  (ref) => throw StateError('未提供 MyPagePort'),
);

/// 由 MyPagePort 构造页面范围内唯一的 Controller。
final myPageControllerProvider = Provider<MyPageController>(
  (ref) => MyPageController(port: ref.watch(myPagePortProvider)),
);

/// “我的”页面的 Riverpod 状态入口。
final myPageNotifierProvider = NotifierProvider<MyPageNotifier, MyPageState>(
  MyPageNotifier.new,
);

/// 发布共享 Controller 状态并转发页面命令。
class MyPageNotifier extends Notifier<MyPageState> {
  late MyPageController _controller;

  MyPageController get controller => _controller;
  MyPagePort get port => _controller.port;

  @override
  MyPageState build() {
    _controller = ref.watch(myPageControllerProvider);
    void onStateChanged(MyPageState next) => state = next;

    _controller.addListener(onStateChanged);
    ref.onDispose(() => _controller.removeListener(onStateChanged));
    return _controller.state;
  }

  Future<void> loadWebService() => _controller.loadWebService();

  Future<MyPageWebServiceStatus> toggleWebService() =>
      _controller.toggleWebService();

  Future<String?> backupLocally() => _controller.backupLocally();
}
