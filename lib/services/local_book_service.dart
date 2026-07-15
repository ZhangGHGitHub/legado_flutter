import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:charset_converter/charset_converter.dart';
import '../bridge/legado_engine_bridge.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../database/database_helper.dart';
import 'txt_toc_rule_prefs.dart';

/// 本地书籍导入服务 - 支持 TXT/EPUB（Rust 分章/解析）
class LocalBookService {
  final DatabaseHelper _db = DatabaseHelper();

  /// 弹出文件选择器，导入本地书籍
  Future<Book?> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'epub'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final filePath = file.path;
      if (filePath == null) return null;

      final ext = p.extension(filePath).toLowerCase();
      if (ext == '.txt') {
        return await _importTxt(filePath, file.name);
      } else if (ext == '.epub') {
        return await _importEpub(filePath, file.name);
      }
      return null;
    } catch (e) {
      debugPrint('文件选择失败: $e');
      return null;
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

    await _db.insertBook(book);
    await _saveChapters(bookId, parsed, fallbackTitle: bookName, fallbackContent: text);

    return book;
  }

  Future<Book> _importEpub(String filePath, String fileName) async {
    final bytes = await File(filePath).readAsBytes();
    final bookId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    if (LegadoEngineBridge.isAvailable) {
      try {
        final info = LegadoEngineBridge.parseEpub(bytes);
        final book = Book(
          id: bookId,
          name: info.title.isNotEmpty ? info.title : p.withoutExtension(fileName),
          author: info.author,
          type: 'local',
          sourceUrl: filePath,
        );
        await _db.insertBook(book);
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
          await _db.insertChapters(chapters);
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
    await _db.insertBook(book);
    return book;
  }

  Future<List<({String title, String content})>> _parseTxtChapters(
    String text,
  ) async {
    if (LegadoEngineBridge.isAvailable) {
      try {
        return LegadoEngineBridge.parseTxtChapters(text);
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
      await _db.insertChapters(chapters);
      return;
    }

    await _db.insertChapters([
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
      final end =
          i + 1 < bestMatches.length ? bestMatches[i + 1].start : text.length;
      final content = text.substring(start, end).trim();
      if (content.isEmpty) continue;
      out.add((title: title, content: content));
    }
    return out;
  }
}
