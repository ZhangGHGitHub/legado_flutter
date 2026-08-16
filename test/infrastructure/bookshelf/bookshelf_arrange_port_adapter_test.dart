import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_arrange_port.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_arrange_port_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'preserves the established open-info preference key and default',
    () async {
      SharedPreferences.setMockInitialValues({});
      const port = SharedPreferencesBookshelfArrangePortAdapter();

      expect(await port.loadOpenBookInfoByTitle(), isFalse);
      await port.saveOpenBookInfoByTitle(true);
      expect(await port.loadOpenBookInfoByTitle(), isTrue);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          BookshelfArrangePort.openBookInfoByTitleKey,
        ),
        isTrue,
      );
    },
  );
}
