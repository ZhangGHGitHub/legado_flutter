import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/app.dart';

void main() {
  testWidgets('App should show bookshelf title', (WidgetTester tester) async {
    await tester.pumpWidget(const LegadoApp());

    // 验证书架标题显示
    expect(find.text('书架'), findsOneWidget);
  });
}
