/// 导入原版内置 RSS 源的 application 边界。
abstract interface class RssDefaultSourceImportPort {
  Future<bool> importDefaults();
}
