import 'package:flutter/material.dart';

import '../../services/tts_service.dart';

/// TTS 朗读面板（对齐 dialog_read_aloud）。
/// 平台引擎未接入时：控件可操作，播放走 [TtsService] stub 并明确提示。
class TtsPanel extends StatefulWidget {
  final String sampleText;
  final VoidCallback onPrevChapter;
  final VoidCallback onNextChapter;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;

  const TtsPanel({
    super.key,
    required this.sampleText,
    required this.onPrevChapter,
    required this.onNextChapter,
    required this.onPrevPage,
    required this.onNextPage,
  });

  static Future<void> show(
    BuildContext context, {
    required String sampleText,
    required VoidCallback onPrevChapter,
    required VoidCallback onNextChapter,
    required VoidCallback onPrevPage,
    required VoidCallback onNextPage,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TtsPanel(
        sampleText: sampleText,
        onPrevChapter: onPrevChapter,
        onNextChapter: onNextChapter,
        onPrevPage: onPrevPage,
        onNextPage: onNextPage,
      ),
    );
  }

  @override
  State<TtsPanel> createState() => _TtsPanelState();
}

class _TtsPanelState extends State<TtsPanel> {
  final _tts = TtsService.instance;

  @override
  void initState() {
    super.initState();
    _tts.addListener(_onTts);
  }

  @override
  void dispose() {
    _tts.removeListener(_onTts);
    super.dispose();
  }

  void _onTts() {
    if (mounted) setState(() {});
  }

  Future<void> _togglePlay() async {
    final wasIdle = _tts.state == TtsPlaybackState.idle;
    await _tts.togglePlay(widget.sampleText);
    if (!mounted) return;
    if (wasIdle &&
        _tts.capability == TtsCapability.stub &&
        _tts.state == TtsPlaybackState.playing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'TTS 服务骨架已就绪，尚未接入系统语音引擎（需 flutter_tts 等插件）',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playing = _tts.state == TtsPlaybackState.playing;
    final paused = _tts.state == TtsPlaybackState.paused;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Text(
                    '朗读 (TTS)',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _tts.capability == TtsCapability.stub
                    ? '引擎未接入 · 当前为服务骨架（可调语速/音调/引擎）'
                    : '正在使用 ${_tts.engineLabel}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            // 运输控件：上章 / 上页 / 播放 / 下页 / 下章
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: '上一章',
                  onPressed: widget.onPrevChapter,
                  icon: const Icon(Icons.skip_previous),
                ),
                IconButton(
                  tooltip: '上一页',
                  onPressed: widget.onPrevPage,
                  icon: const Icon(Icons.fast_rewind),
                ),
                FilledButton.tonal(
                  onPressed: _togglePlay,
                  child: Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                    size: 32,
                  ),
                ),
                IconButton(
                  tooltip: '下一页',
                  onPressed: widget.onNextPage,
                  icon: const Icon(Icons.fast_forward),
                ),
                IconButton(
                  tooltip: '下一章',
                  onPressed: widget.onNextChapter,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
            if (playing || paused)
              TextButton.icon(
                onPressed: () => _tts.stop(),
                icon: const Icon(Icons.stop, size: 18),
                label: const Text('停止'),
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('语速', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Slider(
                      value: _tts.speechRate,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: _tts.speechRate.toStringAsFixed(1),
                      onChanged: _tts.setSpeechRate,
                    ),
                  ),
                  Text(
                    _tts.speechRate.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('音调', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Slider(
                      value: _tts.pitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: _tts.pitch.toStringAsFixed(1),
                      onChanged: _tts.setPitch,
                    ),
                  ),
                  Text(
                    _tts.pitch.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              dense: true,
              title: const Text('TTS 引擎', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                _tts.engineLabel,
                style: const TextStyle(fontSize: 11),
              ),
              trailing: DropdownButton<String>(
                value: _tts.engineId,
                underline: const SizedBox.shrink(),
                items: TtsService.engines
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.label, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id != null) _tts.setEngineId(id);
                },
              ),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text('后台播放', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                '需平台音频服务，当前仅保存偏好',
                style: TextStyle(fontSize: 11),
              ),
              value: _tts.backgroundPlay,
              onChanged: _tts.setBackgroundPlay,
            ),
            ListTile(
              dense: true,
              title: const Text('定时停止', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                _tts.timerMinutes == null
                    ? '未设置'
                    : '${_tts.timerMinutes} 分钟后停止（待引擎）',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: DropdownButton<int?>(
                value: _tts.timerMinutes,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('关闭')),
                  DropdownMenuItem(value: 15, child: Text('15 分钟')),
                  DropdownMenuItem(value: 30, child: Text('30 分钟')),
                  DropdownMenuItem(value: 60, child: Text('60 分钟')),
                ],
                onChanged: _tts.setTimerMinutes,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
