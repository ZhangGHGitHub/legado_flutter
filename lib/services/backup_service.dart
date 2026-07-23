import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../bridge/legado_db_bridge.dart';
import '../bridge/legado_engine_bridge.dart';
import '../services/app_paths.dart';
import '../src/rust/api/backup.dart' as backup_api;
import '../src/rust/api/webdav.dart' as webdav_api;
import 'settings_backup.dart';
import 'webdav_prefs.dart';

/// 备份与恢复服务（DB + 设置打包，支持本地/WebDAV）
class BackupService {
  BackupService();

  static const _archivePayloadName = 'legado_backup.json';

  // These files are the stable subset whose JSON shape is shared with the
  // original app. The wrapper remains the lossless payload for Rust-only data
  // such as chapters and Flutter settings.
  static const _legacyBookshelfName = 'bookshelf.json';
  static const _legacyBookmarkName = 'bookmark.json';
  static const _legacySourceName = 'bookSource.json';
  static const _legacyReplaceRuleName = 'replaceRule.json';
  static const _legacyDetailedRecordName = 'readRecord_detail.json';

  void _requireReady() {
    if (!LegadoEngineBridge.isAvailable || !LegadoDbBridge.isReady) {
      throw StateError('Rust 引擎或数据库未就绪');
    }
  }

  String backupFileName({DateTime? now, String? device}) {
    final date = now ?? DateTime.now();
    final dateText =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final normalizedDevice = _normalizeFileName(device?.trim() ?? '');
    return normalizedDevice.isEmpty
        ? 'backup$dateText.zip'
        : 'backup$dateText-$normalizedDevice.zip';
  }

  static Uint8List archiveJson(String json) {
    final archive = Archive()
      ..add(ArchiveFile.string(_archivePayloadName, json));
    final root = _decodeMap(json);
    final database = root?['database'];
    if (database is Map) {
      _addLegacyJsonArray(
        archive,
        _legacyBookshelfName,
        database['books'],
        transform: _toOriginalBook,
      );
      _addLegacyJsonArray(archive, _legacyBookmarkName, database['bookmarks']);
      _addLegacyJsonArray(archive, _legacySourceName, database['sources']);
      _addLegacyJsonArray(
        archive,
        _legacyReplaceRuleName,
        database['replaceRules'],
        transform: _toOriginalReplaceRule,
      );
      _addLegacyJsonArray(
        archive,
        _legacyDetailedRecordName,
        database['detailedReadRecords'],
      );
    }
    return ZipEncoder().encodeBytes(archive);
  }

