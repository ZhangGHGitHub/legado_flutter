import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/reader/turn/page_direction.dart';
import 'package:legado_flutter/pages/reader/turn/page_turn_controller.dart';

void main() {
  group('onPointerMove direction lock', () {
    test('右滑超过 slop 判定为 prev（dx>0 → PREV，Jingshiro HorizontalPageDelegate.onScroll）', () {
      final c = PageTurnController();
      c.onPointerDown(const Offset(100, 200));
      final locked = c.onPointerMove(
        const Offset(120, 200),
        hasPrev: true,
        hasNext: true,
        slop: 10,
      );
      expect(locked, isTrue);
      expect(c.direction, PageTurnDirection.prev);
    });

    test('左滑超过 slop 判定为 next', () {
      final c = PageTurnController();
      c.onPointerDown(const Offset(200, 200));
      final locked = c.onPointerMove(
        const Offset(170, 200),
        hasPrev: true,
        hasNext: true,
        slop: 10,
      );
      expect(locked, isTrue);
      expect(c.direction, PageTurnDirection.next);
    });

    test('右滑但 hasPrev 为 false 时不锁定方向', () {
      final c = PageTurnController();
      c.onPointerDown(const Offset(100, 200));
      final locked = c.onPointerMove(
        const Offset(130, 200),
        hasPrev: false,
        hasNext: true,
        slop: 10,
      );
      expect(locked, isFalse);
      expect(c.direction, PageTurnDirection.none);
    });

    test('NEXT 锁定后右移相对 lastX 则 isCancel 为 true', () {
      final c = PageTurnController();
      c.onPointerDown(const Offset(200, 200));
      c.onPointerMove(
        const Offset(170, 200),
        hasPrev: true,
        hasNext: true,
        slop: 10,
      );
      expect(c.direction, PageTurnDirection.next);
      c.onPointerMove(
        const Offset(175, 200),
        hasPrev: true,
        hasNext: true,
        slop: 10,
      );
      expect(c.isCancel, isTrue);
    });
  });

  group('onPointerUp settle', () {
    testWidgets('完成翻页时 onCompleted 被调用', (tester) async {
      late PageTurnDirection completed;
      final c = PageTurnController();
      late TickerProvider vsync;
      await tester.pumpWidget(
        MaterialApp(
          home: _TickerHost(
            child: Builder(
              builder: (context) {
                vsync = _TickerHostState.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      c.onPointerDown(const Offset(200, 400));
      c.onPointerMove(
        const Offset(150, 400),
        hasPrev: true,
        hasNext: true,
        slop: 10,
      );
      c.onPointerMove(
        const Offset(100, 400),
        hasPrev: true,
        hasNext: true,
        slop: 10,
      );

      final future = c.onPointerUp(
        vsync: vsync,
        viewWidth: 400,
        viewHeight: 800,
        onCompleted: (dir) => completed = dir,
      );
      await tester.pump();
      await tester.pumpAndSettle();
      await future;

      expect(completed, PageTurnDirection.next);
      expect(c.isSettling, isFalse);
      expect(c.isDragging, isFalse);
      expect(c.direction, PageTurnDirection.none);
    });

    testWidgets('取消翻页时不调用 onCompleted', (tester) async {
      var completed = false;
      final c = PageTurnController();
      late TickerProvider vsync;
      await tester.pumpWidget(
        MaterialApp(
          home: _TickerHost(
            child: Builder(
              builder: (context) {
                vsync = _TickerHostState.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      c.onPointerDown(const Offset(200, 400));
      c.onPointerMove(
        const Offset(150, 400),
        hasPrev: true,
        hasNext: true,
        slop: 10,
      );
      c.onPointerMove(
        const Offset(180, 400),
        hasPrev: true,
        hasNext: true,
        slop: 10,
      );
      expect(c.isCancel, isTrue);

      final future = c.onPointerUp(
        vsync: vsync,
        viewWidth: 400,
        viewHeight: 800,
        onCompleted: (_) => completed = true,
      );
      await tester.pump();
      await tester.pumpAndSettle();
      await future;

      expect(completed, isFalse);
    });
  });
}

class _TickerHost extends StatefulWidget {
  const _TickerHost({required this.child});

  final Widget child;

  @override
  State<_TickerHost> createState() => _TickerHostState();
}

class _TickerHostState extends State<_TickerHost>
    with SingleTickerProviderStateMixin {
  static TickerProvider of(BuildContext context) {
    return context.findAncestorStateOfType<_TickerHostState>()!;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
