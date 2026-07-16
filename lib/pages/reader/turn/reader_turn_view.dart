import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../reader_settings.dart';
import 'page_direction.dart';
import 'page_snapshot.dart';
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

  @override
  State<ReaderTurnView> createState() => ReaderTurnViewState();
}

class ReaderTurnViewState extends State<ReaderTurnView>
    with TickerProviderStateMixin {
  final PageTurnController _controller = PageTurnController();
  final GlobalKey _prevBoundaryKey = GlobalKey();
  final GlobalKey _curBoundaryKey = GlobalKey();
  final GlobalKey _nextBoundaryKey = GlobalKey();

  ui.Image? _curImage;
  ui.Image? _prevImage;
  ui.Image? _nextImage;
  bool _overlayVisible = false;
  bool _capturing = false;

  bool get _hasPrev =>
      widget.pageIndex > 0 || widget.hasChapterPrev;
  bool get _hasNext =>
      widget.pageIndex < widget.pageCount - 1 || widget.hasChapterNext;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerTick);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerTick);
    _controller.dispose();
    _disposeImages();
    super.dispose();
  }

  void _onControllerTick() {
    if (mounted) setState(() {});
  }

  void _disposeImages() {
    _curImage?.dispose();
    _prevImage?.dispose();
    _nextImage?.dispose();
    _curImage = null;
    _prevImage = null;
    _nextImage = null;
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

    await _ensureSnapshotsFor(dir);
    if (!mounted) return;
    setState(() => _overlayVisible = true);

    await _controller.turnByAnim(
      dir,
      vsync: this,
      viewWidth: size.width,
      viewHeight: size.height,
      hasPrev: _hasPrev,
      hasNext: _hasNext,
      onCompleted: _applyCompleted,
    );
    if (mounted) {
      setState(() {
        _overlayVisible = false;
        _disposeImages();
      });
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

  Future<void> _ensureSnapshotsFor(PageTurnDirection dir) async {
    if (_capturing) return;
    _capturing = true;
    try {
      // Let Offstage boundaries paint one frame.
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return;
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final cur = await captureBoundary(_curBoundaryKey, pixelRatio: dpr);
      ui.Image? prev;
      ui.Image? next;
      if (dir == PageTurnDirection.prev && _hasPrev) {
        prev = await captureBoundary(_prevBoundaryKey, pixelRatio: dpr);
      }
      if (dir == PageTurnDirection.next && _hasNext) {
        next = await captureBoundary(_nextBoundaryKey, pixelRatio: dpr);
      }
      _disposeImages();
      _curImage = cur;
      _prevImage = prev;
      _nextImage = next;
    } finally {
      _capturing = false;
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

  Future<void> _onPointerMove(PointerMoveEvent e) async {
    final size = context.size;
    if (size == null) return;
    final slop =
        MediaQuery.maybeGestureSettingsOf(context)?.touchSlop ?? kTouchSlop;

    final wasNone = _controller.direction == PageTurnDirection.none;
    final locked = _controller.onPointerMove(
      e.localPosition,
      hasPrev: _hasPrev,
      hasNext: _hasNext,
      slop: slop,
      viewWidth: size.width,
      viewHeight: size.height,
    );

    if (locked &&
        wasNone &&
        _controller.direction != PageTurnDirection.none &&
        widget.mode != PageAnimMode.none) {
      await _ensureSnapshotsFor(_controller.direction);
      if (mounted) setState(() => _overlayVisible = true);
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

    if (widget.mode == PageAnimMode.none) {
      final dir = _controller.direction;
      final cancel = _controller.isCancel;
      if (dir != PageTurnDirection.none && !cancel) {
        _applyCompleted(dir);
      }
      _controller.resetGesture();
      return;
    }

    if (_controller.direction == PageTurnDirection.none) {
      setState(() {
        _overlayVisible = false;
        _disposeImages();
      });
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
      setState(() {
        _overlayVisible = false;
        _disposeImages();
      });
    }
  }

  CustomPainter? _buildPainter(Size size) {
    final c = _controller;
    final running = c.isDragging || c.isSettling;
    switch (widget.mode) {
      case PageAnimMode.slide:
        return SlidePagePainter(
          cur: _curImage,
          prev: _prevImage,
          next: _nextImage,
          direction: c.direction,
          touchX: c.touchX,
          startX: c.startX,
          viewSize: size,
          isRunning: running,
        );
      case PageAnimMode.cover:
        return CoverPagePainter(
          cur: _curImage,
          prev: _prevImage,
          next: _nextImage,
          direction: c.direction,
          touchX: c.touchX,
          startX: c.startX,
          viewSize: size,
          isRunning: running,
        );
      case PageAnimMode.simulation:
        return SimulationCurlPainter(
          cur: _curImage,
          prev: _prevImage,
          next: _nextImage,
          direction: c.direction,
          touchX: c.touchX,
          touchY: c.touchY,
          cornerX: c.cornerX,
          cornerY: c.cornerY,
          viewSize: size,
          isRunning: running,
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
          onPointerMove: (e) => _onPointerMove(e),
          onPointerUp: (e) => _onPointerUp(e),
          onPointerCancel: (e) => _onPointerCancel(e),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Snapshot sources (laid out, invisible).
              Opacity(
                opacity: 0,
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
              // Live current page (hidden under overlay while animating).
              if (!_overlayVisible)
                KeyedSubtree(
                  key: ValueKey('live-$pageIndex'),
                  child: widget.buildPage(pageIndex),
                )
              else
                const ColoredBox(color: Colors.transparent),
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
