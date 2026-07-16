import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'page_direction.dart';
import 'simulation_curl_math.dart';

class PageTurnController extends ChangeNotifier {
  PageTurnDirection direction = PageTurnDirection.none;
  double touchX = 0;
  double touchY = 0;
  double startX = 0;
  double startY = 0;
  bool isDragging = false;
  bool isSettling = false;
  bool isCancel = false;

  bool _isMoved = false;
  double _lastX = 0;
  int _cornerX = 1;
  int _cornerY = 1;
  AnimationController? _settleController;
  VoidCallback? _settleListener;

  void onPointerDown(Offset p) {
    _abortSettle(applyCompletion: false);
    _isMoved = false;
    isDragging = false;
    isSettling = false;
    isCancel = false;
    direction = PageTurnDirection.none;
    startX = p.dx;
    startY = p.dy;
    touchX = p.dx;
    touchY = p.dy;
    _lastX = p.dx;
    notifyListeners();
  }

  bool onPointerMove(
    Offset p, {
    required bool hasPrev,
    required bool hasNext,
    required double slop,
  }) {
    final slopSquare = slop * slop;
    if (!_isMoved) {
      final deltaX = (p.dx - startX).round();
      final deltaY = (p.dy - startY).round();
      final distance = deltaX * deltaX + deltaY * deltaY;
      if (distance <= slopSquare) {
        return false;
      }
      _isMoved = true;
      if (p.dx - startX > 0) {
        if (!hasPrev) {
          return false;
        }
        direction = PageTurnDirection.prev;
      } else {
        if (!hasNext) {
          return false;
        }
        direction = PageTurnDirection.next;
      }
      startX = p.dx;
      startY = p.dy;
    }

    if (_isMoved && direction != PageTurnDirection.none) {
      isCancel = direction == PageTurnDirection.next
          ? p.dx > _lastX
          : p.dx < _lastX;
      isDragging = true;
      touchX = p.dx;
      touchY = p.dy;
      _lastX = p.dx;
      notifyListeners();
      return true;
    }

    if (_isMoved) {
      touchX = p.dx;
      touchY = p.dy;
      _lastX = p.dx;
      notifyListeners();
    }
    return false;
  }

  Future<void> onPointerUp({
    required TickerProvider vsync,
    required double viewWidth,
    required double viewHeight,
    required void Function(PageTurnDirection) onCompleted,
    int animationSpeed = 100,
  }) {
    if (!_isMoved || direction == PageTurnDirection.none) {
      _resetAfterGesture();
      return Future.value();
    }
    return _startSettle(
      vsync: vsync,
      viewWidth: viewWidth,
      viewHeight: viewHeight,
      onCompleted: onCompleted,
      animationSpeed: animationSpeed,
    );
  }

  Future<void> turnByAnim(
    PageTurnDirection dir, {
    required TickerProvider vsync,
    required double viewWidth,
    required double viewHeight,
    required void Function(PageTurnDirection) onCompleted,
    required bool hasPrev,
    required bool hasNext,
    int animationSpeed = 100,
  }) {
    _abortSettle(applyCompletion: false);
    if (dir == PageTurnDirection.next) {
      if (!hasNext) {
        return Future.value();
      }
      direction = PageTurnDirection.next;
      final y = startY > viewHeight / 2 ? viewHeight * 0.9 : 1.0;
      startX = viewWidth * 0.9;
      startY = y;
      touchX = startX;
      touchY = startY;
      isCancel = false;
      _isMoved = true;
    } else if (dir == PageTurnDirection.prev) {
      if (!hasPrev) {
        return Future.value();
      }
      direction = PageTurnDirection.prev;
      startX = 0;
      startY = viewHeight;
      touchX = startX;
      touchY = startY;
      isCancel = false;
      _isMoved = true;
    } else {
      return Future.value();
    }
    isDragging = false;
    notifyListeners();
    return _startSettle(
      vsync: vsync,
      viewWidth: viewWidth,
      viewHeight: viewHeight,
      onCompleted: onCompleted,
      animationSpeed: animationSpeed,
    );
  }

