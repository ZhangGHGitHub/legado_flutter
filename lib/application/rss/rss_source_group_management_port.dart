/// RSS 订阅源分组管理的 application 边界。
///
/// 分组不是独立持久化实体，而是订阅源的 `sourceGroup` 字段集合。
abstract interface class RssSourceGroupManagementPort {
  List<String> allGroups();

  Future<void> addGroup(String group);

  Future<void> renameGroup(String oldGroup, String newGroup);

  Future<void> deleteGroup(String group);
}