  static String extractJson(List<int> bytes) {
    if (!_isZip(bytes)) return utf8.decode(bytes);

    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final payload = _findArchiveEntry(archive, _archivePayloadName);
      if (payload != null) {
        return utf8.decode(payload.readBytes() ?? const <int>[]);
      }

      final legacyPayload = _legacyZipToWrapper(archive);
      if (legacyPayload != null) return jsonEncode(legacyPayload);

      final fallback = archive.firstWhere(
        (entry) => entry.isFile && entry.name.toLowerCase().endsWith('.json'),
        orElse: () => throw const FormatException('ZIP 备份缺少 JSON 数据'),
      );
      return utf8.decode(fallback.readBytes() ?? const <int>[]);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('无法读取 ZIP 备份: $error');
    }
  }

  static bool _isZip(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4b &&
        (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
        (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08);
  }

  static String _normalizeFileName(String value) {
    return value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Map<String, dynamic>? _decodeMap(String raw) {
    try {
      final value = jsonDecode(raw);
      return value is Map ? Map<String, dynamic>.from(value) : null;
    } on FormatException {
      return null;
    }
  }

  static List<dynamic>? _decodeList(String raw, String fileName) {
    try {
      final value = jsonDecode(raw);
      if (value is! List) {
        throw FormatException('$fileName 必须是 JSON 数组');
      }
      return value;
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('$fileName JSON 无效: $error');
    }
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static String _asString(Object? value, [String fallback = '']) {
    return value is String ? value : value?.toString() ?? fallback;
  }

  static int _asInt(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static void _addLegacyJsonArray(
    Archive archive,
    String fileName,
    Object? value, {
    Map<String, dynamic> Function(Object value)? transform,
  }) {
    if (value is! List || value.isEmpty) return;
    final items = value
        .map((item) => transform?.call(item) ?? item)
        .toList(growable: false);
    archive.add(ArchiveFile.string(fileName, jsonEncode(items)));
  }

  static Map<String, dynamic> _toOriginalBook(Object value) {
    final book = _asMap(value) ?? const <String, dynamic>{};
    final total = _asInt(book['totalChapterNum']);
    final index = _asInt(book['durChapterIndex']);
    final origin = book['bookSourceUrl'] ?? book['sourceUrl'];
    return {
      'bookUrl': book['bookUrl'] ?? book['id'] ?? '',
      'tocUrl': book['tocUrl'] ?? '',
      'origin': origin ?? 'local',
      'originName': book['originName'] ?? book['sourceName'] ?? '',
      'name': book['name'] ?? '',
      'author': book['author'] ?? '',
      'kind': book['kind'],
      'customTag': book['customTag'],
      'coverUrl': book['coverUrl'],
      'customCoverUrl': book['customCoverUrl'],
      'intro': book['description'] ?? book['intro'],
      'customIntro': book['customIntro'],
      'charset': book['charset'],
      'type': _legacyBookType(book['type']),
      'group': book['group'] ?? book['bookGroup'] ?? 0,
      'latestChapterTitle': book['latestChapterTitle'] ?? book['lastChapter'],
      'latestChapterTime': book['latestChapterTime'] ?? 0,
      'lastCheckTime': book['lastCheckTime'] ?? 0,
      'lastCheckCount': book['lastCheckCount'] ?? 0,
      'totalChapterNum': total,
      'durChapterTitle': book['durChapterTitle'] ?? book['currentChapter'],
      'durChapterIndex': index,
      'durChapterPos': book['durChapterPos'] ?? book['currentPageIndex'] ?? 0,
      'durChapterTime': book['durChapterTime'] ?? 0,
      'wordCount': book['wordCount'],
      'canUpdate': book['canUpdate'] ?? true,
      'order': book['order'] ?? 0,
      'originOrder': book['originOrder'] ?? 0,
      'variable': book['variable'],
      'readConfig': book['readConfig'],
      'syncTime': book['syncTime'] ?? 0,
      'readIteration': book['readIteration'] ?? 0,
      'addTime': book['addTime'] ?? 0,
      'preReadNote': book['preReadNote'],
      'finishTime': book['finishTime'] ?? 0,
      'postReadNote': book['postReadNote'],
      'bookRating': book['bookRating'] ?? 0,
    };
  }

  static Map<String, dynamic> _toOriginalReplaceRule(Object value) {
    final rule = _asMap(value) ?? const <String, dynamic>{};
    final id = rule['id'];
    return {
      ...rule,
      if (id is String && int.tryParse(id) != null) 'id': int.parse(id),
    };
  }

  static int _legacyBookType(Object? value) {
    if (value is num) return value.toInt();
    switch (value?.toString().toLowerCase()) {
      case 'audio':
        return 1;
      case 'image':
        return 2;
      case 'file':
        return 3;
      case 'video':
        return 4;
      default:
        return int.tryParse(value?.toString() ?? '') ?? 0;
    }
  }

  static ArchiveFile? _findArchiveEntry(Archive archive, String fileName) {
    final target = fileName.toLowerCase();
    for (final entry in archive) {
      if (entry.isFile &&
          _archiveBaseName(entry.name).toLowerCase() == target) {
        return entry;
      }
    }
    return null;
  }

  static String _archiveBaseName(String path) {
    final slash = path.lastIndexOf('/');
    return slash == -1 ? path : path.substring(slash + 1);
  }

  static String? _archiveEntryText(Archive archive, String fileName) {
    final entry = _findArchiveEntry(archive, fileName);
    if (entry == null) return null;
    return utf8.decode(entry.readBytes() ?? const <int>[]);
  }

  static Map<String, dynamic>? _legacyZipToWrapper(Archive archive) {
    final database = <String, dynamic>{};
    var found = false;

    final bookshelf = _archiveEntryText(archive, _legacyBookshelfName);
    if (bookshelf != null) {
      found = true;
      database['books'] = _decodeList(
        bookshelf,
        _legacyBookshelfName,
      )?.map((item) => _fromOriginalBook(item)).toList(growable: false);
    }
    final bookmarks = _archiveEntryText(archive, _legacyBookmarkName);
    if (bookmarks != null) {
      found = true;
      database['bookmarks'] = _decodeList(
        bookmarks,
        _legacyBookmarkName,
      )?.map((item) => _fromOriginalBookmark(item)).toList(growable: false);
    }
    final sources = _archiveEntryText(archive, _legacySourceName);
    if (sources != null) {
      found = true;
      database['sources'] = _decodeList(sources, _legacySourceName);
    }
    final rules = _archiveEntryText(archive, _legacyReplaceRuleName);
    if (rules != null) {
      found = true;
      database['replaceRules'] = _decodeList(
        rules,
        _legacyReplaceRuleName,
      )?.map((item) => _fromOriginalReplaceRule(item)).toList(growable: false);
    }
    final detailed = _archiveEntryText(archive, _legacyDetailedRecordName);
    if (detailed != null) {
      found = true;
      database['detailedReadRecords'] = _decodeList(
        detailed,
        _legacyDetailedRecordName,
      );
    }
    if (!found) return null;

    return {
      'version': 1,
      'database': database,
      'settings': <String, dynamic>{},
    };
  }

  static Map<String, dynamic> _fromOriginalBook(Object value) {
    final book = _asMap(value) ?? const <String, dynamic>{};
    final total = _asInt(book['totalChapterNum']);
    final index = _asInt(book['durChapterIndex']);
    final origin = book['origin'] ?? book['bookSourceUrl'];
    return {
      'id': book['bookUrl'] ?? book['id'] ?? '',
      'name': book['name'] ?? '',
      'author': book['author'] ?? '',
      'coverUrl': book['coverUrl'] ?? '',
      'type': _currentBookType(book['type']),
      'progress': total > 0 ? index / total : 0,
      'currentChapter': book['durChapterTitle'],
      'lastChapter': book['latestChapterTitle'] ?? '',
      'totalChapterNum': total,
      'durChapterIndex': index,
      'currentPageIndex': book['durChapterPos'] ?? 0,
      'isFavorite': true,
      'sourceUrl': origin ?? '',
      'description': book['intro'] ?? '',
      'bookSourceUrl': origin ?? '',
      'group': book['group'] ?? '',
      'readIteration': book['readIteration'] ?? 0,
      'simReadEnabled': false,
      'simReadStartDate': '',
      'simReadStartChapter': 0,
      'simReadDailyChapters': 3,
    };
  }

  static Map<String, dynamic> _fromOriginalBookmark(Object value) {
    final bookmark = _asMap(value) ?? const <String, dynamic>{};
    return {...bookmark, 'bookId': bookmark['bookId'] ?? ''};
  }

  static Map<String, dynamic> _fromOriginalReplaceRule(Object value) {
    final rule = _asMap(value) ?? const <String, dynamic>{};
    return {
      ...rule,
      'id': _asString(rule['id']),
      'isEnabled': rule['isEnabled'] ?? true,
      'isRegex': rule['isRegex'] ?? true,
    };
  }

  static String _currentBookType(Object? value) {
    if (value is String) return value;
    return _asInt(value).toString();
  }

  Future<String> createFullBackupJson() async {
    _requireReady();
    final database =
        jsonDecode(backup_api.exportBackup()) as Map<String, dynamic>;
    final settings = await SettingsBackup.collect();
    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'engineVersion': LegadoEngineBridge.engineVersion(),
      'database': database,
      'settings': settings,
    });
  }

  Future<File> backupToLocalFile() async {
    final json = await createFullBackupJson();
    final backupsDir = await AppPaths.backupsDir();
    final file = File(p.join(backupsDir.path, backupFileName()));
    await file.writeAsBytes(archiveJson(json));
    debugPrint('[Backup] 本地备份: ${file.path}');
    return file;
  }

  Future<void> restoreFromJson(String raw, {bool replace = true}) async {
    _requireReady();
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final database = root['database'];
    if (database is! Map) {
      throw const FormatException('备份缺少 database 字段');
    }
    backup_api.restoreBackup(json: jsonEncode(database), replace: replace);
    final settings = root['settings'];
    if (settings is Map<String, dynamic>) {
      await SettingsBackup.apply(settings);
    }
  }

  Future<void> restoreFromBytes(List<int> bytes, {bool replace = true}) async {
    await restoreFromJson(extractJson(bytes), replace: replace);
  }

  Future<File?> pickAndRestore({bool replace = true}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
    );
    if (result == null || result.files.single.path == null) return null;
    final file = File(result.files.single.path!);
    await restoreFromBytes(await file.readAsBytes(), replace: replace);
    return file;
  }

  Future<List<File>> listLocalBackups() async {
    final backupsDir = await AppPaths.backupsDir();
    if (!await backupsDir.exists()) return [];
    final files = await backupsDir
        .list()
        .where(
          (e) =>
              e is File &&
              (e.path.toLowerCase().endsWith('.zip') ||
                  e.path.toLowerCase().endsWith('.json')),
        )
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  String remoteBackupPath(WebDavConfig config, String filename) {
    return WebDavConfig.joinPath(config.rootDir, filename);
  }

  Future<void> backupToWebDav() async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }
    final json = await createFullBackupJson();
    final remote = remoteBackupPath(
      config,
      backupFileName(device: config.device),
    );
    await webdav_api.webdavUpload(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remote,
      data: archiveJson(json),
    );
    debugPrint('[Backup] WebDAV 上传: $remote');
  }

  Future<List<webdav_api.WebDavEntry>> listWebDavBackups() async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }
    final items = await webdav_api.webdavList(
      url: config.url,
      username: config.account,
      password: config.password,
      path: config.rootDir,
    );
    return items
        .where(
          (e) =>
              !e.isDir &&
              ((e.name.toLowerCase().startsWith('backup') &&
                      e.name.toLowerCase().endsWith('.zip')) ||
                  (e.name.toLowerCase().startsWith('legado_backup') &&
                      e.name.toLowerCase().endsWith('.json'))),
        )
        .toList()
      ..sort((a, b) => b.name.compareTo(a.name));
  }

  Future<void> restoreFromWebDav(
    String remotePath, {
    bool replace = true,
  }) async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }
    final bytes = await webdav_api.webdavDownload(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remotePath,
    );
    await restoreFromBytes(bytes, replace: replace);
  }

  Future<void> deleteWebDavBackup(String remotePath) async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }
    await webdav_api.webdavDelete(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remotePath,
    );
  }

  Future<void> renameWebDavBackup(String remotePath, String newName) async {
    final config = await WebDavPrefs.load();
    if (!config.isReady) {
      throw StateError('请先配置 WebDAV');
    }
    final name = newName.trim();
    if (name.isEmpty || name.contains('/') || name.contains('\\')) {
      throw const FormatException('备份名称不能为空且不能包含路径分隔符');
    }
    final directory = remotePath.substring(0, remotePath.lastIndexOf('/') + 1);
    final destination = '$directory$name';
    await webdav_api.webdavMove(
      url: config.url,
      username: config.account,
      password: config.password,
      remotePath: remotePath,
      destinationPath: destination,
    );
  }
}
