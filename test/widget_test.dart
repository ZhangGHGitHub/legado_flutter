import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:legado_flutter/app.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';

void main() {
  // 初始化 FFI 数据库工厂（桌面/测试环境）
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('App should show bookshelf title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BookProvider()),
          ChangeNotifierProvider(create: (_) => SourceProvider()),
        ],
        child: const LegadoApp(),
      ),
    );

    // 等待异步初始化完成
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 验书架架标题显示
    expect(find.text('书架'), findsOneWidget);
  });
}
