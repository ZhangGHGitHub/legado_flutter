import '../../application/rss/rss_controller.dart';
import '../../application/rss/rss_source_group_management_port.dart';

/// 将现有 RSS controller 的 sourceGroup 写入能力暴露给页面端口。
final class RssSourceGroupManagementPortAdapter
    implements RssSourceGroupManagementPort {
  const RssSourceGroupManagementPortAdapter(this._controller);

  final RssSourceController _controller;

  @override
  List<String> allGroups() => _controller.allGroups();

  @override
  Future<void> addGroup(String group) => _controller.addGroup(group);

  @override
  Future<void> renameGroup(String oldGroup, String newGroup) =>
      _controller.renameGroup(oldGroup, newGroup);

  @override
  Future<void> deleteGroup(String group) => _controller.deleteGroup(group);
}
