import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/reader/simulated_reading_prefs_port.dart';

/// 模拟追读（对齐 `dialog_simulated_reading.xml` + `showSimulatedReading`）
class SimulatedReadingDialog {
  SimulatedReadingDialog._();

  static Future<SimulatedReadingConfig?> show(
    BuildContext context, {
    required SimulatedReadingConfig initial,
    required int totalChapters,
    required int durChapterIndex,
  }) async {
    var enabled = initial.enabled;
    var startDate = initial.startDate;
    final startCtrl = TextEditingController(
      text: (initial.enabled ? initial.startChapter : durChapterIndex)
          .toString(),
    );
    final dailyCtrl = TextEditingController(
      text: initial.dailyChapters.toString(),
    );

    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final result = await showDialog<SimulatedReadingConfig>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('模拟追读'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 88,
                          child: Text('开关', style: TextStyle(fontSize: 16)),
                        ),
                        Switch(
                          value: enabled,
                          onChanged: (v) => setLocal(() => enabled = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Text('开始日期', style: TextStyle(fontSize: 16)),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: startDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 3650),
                                ),
                              );
                              if (picked != null) {
                                setLocal(() => startDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(fmt(startDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Text('起始章节', style: TextStyle(fontSize: 16)),
                        ),
                        SizedBox(
                          width: 64,
                          child: TextField(
                            controller: startCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              hintText: '0',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text('日更章数', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: dailyCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              hintText: '3',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (totalChapters > 0) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (_) {
                          final preview = SimulatedReadingConfig(
                            enabled: enabled,
                            startDate: startDate,
                            startChapter:
                                int.tryParse(startCtrl.text.trim()) ?? 0,
                            dailyChapters:
                                int.tryParse(dailyCtrl.text.trim()) ?? 3,
                          );
                          final unlocked = preview.simulatedTotalChapterNum(
                            totalChapters,
                          );
                          return Text(
                            enabled
                                ? '按当前设置今日可读至第 $unlocked / $totalChapters 章'
                                : '关闭后目录显示全部 $totalChapters 章',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(ctx).hintColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    final start = int.tryParse(startCtrl.text.trim()) ?? 0;
                    final daily = int.tryParse(dailyCtrl.text.trim()) ?? 3;
                    Navigator.pop(
                      ctx,
                      SimulatedReadingConfig(
                        enabled: enabled,
                        startDate: startDate,
                        startChapter: start < 0 ? 0 : start,
                        dailyChapters: daily < 1 ? 1 : daily,
                      ),
                    );
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );

    startCtrl.dispose();
    dailyCtrl.dispose();
    return result;
  }
}
