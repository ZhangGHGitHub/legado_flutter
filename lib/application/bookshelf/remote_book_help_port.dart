/// 远程书籍帮助页的首次展示版本能力。
abstract interface class RemoteBookHelpPort {
  /// 返回是否需要首次/版本升级展示，并在判断时记录当前版本。
  Future<bool> shouldAutoShow();
}

/// 独立宿主未提供帮助偏好时不自动弹窗。
final class UnavailableRemoteBookHelpPort implements RemoteBookHelpPort {
  const UnavailableRemoteBookHelpPort();

  @override
  Future<bool> shouldAutoShow() async => false;
}
