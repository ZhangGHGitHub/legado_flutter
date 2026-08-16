import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:charset_converter/charset_converter.dart';
import '../domain/repositories/book_repository.dart';
import '../domain/ports/local_book_parser_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'txt_toc_rule_prefs.dart';

/// 本地导入超过大小上限时抛出（消息为可直接展示的中文说明）
class LocalBookImportException implements Exception {
  LocalBookImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 本地书籍导入服务 - 支持 TXT/EPUB（Rust 分章/解析）
class LocalBookService {
  LocalBookService({
    required BookRepository repository,
    required LocalBookParserPort parser,
  }) : _repository = repository,
       _parser = parser;

  final BookRepository _repository;
  final LocalBookParserPort _parser;

  /// 本地导入体积上限（约 50MB），防止超大文件导致 OOM
  static const int maxImportBytes = 50 * 1024 * 1024;

  /// 弹出文件选择器，导入本地书籍
  Future<Book?> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'epub'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final filePath = file.path;
    if (filePath == null) return null;

    await _assertWithinSizeLimit(filePath, pickerSize: file.size);

    return importFromPath(filePath, displayName: file.name);
  }

  /// 从已有本地路径导入（远程书籍下载后复用）
  Future<Book> importFromPath(String filePath, {String? displayName}) async {
    await _assertWithinSizeLimit(filePath);
    final name = displayName ?? p.basename(filePath);
    final ext = p.extension(filePath).toLowerCase();
    if (ext == '.txt') {
      return await _importTxt(filePath, name);
    }
    if (ext == '.epub') {
      return await _importEpub(filePath, name);
    }
    throw LocalBookImportException('仅支持 txt / epub 文件');
  }

  Future<void> _assertWithinSizeLimit(
    String filePath, {
    int? pickerSize,
  }) async {
    var size = pickerSize ?? 0;
    if (size <= 0) {
      size = await File(filePath).length();
    }
    if (size > maxImportBytes) {
      final mb = (size / (1024 * 1024)).toStringAsFixed(1);
      throw LocalBookImportException(
        '文件过大（${mb}MB），本地导入上限为 50MB。'
        '请压缩、拆分后再导入，或改用体积更小的 TXT/EPUB。',
      );
    }
  }

