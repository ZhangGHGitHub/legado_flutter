import 'package:freezed_annotation/freezed_annotation.dart';

part 'webdav_entry.freezed.dart';

/// Domain representation of a WebDAV directory entry.
@freezed
class WebDavEntry with _$WebDavEntry {
  const factory WebDavEntry({
    required String name,
    required String path,
    required bool isDir,
    required int size,
    required int lastModified,
    String? etag,
  }) = _WebDavEntry;
}
