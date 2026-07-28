/// Domain representation of a WebDAV directory entry.
class WebDavEntry {
  const WebDavEntry({
    required this.name,
    required this.path,
    required this.isDir,
    required this.size,
    required this.lastModified,
    this.etag,
  });

  final String name;
  final String path;
  final bool isDir;
  final int size;
  final int lastModified;
  final String? etag;
}
