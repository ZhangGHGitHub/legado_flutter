import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/tts_service.dart';
import '../../widgets/book_cover.dart';

/// 有声 / TTS 播放器 — 对齐 Jingshiro [AudioPlayActivity] + `activity_audio_play.xml`
class AudioPlayPage extends StatefulWidget {
  final Book book;
  final List<Chapter> chapters;
  final int initialChapterIndex;
  final String? initialContent;

  /// 章节切换时回调（同步阅读器进度）
  final ValueChanged<int>? onChapterChanged;

  const AudioPlayPage({
    super.key,
    required this.book,
    required this.chapters,
    this.initialChapterIndex = 0,
    this.initialContent,
    this.onChapterChanged,
  });

  static Future<void> open(
    BuildContext context, {
    required Book book,
    required List<Chapter> chapters,
    int initialChapterIndex = 0,
    String? initialContent,
    ValueChanged<int>? onChapterChanged,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AudioPlayPage(
          book: book,
          chapters: chapters,
          initialChapterIndex: initialChapterIndex,
          initialContent: initialContent,
          onChapterChanged: onChapterChanged,
        ),
      ),
    );
  }

  @override
  State<AudioPlayPage> createState() => _AudioPlayPageState();
}

class _AudioPlayPageState extends State<AudioPlayPage> {
  static const _chromeBg = Color(0xFF1A1A1A);
  static const _chromeFg = Colors.white;
  static const _accentBorder = Color(0xFFFF6D00);

  final _tts = TtsService.instance;
  late int _chapterIndex;
  String _content = '';
  bool _loading = false;
  bool _seeking = false;
  double _seekValue = 0;
  bool _handlingComplete = false;

