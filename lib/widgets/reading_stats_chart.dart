import 'package:flutter/material.dart';

import '../src/rust/api.dart' as rust_api;

/// 近 N 日阅读字数柱状图
class ReadingBarChart extends StatelessWidget {
  final List<rust_api.DailyReadingStat> daily;
  final int maxBars;

  const ReadingBarChart({
    super.key,
    required this.daily,
    this.maxBars = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('暂无阅读数据')),
      );
    }

    final theme = Theme.of(context);
    final bars = daily.length > maxBars
        ? daily.sublist(daily.length - maxBars)
        : daily;
    final maxChars = bars.fold<int>(
      1,
      (m, d) => d.chars > m ? d.chars : m,
    );

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final item in bars) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (item.chars > 0)
                      Text(
                        _shortChars(item.chars),
                        style: theme.textTheme.labelSmall,
                      ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: item.chars / maxChars,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.75,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.date.substring(5),
                      style: theme.textTheme.labelSmall,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _shortChars(int chars) {
    if (chars >= 10000) return '${(chars / 10000).toStringAsFixed(1)}w';
    if (chars >= 1000) return '${(chars / 1000).toStringAsFixed(1)}k';
    return '$chars';
  }
}

/// 日历热力图（近 35 天，7 列）
class ReadingHeatmap extends StatelessWidget {
  final List<rust_api.DailyReadingStat> daily;

  const ReadingHeatmap({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byDate = {for (final d in daily) d.date: d.chars};
    final today = DateTime.now();
    final cells = List.generate(35, (i) {
      final date = today.subtract(Duration(days: 34 - i));
      final key =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      return byDate[key] ?? 0;
    });
    final maxChars = cells.fold<int>(1, (m, c) => c > m ? c : m);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) {
        final chars = cells[index];
        final alpha = chars == 0 ? 0.08 : 0.2 + 0.8 * (chars / maxChars);
        return Tooltip(
          message: chars == 0 ? '无阅读' : '$chars 字',
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: alpha),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      },
    );
  }
}
