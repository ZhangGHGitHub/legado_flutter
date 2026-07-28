import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legado_flutter/features/rss/rss_tab_page.dart';
import 'package:legado_flutter/providers/rss_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('RssTabPage shows search bar and rule subscription tile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RssProvider()..loadSources()),
        ],
        child: const MaterialApp(home: RssTabPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('规则订阅'), findsOneWidget);
    expect(find.text('RSS 订阅即将推出'), findsNothing);
  });
}
