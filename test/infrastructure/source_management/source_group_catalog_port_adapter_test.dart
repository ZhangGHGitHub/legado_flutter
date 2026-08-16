import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/source_management/source_group_catalog_port_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adapts catalog CRUD while preserving trimmed sorted names', () async {
    SharedPreferences.setMockInitialValues({
      'book_source_group_catalog_v1': [' 默认 ', '收藏', '默认', ''],
    });
    const port = SourceGroupCatalogPortAdapter();

    await port.load();

    expect(port.names, containsAllInOrder(['收藏', '默认']));
    expect(await port.add(' 新组 '), isTrue);
    expect(await port.add('新组'), isFalse);
    await port.rename('新组', ' 重命名 ');
    await port.remove('默认');

    expect(port.names, contains('收藏'));
    expect(port.names, contains('重命名'));
    expect(port.names, isNot(contains('默认')));
  });

  test('adapts source-group split, trim, dedupe and tag operations', () {
    const port = SourceGroupCatalogPortAdapter();

    expect(port.splitGroups(' A, B，A,, '), ['A', 'B']);
    expect(port.addGroupTag('A,B', ' A '), 'A,B');
    expect(port.addGroupTag('A', ' B '), 'A,B');
    expect(port.removeGroupTag('A,B,C', ' B '), 'A,C');
    expect(port.renameGroupTag('A,B', ' A ', ' X '), 'X,B');
    expect(port.hasGroupTag('A,B', ' B '), isTrue);
    expect(port.hasGroupTag('A,B', ' C '), isFalse);
  });
}
