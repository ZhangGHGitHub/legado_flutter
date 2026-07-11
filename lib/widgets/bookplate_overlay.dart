import 'package:flutter/material.dart';

/// 阅读书票 overlay 占位 — 对齐 BookplateDrawer
class BookplateOverlay extends StatelessWidget {
  final Color textColor;
  final bool isHeader;

  const BookplateOverlay({
    super.key,
    required this.textColor,
    this.isHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_activity_outlined,
            size: 16,
            color: textColor.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isHeader ? '章首书票（占位）' : '章尾书票（占位）',
              style: TextStyle(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.45),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
