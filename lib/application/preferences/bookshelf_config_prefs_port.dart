/// 配置页读取书架布局偏好的应用层端口。
///
/// 书架配置对话框仍负责在用户确认时保存完整配置；此端口只承载配置页
/// 首屏摘要需要的分组样式，避免 Feature 直接依赖 SharedPreferences 服务。
abstract interface class BookshelfConfigPrefsPort {
  Future<int> loadGroupStyle();
}
