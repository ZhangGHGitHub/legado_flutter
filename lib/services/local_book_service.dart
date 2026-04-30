import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:charset_converter/charset_converter.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../database/database_helper.dart';

/// 本地书籍导入服务 - 支持 TXT/EPUB
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

  /// 导入 TXT 文件
  Future<Book> _importTxt(String filePath, String fileName) async {
    // 1. 读取文件内容（自动检测编码）
    final bytes = await File(filePath).readAsBytes();
    String text;
    try {
      // 先试 UTF-8
      text = utf8.decode(bytes);
      // 检查是否有乱码
      if (text.contains('\uFFFD')) {
        // 有乱码，尝试 GBK
        text = await CharsetConverter.decode('GBK', bytes);
      }
    } catch (_) {
      // UTF-8 失败，尝试 GBK
      try {
        text = await CharsetConverter.decode('GBK', bytes);
      } catch (_) {
        // 最终兜底
        text = utf8.decode(bytes, allowMalformed: true);
      }
    }

    // 2. 提取书名（从文件名或内容开头）
    final bookName = p.withoutExtension(fileName);

    // 3. 按章节分割
    final chapters = _splitChapters(text);
    final bookId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    // 4. 创建书籍
    final book = Book(
      id: bookId,
      name: bookName,
      author: '本地导入',
      type: 'local',
    );

    // 5. 保存到数据库
    await _db.insertBook(book);

    if (chapters.isNotEmpty) {
      await _db.insertChapters(chapters);
    } else {
      // 没有章节标记，整本书作为一章
      await _db.insertChapters([
        Chapter(
          id: '${bookId}_ch_0',
          bookId: bookId,
          title: bookName,
          index: 0,
          url: '',
          isDownloaded: true,
          content: text,
        ),
      ]);
    }

    return book;
  }

  /// 导入 EPUB 文件（简易版 - 提取文本内容）
  Future<Book> _importEpub(String filePath, String fileName) async {
    // EPUB 是 ZIP 压缩包，简易处理：直接读文件名
    final bookName = p.withoutExtension(fileName);
    final bookId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    final book = Book(
      id: bookId,
      name: bookName,
      author: '本地EPUB',
      type: 'local',
    );

    await _db.insertBook(book);
    return book;
  }

  /// 分割章节 - 支持常见章节标题格式
  List<Chapter> _splitChapters(String text) {
    final chapters = <Chapter>[];
    
    // 常见的章节标题正则
    final patterns = [
      RegExp(r'第[一二三四五六七八九十百千零0-9]+章\s*[^\n]*'),
      RegExp(r'第[一二三四五六七八九十百千零0-9]+节\s*[^\n]*'),
      RegExp(r'第[一二三四五六七八九十百千零0-9]+回\s*[^\n]*'),
      RegExp(r'Chapter\s+[0-9]+\s*[^\n]*', caseSensitive: false),
      RegExp(r'VOL\.[0-9]+\s*[^\n]*', caseSensitive: false),
    ];

    // 先用第一个匹配到的模式
    RegExp? usedPattern;
    for (final pattern in patterns) {
      if (pattern.hasMatch(text)) {
        usedPattern = pattern;
        break;
      }
    }

    if (usedPattern == null) return chapters;

    final matches = usedPattern.allMatches(text).toList();
    if (matches.isEmpty) return chapters;

    // 生成章节
    for (int i = 0; i < matches.length; i++) {
      final title = matches[i].group(0)!.trim();

      // 提取正文（从本章标题到下一章标题之间）
      final start = matches[i].end;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : text.length;
      final content = text.substring(start, end).trim();

      chapters.add(Chapter(
        id: '${matches[i].start}',
        bookId: '', // 稍后设置
        title: title,
        index: i,
        url: '',
        isDownloaded: true,
        content: content,
      ));
    }

    return chapters;
  }

  /// 分割章节 - 支持常见章节标题格式
  
} 
