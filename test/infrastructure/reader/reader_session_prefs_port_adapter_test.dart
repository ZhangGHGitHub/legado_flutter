import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/reader/reader_session_prefs_port_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('preserves replacement filtering default and saved value', () async {
    const port = ReaderSessionPrefsPortAdapter();

    expect(await port.loadEnableReplace(), isTrue);
    await port.saveEnableReplace(false);
    expect(await port.loadEnableReplace(), isFalse);
  });
}
