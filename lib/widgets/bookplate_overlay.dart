import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/annotation/bookplate_overlay_port.dart';
import 'package:legado_flutter/domain/book/book.dart';

/// 阅读书票 — 章首/章尾卡片（Phase 4.4）
class BookplateOverlay extends StatefulWidget {
  final Book book;
  final int currentChapterIndex;
  final int totalChapters;
  final Color textColor;
  final bool isHeader;

  /// 测试注入：跳过异步加载
  final BookplateData? previewData;
  final BookplateOverlayPort? port;

  const BookplateOverlay({
    super.key,
    required this.book,
    required this.currentChapterIndex,
    required this.totalChapters,
    required this.textColor,
    this.isHeader = true,
    this.previewData,
    this.port,
  });

  @override
  State<BookplateOverlay> createState() => _BookplateOverlayState();
}

class _BookplateOverlayState extends State<BookplateOverlay> {
  BookplateData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BookplateOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id ||
        oldWidget.currentChapterIndex != widget.currentChapterIndex ||
        oldWidget.totalChapters != widget.totalChapters ||
        oldWidget.previewData != widget.previewData) {
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.previewData != null) {
      setState(() {
        _data = widget.previewData;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    final port =
        widget.port ??
        Provider.of<BookplateOverlayPort?>(context, listen: false) ??
        const UnavailableBookplateOverlayPort();

    if (!mounted) return;
    setState(() {
      _data = port.build(
        book: widget.book,
        currentChapterIndex: widget.currentChapterIndex,
        totalChapters: widget.totalChapters,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _data == null) {
      return const SizedBox.shrink();
    }

    return widget.isHeader ? _buildHeader(_data!) : _buildFooter(_data!);
  }

  Widget _buildHeader(BookplateData data) {
    final muted = widget.textColor.withValues(alpha: 0.55);
    return _ticketShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_activity_outlined, size: 16, color: muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.bookName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(data.author, style: TextStyle(fontSize: 10, color: muted)),
          const SizedBox(height: 6),
          Row(
            children: [
              _StarRating(rating: data.rating, color: widget.textColor),
              const SizedBox(width: 8),
              Text(
                '开始 ${formatBookplateDateLabel(data.startDate)}',
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BookplateData data) {
    final muted = widget.textColor.withValues(alpha: 0.55);
    final progressPct = (data.progress * 100).round();
    return _ticketShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: muted),
              const SizedBox(width: 4),
              Text(
                '阅读 ${data.durationLabel}',
                style: TextStyle(fontSize: 10, color: muted),
              ),
              const SizedBox(width: 10),
              Icon(Icons.menu_book_outlined, size: 14, color: muted),
              const SizedBox(width: 4),
              Text(
                '${data.chaptersRead}/${data.totalChapters} 章',
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '已读 ${data.charsLabel}',
                style: TextStyle(fontSize: 10, color: muted),
              ),
              const SizedBox(width: 10),
              Text(
                '进度 $progressPct%',
                style: TextStyle(fontSize: 10, color: muted),
              ),
              if (data.finishDate != null) ...[
                const SizedBox(width: 10),
                Text(
                  '读完 ${formatBookplateDateLabel(data.finishDate)}',
                  style: TextStyle(fontSize: 10, color: muted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _ticketShell({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: widget.textColor.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  final Color color;

  const _StarRating({required this.rating, required this.color});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor().clamp(0, 5);
    final half = (rating - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icon;
        if (i < full) {
          icon = Icons.star_rounded;
        } else if (i == full && half) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(
          icon,
          size: 13,
          color: color.withValues(
            alpha: i < full || (i == full && half) ? 0.75 : 0.3,
          ),
        );
      }),
    );
  }
}
