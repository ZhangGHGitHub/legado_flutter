import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../reader_settings.dart';
import 'page_direction.dart';
import 'page_snapshot_cache.dart';
import 'page_turn_controller.dart';
import 'painters/cover_page_painter.dart';
import 'painters/simulation_curl_painter.dart';
import 'painters/slide_page_painter.dart';

/// Horizontal page-turn host: live page + snapshot CustomPaint overlay.
class ReaderTurnView extends StatefulWidget {
  const ReaderTurnView({
    super.key,
    required this.mode,
    required this.pageIndex,
    required this.pageCount,
    required this.buildPage,
    required this.onPageChanged,
    required this.onTurnChapterPrev,
    required this.onTurnChapterNext,
    required this.hasChapterPrev,
    required this.hasChapterNext,
    this.overlay,
    this.backPageColor = const Color(0xFFECECEC),
  });

  final PageAnimMode mode;
  final int pageIndex;
  final int pageCount;
  final Widget Function(int index) buildPage;
  final void Function(int index) onPageChanged;
  final VoidCallback onTurnChapterPrev;
  final VoidCallback onTurnChapterNext;
  final bool hasChapterPrev;
  final bool hasChapterNext;
  /// Drawn above the live page but under the turn overlay (e.g. click zones).
  final Widget? overlay;
  /// Simulation back-of-page fill (Jingshiro bgMeanColor).
  final Color backPageColor;

  @override
  State<ReaderTurnView> createState() => ReaderTurnViewState();
}

