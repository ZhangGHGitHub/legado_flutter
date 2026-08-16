import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/book/book_metadata_port.dart';
import '../../application/book/change_cover_controller.dart';
import '../../application/reader/reader_source_access_port.dart';
import '../../domain/book/book.dart';
import '../../domain/ports/book_source_search_port.dart';
import '../../widgets/book_cover.dart';

/// 封面换源页，视图只渲染 application controller 的状态。
class ChangeCoverPage extends StatefulWidget {
  const ChangeCoverPage({
    super.key,
    required this.book,
    this.persistChanges = true,
    this.metadataPort,
    this.sourceAccessPort,
    this.searchPort,
    this.rulePort,
    this.cachePort,
    this.controller,
  });

  final Book book;
  final bool persistChanges;
  final BookMetadataPort? metadataPort;
  final ReaderSourceAccessPort? sourceAccessPort;
  final BookSourceSearchPort? searchPort;
  final ChangeCoverRulePort? rulePort;
  final ChangeCoverCandidateCachePort? cachePort;
  final ChangeCoverController? controller;

  @override
  State<ChangeCoverPage> createState() => _ChangeCoverPageState();
}

class _ChangeCoverPageState extends State<ChangeCoverPage> {
  late final BookMetadataPort _metadataPort;
  late final ChangeCoverController _controller;
  late final bool _ownsController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _metadataPort =
        widget.metadataPort ??
        Provider.of<BookMetadataPort?>(context, listen: false) ??
        const EmptyBookMetadataPort();
    final injectedController = widget.controller;
    _ownsController = injectedController == null;
    _controller =
        injectedController ??
        ChangeCoverController(
          book: widget.book,
          sourceAccessPort:
              widget.sourceAccessPort ??
              Provider.of<ReaderSourceAccessPort?>(context, listen: false) ??
              const EmptyReaderSourceAccessPort(),
          sourceSearchPort:
              widget.searchPort ??
              Provider.of<BookSourceSearchPort?>(context, listen: false) ??
              const EmptyBookSourceSearchPort(),
          rulePort:
              widget.rulePort ??
              Provider.of<ChangeCoverRulePort?>(context, listen: false) ??
              const EmptyChangeCoverRulePort(),
          cachePort:
              widget.cachePort ??
              Provider.of<ChangeCoverCandidateCachePort?>(
                context,
                listen: false,
              ) ??
              const EmptyChangeCoverCandidateCachePort(),
        );
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _ownsController) _controller.initialize();
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _selectCover(ChangeCoverCandidate candidate) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final updated = widget.persistChanges
          ? await _metadataPort.updateCustomCover(widget.book, candidate.url)
          : widget.book.copyWith(customCoverUrl: candidate.url);
      if (mounted) Navigator.pop(context, updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('封面保存失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final searching = _controller.isSearching;
    final actionIcon = switch (_controller.state) {
      ChangeCoverSearchState.searchingCoverRule ||
      ChangeCoverSearchState.searchingSources => Icons.stop,
      ChangeCoverSearchState.continueWithSources => Icons.play_arrow,
      ChangeCoverSearchState.idle => Icons.refresh,
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('封面换源'),
        actions: [
          IconButton(
            tooltip: _controller.actionLabel,
            onPressed: _saving ? null : _controller.startOrStop,
            icon: Icon(actionIcon),
          ),
        ],
        bottom: searching
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.62,
        ),
        itemCount: _controller.candidates.length,
        itemBuilder: (context, index) {
          final candidate = _controller.candidates[index];
          return InkWell(
            key: ValueKey('cover:${candidate.url}'),
            onTap: _saving ? null : () => _selectCover(candidate),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  Expanded(
                    child: BookCover(
                      coverUrl: candidate.url == legadoDefaultCoverMarker
                          ? ''
                          : candidate.url,
                      author: widget.book.author,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    candidate.sourceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
