import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../utils/ssrf_guard.dart';

/// 书单条目 — 对齐 Jingshiro 导出 `{name, author, intro}`。
typedef BookshelfListEntry = ({String name, String author, String intro});

/// 书架书单导入/导出 — 对齐 Jingshiro「导出书单 / 导入书单」。
abstract final class BookshelfListIo {
  /// 导出当前书架为 `[{name, author, intro}, …]`；返回写入路径，取消则为 null。
  static Future<String?> exportBooks(List<Book> books) async {
    final payload = books.map(_toExportMap).toList(growable: false);
    final text = const JsonEncoder.withIndent('  ').convert(payload);
    final suggested = 'bookshelf.json';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '导出书单',
      fileName: suggested,
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (savePath == null || savePath.isEmpty) return null;

    final path = savePath.toLowerCase().endsWith('.json')
        ? savePath
        : '$savePath.json';
    await File(path).writeAsString(text, flush: true);
    return path;
  }

  /// 从文件选择器读取书单文本。
  static Future<String?> pickFileText() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json', 'txt'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return utf8.decode(file.bytes!);
    }
    if (file.path != null) {
      return File(file.path!).readAsString();
    }
    return null;
  }

  /// 拉取书单 URL（或直接返回 JSON 文本）。
  static Future<String> resolveInput(String input) async {
    final text = input.trim();
    if (text.isEmpty) throw FormatException('请输入 url 或 json');
    if (_looksLikeUrl(text)) {
      return fetchUrl(text);
    }
    return text;
  }

  static Future<String> fetchUrl(String url) async {
    SsrfGuard.assertPublicHttpUrl(url);
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.plain,
        followRedirects: true,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );
    if (!kIsWeb) {
      dio.httpClientAdapter = IOHttpClientAdapter();
    }
    final res = await dio.get<String>(url);
    final body = res.data?.toString() ?? '';
    if (body.trim().isEmpty) {
      throw FormatException('书单 URL 返回为空');
    }
    return body;
  }

  static List<BookshelfListEntry> parseEntries(String text) {
    final decoded = jsonDecode(text.trim());
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map && decoded['books'] is List) {
      list = decoded['books'] as List;
    } else {
      throw FormatException('书单格式无效：需要 JSON 数组');
    }
    return list
        .whereType<Map>()
        .map((e) {
          final m = Map<String, dynamic>.from(e);
          final name = (m['name'] ?? m['bookName'] ?? '').toString().trim();
          final author = (m['author'] ?? '').toString().trim();
          final intro =
              (m['intro'] ?? m['description'] ?? '').toString().trim();
          return (name: name, author: author, intro: intro);
        })
        .where((e) => e.name.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> _toExportMap(Book b) => {
        'name': b.name,
        'author': b.author,
        'intro': b.description,
      };

  static bool _looksLikeUrl(String text) {
    if (text.contains('\n') || text.trimLeft().startsWith('[')) return false;
    final u = Uri.tryParse(text.trim());
    return u != null &&
        (u.scheme == 'http' || u.scheme == 'https') &&
        u.host.isNotEmpty;
  }
}