class ReaderTurnViewState extends State<ReaderTurnView>
    with TickerProviderStateMixin {
  final PageTurnController _controller = PageTurnController();
  final PageSnapshotCache _cache = PageSnapshotCache();
  final GlobalKey _prevBoundaryKey = GlobalKey();
  final GlobalKey _curBoundaryKey = GlobalKey();
  final GlobalKey _nextBoundaryKey = GlobalKey();

  bool _overlayVisible = false;
  int _warmGeneration = 0;

  /// Gesture may cross chapter; bitmap exists only for in-chapter neighbors.
  bool get _gestureHasPrev =>
      widget.pageIndex > 0 || widget.hasChapterPrev;
  bool get _gestureHasNext =>
      widget.pageIndex < widget.pageCount - 1 || widget.hasChapterNext;

  bool get _captureHasPrev => widget.pageIndex > 0;
  bool get _captureHasNext => widget.pageIndex < widget.pageCount - 1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleWarmSnapshots());
  }

  @override
  void didUpdateWidget(covariant ReaderTurnView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex ||
        oldWidget.pageCount != widget.pageCount ||
        oldWidget.mode != widget.mode ||
        oldWidget.backPageColor != widget.backPageColor) {
      _scheduleWarmSnapshots();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerTick);
    _controller.dispose();
    _cache.invalidate();
    super.dispose();
  }

  void _onControllerTick() {
    if (mounted) setState(() {});
  }

  void _scheduleWarmSnapshots() {
    if (widget.mode == PageAnimMode.none || widget.mode == PageAnimMode.scroll) {
      return;
    }
    if (widget.pageCount <= 0) return;
    final gen = ++_warmGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || gen != _warmGeneration) return;
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted || gen != _warmGeneration) return;
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final ok = await _cache.refresh(
        prevKey: _prevBoundaryKey,
        curKey: _curBoundaryKey,
        nextKey: _nextBoundaryKey,
        pixelRatio: dpr,
        hasPrev: _captureHasPrev,
        hasNext: _captureHasNext,
      );
      if (mounted && ok && gen == _warmGeneration) {
        setState(() {});
      }
    });
  }

  Future<bool> _ensureCacheReady() async {
    if (_cache.hasCur) return true;
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return false;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return _cache.refresh(
      prevKey: _prevBoundaryKey,
      curKey: _curBoundaryKey,
      nextKey: _nextBoundaryKey,
      pixelRatio: dpr,
      hasPrev: _captureHasPrev,
      hasNext: _captureHasNext,
    );
  }

  /// Programmatic turn used by tap zones / volume keys / auto-read.
  Future<void> turnByAnim(PageTurnDirection dir) async {
    if (dir == PageTurnDirection.none) return;
    final size = context.size;
    if (size == null || size.isEmpty) return;

    if (widget.mode == PageAnimMode.none) {
      _applyCompleted(dir);
      return;
    }

    // Chapter edge without neighbor bitmap → instant fill (no empty overlay).
    if (dir == PageTurnDirection.prev && !_captureHasPrev) {
      _applyCompleted(dir);
      return;
    }
    if (dir == PageTurnDirection.next && !_captureHasNext) {
      _applyCompleted(dir);
      return;
    }

    final ready = await _ensureCacheReady();
    if (!mounted) return;
    if (!ready || !_cache.hasCur) {
      _applyCompleted(dir);
      return;
    }

    setState(() => _overlayVisible = true);

    await _controller.turnByAnim(
      dir,
      vsync: this,
      viewWidth: size.width,
      viewHeight: size.height,
      hasPrev: _gestureHasPrev,
      hasNext: _gestureHasNext,
      onCompleted: _applyCompleted,
    );
    if (mounted) {
      setState(() => _overlayVisible = false);
      _scheduleWarmSnapshots();
    }
  }

  void _applyCompleted(PageTurnDirection dir) {
    if (dir == PageTurnDirection.prev) {
      if (widget.pageIndex > 0) {
        widget.onPageChanged(widget.pageIndex - 1);
      } else if (widget.hasChapterPrev) {
        widget.onTurnChapterPrev();
      }
    } else if (dir == PageTurnDirection.next) {
      if (widget.pageIndex < widget.pageCount - 1) {
        widget.onPageChanged(widget.pageIndex + 1);
      } else if (widget.hasChapterNext) {
        widget.onTurnChapterNext();
      }
    }
  }

  void _onPointerDown(PointerDownEvent e) {
    final size = context.size;
    _controller.onPointerDown(
      e.localPosition,
      viewWidth: size?.width,
      viewHeight: size?.height,
    );
  }

  void _onPointerMove(PointerMoveEvent e) {
    final size = context.size;
    if (size == null) return;
    final slop =
        MediaQuery.maybeGestureSettingsOf(context)?.touchSlop ?? kTouchSlop;

    final wasNone = _controller.direction == PageTurnDirection.none;
    final locked = _controller.onPointerMove(
      e.localPosition,
      hasPrev: _gestureHasPrev,
      hasNext: _gestureHasNext,
      slop: slop,
      viewWidth: size.width,
      viewHeight: size.height,
    );

    // Jingshiro: bitmaps already ready at setDirection — never capture here.
    if (locked &&
        wasNone &&
        _controller.direction != PageTurnDirection.none &&
        widget.mode != PageAnimMode.none) {
      final dir = _controller.direction;
      final canAnimate = _cache.hasCur &&
          (dir != PageTurnDirection.prev ||
              _captureHasPrev ||
              widget.hasChapterPrev) &&
          (dir != PageTurnDirection.next ||
              _captureHasNext ||
              widget.hasChapterNext);

      // Neighbor page bitmap required for in-chapter anim; chapter edge → instant.
      final needsPrevBmp =
          dir == PageTurnDirection.prev && _captureHasPrev;
      final needsNextBmp =
          dir == PageTurnDirection.next && _captureHasNext;
      final bmpOk = _cache.hasCur &&
          (!needsPrevBmp || _cache.display?.prev != null) &&
          (!needsNextBmp || _cache.display?.next != null);

      if (canAnimate && bmpOk) {
        setState(() => _overlayVisible = true);
      } else if (dir == PageTurnDirection.prev && !_captureHasPrev) {
        // Chapter prev: no overlay, complete on up.
      } else if (dir == PageTurnDirection.next && !_captureHasNext) {
        // Chapter next: no overlay, complete on up.
      } else if (!_cache.hasCur) {
        // Missing cache — treat as none on up.
      }
    }

    // Jingshiro SimulationPageDelegate.onTouch MOVE mid-band Y pin.
    if (widget.mode == PageAnimMode.simulation &&
        _controller.direction != PageTurnDirection.none) {
      final h = size.height;
      final startY = _controller.startY;
      final dir = _controller.direction;
      if ((startY > h / 3 && startY < h * 2 / 3) ||
          dir == PageTurnDirection.prev) {
        _controller.touchY = h;
      }
      if (startY > h / 3 &&
          startY < h / 2 &&
          dir == PageTurnDirection.next) {
        _controller.touchY = 1;
      }
    }
  }

  Future<void> _onPointerUp(PointerUpEvent e) async {
    await _finishGesture();
  }

  Future<void> _onPointerCancel(PointerCancelEvent e) async {
    _controller.isCancel = true;
    await _finishGesture();
  }

  Future<void> _finishGesture() async {
    final size = context.size;
    if (size == null) return;

    final dir = _controller.direction;
    final cancel = _controller.isCancel;

    if (widget.mode == PageAnimMode.none) {
      if (dir != PageTurnDirection.none && !cancel) {
        _applyCompleted(dir);
      }
      _controller.resetGesture();
      return;
    }

    // No overlay (cache miss or chapter edge): instant fill when not cancelled.
    if (!_overlayVisible && dir != PageTurnDirection.none) {
      if (!cancel) {
        _applyCompleted(dir);
      }
      _controller.resetGesture();
      _scheduleWarmSnapshots();
      return;
    }

    if (dir == PageTurnDirection.none) {
      setState(() => _overlayVisible = false);
      _controller.resetGesture();
      return;
    }

    await _controller.onPointerUp(
      vsync: this,
      viewWidth: size.width,
      viewHeight: size.height,
      onCompleted: _applyCompleted,
    );
    if (mounted) {
      setState(() => _overlayVisible = false);
      _scheduleWarmSnapshots();
    }
  }

  CustomPainter? _buildPainter(Size size) {
    final c = _controller;
    final snap = _cache.display;
    final running = c.isDragging || c.isSettling;
    switch (widget.mode) {
      case PageAnimMode.slide:
        return SlidePagePainter(
          cur: snap?.cur,
          prev: snap?.prev,
          next: snap?.next,
          direction: c.direction,
          touchX: c.touchX,
          startX: c.startX,
          viewSize: size,
          isRunning: running,
        );
      case PageAnimMode.cover:
        return CoverPagePainter(
          cur: snap?.cur,
          prev: snap?.prev,
          next: snap?.next,
          direction: c.direction,
          touchX: c.touchX,
          startX: c.startX,
          viewSize: size,
          isRunning: running,
        );
      case PageAnimMode.simulation:
        return SimulationCurlPainter(
          cur: snap?.cur,
          prev: snap?.prev,
          next: snap?.next,
          direction: c.direction,
          touchX: c.touchX,
          touchY: c.touchY,
          cornerX: c.cornerX,
          cornerY: c.cornerY,
          viewSize: size,
          isRunning: running,
          backPageColor: widget.backPageColor,
        );
      case PageAnimMode.none:
      case PageAnimMode.scroll:
        return null;
    }
  }

  Widget _boundaryPage(GlobalKey key, int? index) {
    if (index == null || index < 0 || index >= widget.pageCount) {
      return const SizedBox.shrink();
    }
    return RepaintBoundary(
      key: key,
      child: SizedBox.expand(child: widget.buildPage(index)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageIndex = widget.pageIndex;
    final prevIndex = pageIndex > 0 ? pageIndex - 1 : null;
    final nextIndex =
        pageIndex < widget.pageCount - 1 ? pageIndex + 1 : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final painter = _overlayVisible ? _buildPainter(size) : null;

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: (e) => _onPointerUp(e),
          onPointerCancel: (e) => _onPointerCancel(e),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Slight opacity so RepaintBoundary.toImage still paints.
              Opacity(
                opacity: 0.01,
                child: IgnorePointer(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _boundaryPage(_prevBoundaryKey, prevIndex),
                      _boundaryPage(_curBoundaryKey, pageIndex),
                      _boundaryPage(_nextBoundaryKey, nextIndex),
                    ],
                  ),
                ),
              ),
              if (!_overlayVisible)
                KeyedSubtree(
                  key: ValueKey('live-$pageIndex'),
                  child: widget.buildPage(pageIndex),
                )
              else
                const ColoredBox(color: Colors.transparent),
              if (widget.overlay != null) widget.overlay!,
              if (painter != null)
                CustomPaint(
                  size: size,
                  painter: painter,
                  child: const SizedBox.expand(),
                ),
            ],
          ),
        );
      },
    );
  }
}