  @override
  void initState() {
    super.initState();
    _chapterIndex = widget.initialChapterIndex.clamp(
      0,
      max(0, widget.chapters.length - 1),
    );
    _tts.addListener(_onTts);
    _tts.onPlaybackCompleted = _onPlaybackCompleted;
    _tts.ensureInitialized();
    final seed = widget.initialContent;
    if (seed != null && seed.isNotEmpty) {
      _content = seed;
      _tts.bindText(seed);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadChapter());
    }
  }

  @override
  void dispose() {
    if (_tts.onPlaybackCompleted == _onPlaybackCompleted) {
      _tts.onPlaybackCompleted = null;
    }
    _tts.removeListener(_onTts);
    super.dispose();
  }

  void _onTts() {
    if (mounted) setState(() {});
  }

  Chapter? get _chapter {
    if (widget.chapters.isEmpty) return null;
    return widget.chapters[_chapterIndex.clamp(0, widget.chapters.length - 1)];
  }

  String get _subTitle => _chapter?.title ?? '暂无章节';

  int get _progressMax => max(1, _tts.sentenceCount);
  int get _progressValue =>
      _tts.sentenceCount == 0 ? 0 : _tts.sentenceIndex.clamp(0, _progressMax - 1);

  Future<void> _loadChapter({bool autoPlay = false}) async {
    if (widget.chapters.isEmpty) return;
    setState(() => _loading = true);
    try {
      final chapter = widget.chapters[_chapterIndex];
      String content;
      if (_chapterIndex == widget.initialChapterIndex &&
          widget.initialContent != null &&
          widget.initialContent!.isNotEmpty &&
          _content.isEmpty) {
        content = widget.initialContent!;
      } else {
        final source =
            context.read<SourceProvider>().findSourceForBook(widget.book);
        if (source == null) {
          content = '未找到匹配的书源';
        } else {
          content = await context.read<BookProvider>().loadChapterContentCached(
                chapter.url,
                source: source,
                chapterId: chapter.id,
                bookId: widget.book.id,
              );
        }
      }
      if (!mounted) return;
      setState(() {
        _content = content;
        _loading = false;
      });
      _tts.bindText(content);
      widget.onChapterChanged?.call(_chapterIndex);
      if (autoPlay) {
        await _tts.speak(content);
        if (mounted) _maybeWarnCapability();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _content = '加载失败: $e';
        _loading = false;
      });
      _tts.bindText(_content);
    }
  }

  void _maybeWarnCapability() {
    if (_tts.engineId == 'http' && _tts.state == TtsPlaybackState.playing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('HTTP TTS 尚未实现，请改用系统 TTS'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (_tts.capability == TtsCapability.stub &&
        _tts.state == TtsPlaybackState.playing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('系统语音引擎不可用（桌面 stub），界面控件可正常预览'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _togglePlay() async {
    if (_loading) return;
    if (_content.isEmpty) {
      await _loadChapter(autoPlay: true);
      return;
    }
    await _tts.togglePlay(_content);
    if (mounted) _maybeWarnCapability();
  }

  Future<void> _skipTo(int index, {bool autoPlay = true}) async {
    if (index < 0 || index >= widget.chapters.length) return;
    await _tts.stop();
    setState(() {
      _chapterIndex = index;
      _content = '';
    });
    await _loadChapter(autoPlay: autoPlay);
  }

  Future<void> _prevChapter() => _skipTo(_chapterIndex - 1);

  Future<void> _nextChapterManual() async {
    if (_chapterIndex + 1 < widget.chapters.length) {
      await _skipTo(_chapterIndex + 1);
    }
  }

  Future<void> _onPlaybackCompleted() async {
    if (_handlingComplete || !mounted) return;
    _handlingComplete = true;
    try {
      final size = widget.chapters.length;
      if (size == 0) return;
      switch (_tts.playMode) {
        case TtsPlayMode.listEndStop:
          if (_chapterIndex + 1 < size) {
            await _skipTo(_chapterIndex + 1);
          }
        case TtsPlayMode.singleLoop:
          await _tts.speak(_content);
        case TtsPlayMode.random:
          if (size == 1) {
            await _tts.speak(_content);
          } else {
            var next = _chapterIndex;
            while (next == _chapterIndex) {
              next = Random().nextInt(size);
            }
            await _skipTo(next);
          }
        case TtsPlayMode.listLoop:
          await _skipTo((_chapterIndex + 1) % size);
      }
    } finally {
      _handlingComplete = false;
    }
  }

  Future<void> _showTimerSheet() async {
    var minutes = (_tts.timerMinutes ?? 0).clamp(0, 180);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '定时关闭',
                      style: TextStyle(
                        color: _chromeFg,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      minutes == 0 ? '关闭' : '$minutes 分钟',
                      style: const TextStyle(color: _chromeFg, fontSize: 14),
                    ),
                    Slider(
                      value: minutes.toDouble(),
                      min: 0,
                      max: 180,
                      divisions: 36,
                      activeColor: _accentBorder,
                      onChanged: (v) => setLocal(() => minutes = v.round()),
                    ),
                    Row(
                      children: [
                        for (final m in [0, 15, 30, 60, 90])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(m == 0 ? '关闭' : '${m}m'),
                              onPressed: () => setLocal(() => minutes = m),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        _tts.setTimerMinutes(minutes == 0 ? null : minutes);
                        Navigator.pop(ctx);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSpeedSheet() async {
    var speed = _tts.speechRate.clamp(0.5, 3.0);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '语速',
                      style: TextStyle(
                        color: _chromeFg,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${speed.toStringAsFixed(1)}X',
                      style: const TextStyle(color: _chromeFg, fontSize: 14),
                    ),
                    Slider(
                      value: speed,
                      min: 0.5,
                      max: 3.0,
                      divisions: 25,
                      activeColor: _accentBorder,
                      onChanged: (v) {
                        setLocal(() => speed = v);
                        _tts.setSpeechRate(v);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPlaylist() async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (ctx, scroll) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        '目录（${widget.chapters.length}）',
                        style: const TextStyle(
                          color: _chromeFg,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: _chromeFg),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scroll,
                    itemCount: widget.chapters.length,
                    itemBuilder: (_, i) {
                      final ch = widget.chapters[i];
                      final active = i == _chapterIndex;
                      return ListTile(
                        dense: true,
                        selected: active,
                        selectedTileColor: Colors.white12,
                        title: Text(
                          ch.title,
                          style: TextStyle(
                            color: active ? _accentBorder : _chromeFg,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: active
                            ? const Icon(Icons.graphic_eq,
                                color: _accentBorder, size: 18)
                            : null,
                        onTap: () => Navigator.pop(ctx, i),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (chosen != null && chosen != _chapterIndex) {
      await _skipTo(chosen);
    }
  }

  IconData _playModeIcon(TtsPlayMode mode) => switch (mode) {
        TtsPlayMode.listEndStop => Icons.playlist_play,
        TtsPlayMode.singleLoop => Icons.repeat_one,
        TtsPlayMode.random => Icons.shuffle,
        TtsPlayMode.listLoop => Icons.repeat,
      };

  Widget _circleBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    double size = 46,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: _chromeFg.withValues(alpha: onPressed == null ? 0.35 : 1), size: 26),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playing = _tts.state == TtsPlaybackState.playing;
    final timerLeft = _tts.timerRemainingMinutes;
    final showSpeed = (_tts.speechRate - 1.0).abs() > 0.05;
    final progress = _seeking ? _seekValue : _progressValue.toDouble();

    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accentBorder,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _chromeBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: _chromeFg,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 模糊封面底（对齐 iv_bg）
            if (widget.book.coverUrl.isNotEmpty)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Image.network(
                  widget.book.coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(color: _chromeBg),
                ),
              ),
            const ColoredBox(color: Color(0xCC121212)),
            SafeArea(
              child: Column(
                children: [
                  AppBar(
                    title: Text(
                      widget.book.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    actions: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (v) {
                          switch (v) {
                            case 'engine':
                              final next = _tts.engineId == 'system'
                                  ? 'http'
                                  : 'system';
                              _tts.setEngineId(next);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('引擎：${_tts.engineLabel}'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            case 'stop':
                              _tts.stop();
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'engine',
                            child: Text('TTS 引擎：${_tts.engineLabel}'),
                          ),
                          const PopupMenuItem(
                            value: 'stop',
                            child: Text('停止播放'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        // 圆形封面 260dp
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _accentBorder, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: BookCover(
                            coverUrl: widget.book.coverUrl,
                            author: widget.book.author,
                            width: 260,
                            height: 260,
                            radius: 130,
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _subTitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _chromeFg,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tts.capability == TtsCapability.platform
                              ? '${_tts.engineLabel} · 第 ${_tts.sentenceIndex + (_tts.sentenceCount == 0 ? 0 : 1)}/${_tts.sentenceCount} 句'
                              : _tts.engineId == 'http'
                                  ? 'HTTP TTS 待实现'
                                  : 'TTS stub · 第 ${_tts.sentenceIndex + (_tts.sentenceCount == 0 ? 0 : 1)}/${_tts.sentenceCount} 句',
                          style: TextStyle(
                            color: _chromeFg.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${_tts.sentenceCount == 0 ? 0 : _progressValue + 1}',
                                  style: TextStyle(
                                    color: _chromeFg.withValues(alpha: 0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 7,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14,
                                    ),
                                    activeTrackColor: _accentBorder,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: _chromeFg,
                                  ),
                                  child: Slider(
                                    value: progress.clamp(
                                      0,
                                      (_progressMax - 1).toDouble(),
                                    ),
                                    min: 0,
                                    max: (_progressMax - 1).toDouble(),
                                    onChangeStart: (_) {
                                      setState(() {
                                        _seeking = true;
                                        _seekValue = _progressValue.toDouble();
                                      });
                                    },
                                    onChanged: (v) =>
                                        setState(() => _seekValue = v),
                                    onChangeEnd: (v) async {
                                      setState(() => _seeking = false);
                                      await _tts.seekSentence(v.round());
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '$_progressMax',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: _chromeFg.withValues(alpha: 0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Row(
                            children: [
                              if (timerLeft != null && timerLeft > 0)
                                Text(
                                  '${timerLeft}m',
                                  style: const TextStyle(
                                    color: _chromeFg,
                                    fontSize: 12,
                                  ),
                                )
                              else
                                const SizedBox(width: 28),
                              const Spacer(),
                              if (showSpeed)
                                Text(
                                  '${_tts.speechRate.toStringAsFixed(1)}X',
                                  style: const TextStyle(
                                    color: _chromeFg,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // 底栏控件：定时 | 语速 | 上一章 | 播放 | 下一章 | 模式 | 目录
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _circleBtn(
                          icon: Icons.timer_outlined,
                          tooltip: '定时',
                          onPressed: _showTimerSheet,
                        ),
                        _circleBtn(
                          icon: Icons.speed,
                          tooltip: '语速',
                          onPressed: _showSpeedSheet,
                        ),
                        _circleBtn(
                          icon: Icons.skip_previous,
                          tooltip: '上一个',
                          onPressed:
                              _chapterIndex > 0 ? () => _prevChapter() : null,
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            FloatingActionButton(
                              heroTag: 'audio_play_fab',
                              backgroundColor: _chromeFg,
                              foregroundColor: Colors.black,
                              onPressed: _loading ? null : _togglePlay,
                              child: Icon(
                                playing ? Icons.pause : Icons.play_arrow,
                                size: 32,
                              ),
                            ),
                            if (_loading)
                              const SizedBox(
                                width: 56,
                                height: 56,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: _accentBorder,
                                ),
                              ),
                          ],
                        ),
                        _circleBtn(
                          icon: Icons.skip_next,
                          tooltip: '下一个',
                          onPressed: _chapterIndex < widget.chapters.length - 1
                              ? () => _nextChapterManual()
                              : null,
                        ),
                        _circleBtn(
                          icon: _playModeIcon(_tts.playMode),
                          tooltip: _tts.playMode.label,
                          onPressed: () {
                            _tts.cyclePlayMode();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_tts.playMode.label),
                                duration: const Duration(milliseconds: 900),
                              ),
                            );
                          },
                        ),
                        _circleBtn(
                          icon: Icons.list,
                          tooltip: '目录',
                          onPressed: widget.chapters.isEmpty
                              ? null
                              : () => _showPlaylist(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
