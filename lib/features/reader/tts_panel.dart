import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/reader/tts_port.dart';

/// TTS 朗读面板（对齐 dialog_read_aloud）。
/// 系统引擎经 [TtsService] 朗读当前页；支持上/下句（桌面 Windows 为 stub）。
class TtsPanel extends StatefulWidget {
  final String sampleText;
  final VoidCallback onPrevChapter;
  final VoidCallback onNextChapter;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final VoidCallback? onOpenAudioPlayer;

  const TtsPanel({
    super.key,
    required this.sampleText,
    required this.onPrevChapter,
    required this.onNextChapter,
    required this.onPrevPage,
    required this.onNextPage,
    this.onOpenAudioPlayer,
  });

  static Future<void> show(
    BuildContext context, {
    required String sampleText,
    required VoidCallback onPrevChapter,
    required VoidCallback onNextChapter,
    required VoidCallback onPrevPage,
    required VoidCallback onNextPage,
    VoidCallback? onOpenAudioPlayer,
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
        onOpenAudioPlayer: onOpenAudioPlayer,
      ),
    );
  }

  @override
  State<TtsPanel> createState() => _TtsPanelState();
}

class _TtsPanelState extends State<TtsPanel> {
  late final TtsPort _tts;

  @override
  void initState() {
    super.initState();
    _tts = context.read<TtsPort>();
    _tts.addListener(_onTts);
    _tts.bindText(widget.sampleText);
    _tts.ensureInitialized();
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
    if (_tts.engineId == 'http' && !_tts.httpTtsConfigured) {
      await _editHttpTts();
      if (!_tts.httpTtsConfigured) return;
    }
    await _tts.togglePlay(widget.sampleText);
    if (!mounted) return;
    if (_tts.capability == TtsCapabilityPort.stub &&
        _tts.state == TtsPlaybackStatePort.playing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('系统语音引擎不可用，请检查 TTS 权限或安装语音包'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _editHttpTts() async {
    final controller = TextEditingController(text: _tts.httpTtsUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('HTTP TTS 地址'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'https://example.com/tts?text={{speakText}}',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url != null && url.isNotEmpty) {
      _tts.configureHttpTts(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playing = _tts.state == TtsPlaybackStatePort.playing;
    final paused = _tts.state == TtsPlaybackStatePort.paused;
    final sentenceHint = _tts.sentenceCount == 0
        ? '无正文'
        : '第 ${_tts.sentenceIndex + 1}/${_tts.sentenceCount} 句';

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
                  if (widget.onOpenAudioPlayer != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onOpenAudioPlayer!();
                      },
                      icon: const Icon(Icons.headphones, size: 18),
                      label: const Text('播放界面'),
                    ),
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
                _tts.capability == TtsCapabilityPort.platform
                    ? '正在使用 ${_tts.engineLabel} · $sentenceHint'
                    : _tts.capability == TtsCapabilityPort.http
                    ? '正在使用 HTTP TTS · $sentenceHint'
                    : _tts.engineId == 'http'
                    ? 'HTTP TTS 未配置 · $sentenceHint'
                    : '引擎初始化中或不可用 · $sentenceHint',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            // 运输控件：上章 / 上句 / 播放 / 下句 / 下章
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: '上一章',
                  onPressed: widget.onPrevChapter,
                  icon: const Icon(Icons.skip_previous),
                ),
                IconButton(
                  tooltip: '上一句',
                  onPressed: () => _tts.previousSentence(),
                  icon: const Icon(Icons.undo),
                ),
                FilledButton.tonal(
                  onPressed: _togglePlay,
                  child: Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                    size: 32,
                  ),
                ),
                IconButton(
                  tooltip: '下一句',
                  onPressed: () => _tts.nextSentence(),
                  icon: const Icon(Icons.redo),
                ),
                IconButton(
                  tooltip: '下一章',
                  onPressed: widget.onNextChapter,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: widget.onPrevPage,
                  icon: const Icon(Icons.fast_rewind, size: 18),
                  label: const Text('上一页'),
                ),
                TextButton.icon(
                  onPressed: widget.onNextPage,
                  icon: const Icon(Icons.fast_forward, size: 18),
                  label: const Text('下一页'),
                ),
                if (playing || paused)
                  TextButton.icon(
                    onPressed: () => _tts.stop(),
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('停止'),
                  ),
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('语速', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Slider(
                      value: _tts.speechRate.clamp(0.5, 3.0),
                      min: 0.5,
                      max: 3.0,
                      divisions: 25,
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_tts.engineId == 'http')
                    IconButton(
                      tooltip: '配置 HTTP TTS',
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      onPressed: _editHttpTts,
                    ),
                  DropdownButton<String>(
                    value: _tts.engineId,
                    underline: const SizedBox.shrink(),
                    items: _tts.engines
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(
                              e.label,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id != null) _tts.setEngineId(id);
                    },
                  ),
                ],
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
                    : '${_tts.timerMinutes} 分钟后停止',
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
