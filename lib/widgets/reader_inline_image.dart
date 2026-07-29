import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/reader_image_cache.dart';
import 'remote_binary_image.dart';

/// Inline reader image with stable layout bounds and a non-network fallback.
class ReaderInlineImage extends StatefulWidget {
  final String source;
  final double width;
  final double height;
  final Map<String, String> headers;
  final VoidCallback? onTap;
  final ImageProvider? imageProvider;
  final ReaderImageCache? imageCache;

  const ReaderInlineImage({
    super.key,
    required this.source,
    required this.width,
    required this.height,
    this.headers = const {},
    this.onTap,
    this.imageProvider,
    this.imageCache,
  });

  static bool isSvgBytes(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true).trimLeft();
    return RegExp(r'<svg(?:\s|>)', caseSensitive: false).hasMatch(text);
  }

  @override
  State<ReaderInlineImage> createState() => _ReaderInlineImageState();
}

class _ReaderInlineImageState extends State<ReaderInlineImage> {
  Uint8List? _bytes;
  bool _loading = false;
  int _loadGeneration = 0;

  bool get _isHttpSource {
    final uri = Uri.tryParse(widget.source);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  void initState() {
    super.initState();
    _startCacheLoad();
  }

  @override
  void didUpdateWidget(covariant ReaderInlineImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.imageCache != widget.imageCache ||
        oldWidget.headers != widget.headers) {
      _startCacheLoad();
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    super.dispose();
  }

  void _startCacheLoad() {
    final cache = widget.imageCache;
    final generation = ++_loadGeneration;
    _bytes = null;
    _loading = cache != null;
    if (cache == null) return;
    cache.loadBytes(widget.source, headers: widget.headers).then((bytes) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    });
  }

  Widget _fallback({required String key}) {
    return SizedBox(
      key: ValueKey(key),
      width: widget.width,
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          border: Border.all(color: Colors.black26),
        ),
      ),
    );
  }

  Widget _loadedImage(Uint8List bytes) {
    if (ReaderInlineImage.isSvgBytes(bytes)) {
      return SvgPicture.memory(
        bytes,
        fit: BoxFit.contain,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) =>
            _fallback(key: 'reader-inline-image-error'),
      );
    }
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) =>
          _fallback(key: 'reader-inline-image-error'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.imageCache != null
        ? (_bytes == null
              ? _fallback(
                  key: _loading
                      ? 'reader-inline-image-loading'
                      : 'reader-inline-image-error',
                )
              : _loadedImage(_bytes!))
        : widget.imageProvider != null
        ? Image(
            image: widget.imageProvider!,
            fit: BoxFit.contain,
            width: widget.width,
            height: widget.height,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) return child;
              return _fallback(key: 'reader-inline-image-loading');
            },
            errorBuilder: (context, error, stackTrace) =>
                _fallback(key: 'reader-inline-image-error'),
          )
        : !_isHttpSource
        ? _fallback(key: 'reader-inline-image-error')
        : RemoteBinaryImage(
            url: widget.source,
            headers: widget.headers,
            fit: BoxFit.contain,
            width: widget.width,
            height: widget.height,
            placeholderBuilder: (_) =>
                _fallback(key: 'reader-inline-image-loading'),
            errorBuilder: (_, _, _) =>
                _fallback(key: 'reader-inline-image-error'),
          );
    final child = SizedBox(
      key: const ValueKey('reader-inline-image-bounds'),
      width: widget.width,
      height: widget.height,
      child: image,
    );
    if (widget.onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: child,
    );
  }
}
