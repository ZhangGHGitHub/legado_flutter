import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../page_direction.dart';

/// Edge shadow width aligned with Jingshiro `CoverPageDelegate.setViewSize`.
const double kCoverShadowWidth = 30;

class CoverPagePainter extends CustomPainter {
  CoverPagePainter({
    required this.cur,
    required this.prev,
    required this.next,
    required this.direction,
    required this.touchX,
    required this.startX,
    required this.viewSize,
    required this.isRunning,
  });

  final ui.Image? cur;
  final ui.Image? prev;
  final ui.Image? next;
  final PageTurnDirection direction;
  final double touchX;
  final double startX;
  final Size viewSize;
  final bool isRunning;

  @override
  void paint(Canvas canvas, Size size) {
    if (direction == PageTurnDirection.none) {
      _drawPage(canvas, cur, size);
      return;
    }

    if (!isRunning) {
      _drawPage(canvas, cur, size);
      return;
    }

    final viewWidth = viewSize.width;
    final offsetX = touchX - startX;

    if ((direction == PageTurnDirection.next && offsetX > 0) ||
        (direction == PageTurnDirection.prev && offsetX < 0)) {
      _drawPage(canvas, cur, size);
      return;
    }

    final distanceX = offsetX > 0 ? offsetX - viewWidth : offsetX + viewWidth;

    if (direction == PageTurnDirection.prev) {
      // Base current page under the incoming prev cover (Jingshiro PREV
      // only draws prevRecorder; without a base layer Flutter shows holes).
      _drawPage(canvas, cur, size);
      if (offsetX <= viewWidth) {
        // KT `withTranslation { prevRecorder.draw(canvas) }` uses outer
        // canvas (likely typo); we draw on the translated canvas.
        _drawPageTranslated(canvas, prev, distanceX, size);
        _addShadow(canvas, distanceX, size);
      } else {
        _drawPage(canvas, prev, size);
      }
    } else if (direction == PageTurnDirection.next) {
      final width = viewSize.width;
      final height = viewSize.height;
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(width + offsetX, 0, width, height));
      _drawPage(canvas, next, size);
      canvas.restore();
      _drawPageTranslated(canvas, cur, distanceX - viewWidth, size);
      _addShadow(canvas, distanceX, size);
    }
  }

  @override
  bool shouldRepaint(covariant CoverPagePainter oldDelegate) {
    return oldDelegate.cur != cur ||
        oldDelegate.prev != prev ||
        oldDelegate.next != next ||
        oldDelegate.direction != direction ||
        oldDelegate.touchX != touchX ||
        oldDelegate.startX != startX ||
        oldDelegate.viewSize != viewSize ||
        oldDelegate.isRunning != isRunning;
  }
}

void _drawPage(Canvas canvas, ui.Image? image, Size size) {
  if (image == null) {
    return;
  }
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Offset.zero & size,
    Paint(),
  );
}

void _drawPageTranslated(
  Canvas canvas,
  ui.Image? image,
  double dx,
  Size size,
) {
  if (image == null) {
    return;
  }
  canvas.save();
  canvas.translate(dx, 0);
  _drawPage(canvas, image, size);
  canvas.restore();
}

void _addShadow(Canvas canvas, double left, Size size) {
  if (left == 0) {
    return;
  }
  final dx = left < 0 ? left + size.width : left;
  final shadowRect = Rect.fromLTWH(0, 0, kCoverShadowWidth, size.height);
  canvas.save();
  canvas.translate(dx, 0);
  canvas.drawRect(
    shadowRect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0x66111111), Color(0x00000000)],
      ).createShader(shadowRect),
  );
  canvas.restore();
}