  void _updateCornerForDirection({
    required double viewWidth,
    required double viewHeight,
  }) {
    switch (direction) {
      case PageTurnDirection.prev:
        final corner = startX > viewWidth / 2
            ? calcCornerXY(
                x: startX,
                y: viewHeight,
                viewWidth: viewWidth,
                viewHeight: viewHeight,
              )
            : calcCornerXY(
                x: viewWidth - startX,
                y: viewHeight,
                viewWidth: viewWidth,
                viewHeight: viewHeight,
              );
        _cornerX = corner.cornerX;
        _cornerY = corner.cornerY;
      case PageTurnDirection.next:
        if (viewWidth / 2 > startX) {
          final corner = calcCornerXY(
            x: viewWidth - startX,
            y: startY,
            viewWidth: viewWidth,
            viewHeight: viewHeight,
          );
          _cornerX = corner.cornerX;
          _cornerY = corner.cornerY;
        }
      case PageTurnDirection.none:
        break;
    }
  }

  Offset _settleDelta({
    required double viewWidth,
    required double viewHeight,
  }) {
    late double dx;
    late double dy;
    if (isCancel) {
      if (_cornerX > 0 && direction == PageTurnDirection.next) {
        dx = viewWidth - touchX;
      } else {
        dx = -touchX;
      }
      if (direction != PageTurnDirection.next) {
        dx = -(viewWidth + touchX);
      }
      dy = _cornerY > 0 ? viewHeight - touchY : -touchY;
    } else {
      if (_cornerX > 0 && direction == PageTurnDirection.next) {
        dx = -(viewWidth + touchX);
      } else {
        dx = viewWidth - touchX;
      }
      dy = _cornerY > 0 ? viewHeight - touchY : 1 - touchY;
    }
    return Offset(dx, dy);
  }

  Future<void> _startSettle({
    required TickerProvider vsync,
    required double viewWidth,
    required double viewHeight,
    required void Function(PageTurnDirection) onCompleted,
    required int animationSpeed,
  }) {
    _updateCornerForDirection(
      viewWidth: viewWidth,
      viewHeight: viewHeight,
    );
    final delta = _settleDelta(viewWidth: viewWidth, viewHeight: viewHeight);
    final fromX = touchX;
    final fromY = touchY;
    final completedDirection = direction;
    final cancelled = isCancel;

    final durationMs = delta.dx != 0
        ? (animationSpeed * delta.dx.abs()) ~/ viewWidth
        : (animationSpeed * delta.dy.abs()) ~/ viewHeight;
    final duration = Duration(
      milliseconds: math.max(durationMs, 1),
    );

    isDragging = false;
    isSettling = true;
    notifyListeners();

    final controller = AnimationController(
      vsync: vsync,
      duration: duration,
    );
    _settleController = controller;

    void listener() {
      final t = controller.value;
      touchX = fromX + delta.dx * t;
      touchY = fromY + delta.dy * t;
      notifyListeners();
    }

    _settleListener = listener;
    controller.addListener(listener);

    final completer = Completer<void>();
    controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) {
        return;
      }
      controller.removeListener(listener);
      _settleController = null;
      _settleListener = null;
      if (!cancelled) {
        onCompleted(completedDirection);
      }
      _resetAfterGesture();
      completer.complete();
    });

    controller.forward();
    return completer.future;
  }

  void _abortSettle({required bool applyCompletion}) {
    final controller = _settleController;
    if (controller == null) {
      return;
    }
    final listener = _settleListener;
    if (listener != null) {
      controller.removeListener(listener);
    }
    controller.stop();
    controller.dispose();
    _settleController = null;
    _settleListener = null;
    isSettling = false;
  }

  void _resetAfterGesture() {
    _isMoved = false;
    isDragging = false;
    isSettling = false;
    isCancel = false;
    direction = PageTurnDirection.none;
    notifyListeners();
  }

  @override
  void dispose() {
    _abortSettle(applyCompletion: false);
    super.dispose();
  }
}
