import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/widgets/book_cover.dart';

void main() {
  testWidgets('BookCover with infinite width does not throw layout assert', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 180,
            child: BookCover(
              coverUrl: '',
              author: '作者',
              width: double.infinity,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(BookCover), findsOneWidget);
  });
}
