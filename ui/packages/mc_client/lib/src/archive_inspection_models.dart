class InspectedEntry {
  const InspectedEntry(
    this.index,
    this.components,
    this.directory,
    this.size,
    this.compressedSize,
  );
  final int index, size;
  final List<String> components;
  final bool directory;
  final int? compressedSize;
}

class InspectedArchive {
  const InspectedArchive(
    this.sha256,
    this.format,
    this.entries,
    this.totalSize,
  );
  final String sha256, format;
  final List<InspectedEntry> entries;
  final int totalSize;
}

class ArchiveRead {
  const ArchiveRead(this.result, this.cancel);
  final Future<InspectedArchive> result;
  final Future<void> Function() cancel;
}