  Future<String> _readTextFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    try {
      var text = utf8.decode(bytes);
      if (text.contains('\uFFFD')) {
        text = await CharsetConverter.decode('GBK', bytes);
      }
      return text;
    } catch (_) {
      try {
        return await CharsetConverter.decode('GBK', bytes);
      } catch (_) {
        return utf8.decode(bytes, allowMalformed: true);
      }
    }
  }

  Future<Book> _importTxt(String filePath, String fileName) async {
    final text = await _readTextFile(filePath);
    final bookName = p.withoutExtension(fileName);
    final bookId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    final parsed = await _parseTxtChapters(text);
    final book = Book(
      id: bookId,
      name: bookName,
      author: '本地导入',
      type: 'local',
      sourceUrl: filePath,
    );

    await _repository.insert(book);
    await _saveChapters(
      bookId,
      parsed,
      fallbackTitle: bookName,
      fallbackContent: text,
    );

    return book;
  }

  Future<Book> _importEpub(String filePath, String fileName) async {
    final bytes = await File(filePath).readAsBytes();
    final bookId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    if (_parser.isAvailable) {
      try {
        final info = _parser.parseEpub(bytes);
        final book = Book(
          id: bookId,
          name: info.title.isNotEmpty
              ? info.title
              : p.withoutExtension(fileName),
          author: info.author,
          type: 'local',
          sourceUrl: filePath,
        );
        await _repository.insert(book);
        final chapters = info.chapters
            .asMap()
            .entries
            .map(
              (e) => Chapter(
                id: '${bookId}_ch_${e.key}',
                bookId: bookId,
                title: e.value.title,
                index: e.key,
                url: '',
                isDownloaded: true,
                content: e.value.content,
              ),
            )
            .toList();
        if (chapters.isNotEmpty) {
          await _repository.insertChapters(chapters);
        }
        return book;
      } catch (e) {
        debugPrint('EPUB Rust 解析失败，回退占位: $e');
      }
    }

    final bookName = p.withoutExtension(fileName);
    final book = Book(
      id: bookId,
      name: bookName,
      author: '本地 EPUB',
      type: 'local',
      sourceUrl: filePath,
    );
    await _repository.insert(book);
    return book;
  }

  Future<List<({String title, String content})>> _parseTxtChapters(
    String text,
  ) async {
    if (_parser.isAvailable) {
      try {
        return _parser
            .parseTxtChapters(text)
            .map((chapter) => (title: chapter.title, content: chapter.content))
            .toList(growable: false);
      } catch (e) {
        debugPrint('TXT Rust 分章失败，回退 Dart: $e');
      }
    }
    await TxtTocRulePrefs.load();
    return _splitChaptersDart(text);
  }

  Future<void> _saveChapters(
    String bookId,
    List<({String title, String content})> parsed, {
    required String fallbackTitle,
    required String fallbackContent,
  }) async {
    if (parsed.isNotEmpty) {
      final chapters = parsed
          .asMap()
          .entries
          .map(
            (e) => Chapter(
              id: '${bookId}_ch_${e.key}',
              bookId: bookId,
              title: e.value.title,
              index: e.key,
              url: '',
              isDownloaded: true,
              content: e.value.content,
            ),
          )
          .toList();
      await _repository.insertChapters(chapters);
      return;
    }

    await _repository.insertChapters([
      Chapter(
        id: '${bookId}_ch_0',
        bookId: bookId,
        title: fallbackTitle,
        index: 0,
        url: '',
        isDownloaded: true,
        content: fallbackContent,
      ),
    ]);
  }

  /// Dart 回退分章：优先使用用户启用的 TXT 目录规则
  List<({String title, String content})> _splitChaptersDart(String text) {
    final patterns = <RegExp>[];
    for (final rule in TxtTocRulePrefs.enabledRules) {
      try {
        patterns.add(RegExp(rule.rule, multiLine: true));
      } catch (e) {
        debugPrint('跳过无效 TOC 规则 ${rule.name}: $e');
      }
    }
    if (patterns.isEmpty) {
      patterns.addAll([
        RegExp(r'第[一二三四五六七八九十百千零0-9]+章\s*[^\n]*'),
        RegExp(r'第[一二三四五六七八九十百千零0-9]+节\s*[^\n]*'),
        RegExp(r'第[一二三四五六七八九十百千零0-9]+回\s*[^\n]*'),
        RegExp(r'Chapter\s+[0-9]+\s*[^\n]*', caseSensitive: false),
        RegExp(r'VOL\.[0-9]+\s*[^\n]*', caseSensitive: false),
      ]);
    }

    RegExp? usedPattern;
    List<RegExpMatch> bestMatches = const [];
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text).toList();
      if (matches.length >= 2 &&
          (usedPattern == null || matches.length > bestMatches.length)) {
        usedPattern = pattern;
        bestMatches = matches;
      }
    }
    // 仅命中 1 次也可用（短篇）；优先多命中规则
    if (usedPattern == null) {
      for (final pattern in patterns) {
        final matches = pattern.allMatches(text).toList();
        if (matches.isNotEmpty) {
          usedPattern = pattern;
          bestMatches = matches;
          break;
        }
      }
    }
    if (usedPattern == null || bestMatches.isEmpty) return [];

    final out = <({String title, String content})>[];
    for (var i = 0; i < bestMatches.length; i++) {
      final title = bestMatches[i].group(0)!.trim();
      final start = bestMatches[i].end;
      final end = i + 1 < bestMatches.length
          ? bestMatches[i + 1].start
          : text.length;
      final content = text.substring(start, end).trim();
      if (content.isEmpty) continue;
      out.add((title: title, content: content));
    }
    return out;
  }
}
