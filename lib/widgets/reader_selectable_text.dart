import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../pages/reader/reader_markup.dart';
import '../services/reader_image_cache.dart';

/// 阅读器正文：对齐 Jingshiro —— 平时不可选中，仅长按进入选区。
///
/// Long-press uses a [Listener]+Timer (not [GestureDetector]) so it does not
/// enter the gesture arena and cannot block parent [ScrollView] drags.
class ReaderSelectableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final InlineSpan? richText;
  final ReaderMarkupDocument? markupDocument;
  final int markupStart;
  final int? markupEnd;
  final ValueChanged<String>? onOpenLink;
  final ReaderImageCache? imageCache;
  final Map<String, Size>? imageSizes;
  final Map<String, String> imageHeaders;
  final TextAlign textAlign;
  final void Function(String selectedText) onWriteNote;

  const ReaderSelectableText({
    super.key,
    required this.text,
    required this.style,
    this.richText,
    this.markupDocument,
    this.markupStart = 0,
    this.markupEnd,
    this.onOpenLink,
    this.imageCache,
    this.imageSizes,
    this.imageHeaders = const {},
    this.textAlign = TextAlign.start,
    required this.onWriteNote,
  });

  @override
  State<ReaderSelectableText> createState() => _ReaderSelectableTextState();
}

class _ReaderSelectableTextState extends State<ReaderSelectableText> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _selectionEnabled = false;
  Timer? _longPressTimer;
  Offset? _downLocal;
  int? _pointer;
  final _linkRecognizers = <GestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(covariant ReaderSelectableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.value = TextEditingValue(
        text: widget.text,
        selection: const TextSelection.collapsed(offset: 0),
      );
      _selectionEnabled = false;
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    _linkRecognizers.clear();
    super.dispose();
  }

  void _disableSelection() {
    if (!_selectionEnabled) return;
    setState(() {
      _selectionEnabled = false;
      _controller.selection = const TextSelection.collapsed(offset: 0);
    });
    _focusNode.unfocus();
  }

  (int, int) _wordRange(String text, int offset) {
    if (text.isEmpty) return (0, 0);
    final o = offset.clamp(0, text.length);
    var start = o;
    var end = o;
    bool isWordChar(int i) {
      final c = text.codeUnitAt(i);
      return c > 0x20 && c != 0x3000;
    }

    while (start > 0 && isWordChar(start - 1)) {
      start--;
    }
    while (end < text.length && isWordChar(end)) {
      end++;
    }
    if (start == end && end < text.length) {
      end++;
    }
    return (start, end);
  }

  int _offsetForLocalPosition(Offset local) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 0;
    final span =
        widget.markupDocument?.spanForRange(
          widget.style,
          start: widget.markupStart,
          end: widget.markupEnd,
          imageCache: widget.imageCache,
          imageSizes: widget.imageSizes,
          imageHeaders: widget.imageHeaders,
        ) ??
        widget.richText ??
        TextSpan(text: widget.text, style: widget.style);
    final painter = TextPainter(
      text: span,
      textAlign: widget.textAlign,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: box.size.width);
    return painter
        .getPositionForOffset(local)
        .offset
        .clamp(0, widget.text.length);
  }

  void _enableSelectionAt(Offset local) {
    final offset = _offsetForLocalPosition(local);
    final range = _wordRange(widget.text, offset);
    setState(() {
      _selectionEnabled = true;
      _controller.value = TextEditingValue(
        text: widget.text,
        selection: TextSelection(baseOffset: range.$1, extentOffset: range.$2),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _downLocal = null;
    _pointer = null;
  }

  void _onPointerDown(PointerDownEvent e) {
    if (_selectionEnabled) return;
    _cancelLongPress();
    _pointer = e.pointer;
    _downLocal = e.localPosition;
    _longPressTimer = Timer(kLongPressTimeout, () {
      if (!mounted || _downLocal == null) return;
      _enableSelectionAt(_downLocal!);
      _cancelLongPress();
    });
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_pointer != e.pointer || _downLocal == null) return;
    if ((e.localPosition - _downLocal!).distance > kTouchSlop) {
      _cancelLongPress();
    }
  }

  void _onPointerUpOrCancel(PointerEvent e) {
    if (_pointer != null && e.pointer != _pointer) return;
    _cancelLongPress();
  }

  String get _selected {
    final sel = _controller.selection;
    if (!sel.isValid || sel.isCollapsed) return '';
    final start = sel.start.clamp(0, _controller.text.length);
    final end = sel.end.clamp(0, _controller.text.length);
    if (start >= end) return '';
    return _controller.text.substring(start, end);
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    _linkRecognizers.clear();
    final richSpan =
        widget.markupDocument?.spanForRange(
          widget.style,
          start: widget.markupStart,
          end: widget.markupEnd,
          onLink: widget.onOpenLink,
          recognizers: _linkRecognizers,
          imageCache: widget.imageCache,
          imageSizes: widget.imageSizes,
          imageHeaders: widget.imageHeaders,
        ) ??
        widget.richText;
    // RichText keeps HTML styling visible; selection still uses plain text.
    if (!_selectionEnabled) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUpOrCancel,
        onPointerCancel: _onPointerUpOrCancel,
        child: richSpan == null
            ? Text(
                widget.text,
                style: widget.style,
                textAlign: widget.textAlign,
              )
            : Text.rich(richSpan, textAlign: widget.textAlign),
      );
    }

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: true,
      showCursor: false,
      enableInteractiveSelection: true,
      keyboardType: TextInputType.none,
      textAlign: widget.textAlign,
      style: widget.style,
      maxLines: null,
      decoration: const InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onTap: () {
        if (_controller.selection.isCollapsed) {
          _disableSelection();
        }
      },
      contextMenuBuilder: (ctx, editableTextState) {
        final selected = _selected;
        final items = <ContextMenuButtonItem>[
          ...editableTextState.contextMenuButtonItems,
          ContextMenuButtonItem(
            label: '写想法',
            onPressed: selected.isEmpty
                ? () {}
                : () {
                    ContextMenuController.removeAny();
                    widget.onWriteNote(selected);
                  },
          ),
        ];
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: items,
        );
      },
    );
  }
}
