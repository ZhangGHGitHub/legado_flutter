import 'package:flutter/material.dart';

/// 阅读器正文：对齐 Jingshiro —— 平时不可选中，仅长按进入选区。
class ReaderSelectableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final void Function(String selectedText) onWriteNote;

  const ReaderSelectableText({
    super.key,
    required this.text,
    required this.style,
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
    _controller.dispose();
    _focusNode.dispose();
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
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textAlign: widget.textAlign,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: box.size.width);
    return painter
        .getPositionForOffset(local)
        .offset
        .clamp(0, widget.text.length);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    final offset = _offsetForLocalPosition(details.localPosition);
    final range = _wordRange(widget.text, offset);
    setState(() {
      _selectionEnabled = true;
      _controller.value = TextEditingValue(
        text: widget.text,
        selection: TextSelection(
          baseOffset: range.$1,
          extentOffset: range.$2,
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
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
    // Plain Text while reading: scroll/drag never selects (Jingshiro parity).
    if (!_selectionEnabled) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPressStart: _onLongPressStart,
        child: Text(
          widget.text,
          style: widget.style,
          textAlign: widget.textAlign,
        ),
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
