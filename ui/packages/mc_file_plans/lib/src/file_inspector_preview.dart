part of 'file_inspector_controller.dart';

FilePreviewRepresentation _initialRepresentation(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg')) {
    return FilePreviewRepresentation.image;
  }
  const text = [
    '.txt',
    '.ini',
    '.json',
    '.xml',
    '.html',
    '.htm',
    '.css',
    '.js',
    '.lua',
    '.psc',
    '.yaml',
    '.yml',
    '.toml',
    '.md',
    '.csv',
    '.log',
  ];
  return text.any(lower.endsWith)
      ? FilePreviewRepresentation.text
      : FilePreviewRepresentation.hex;
}

extension _FileInspectorPreview on FileInspectorController {
  void _cancelPreview() {
    ++_previewEpoch;
    final read = _previewRead;
    _previewRead = null;
    if (read != null) {
      unawaited(read.cancel().onError<Exception>((_, _) {}));
    }
    previewLoading = false;
  }

  void _cancelPreviewByUser() {
    _cancelPreview();
    previewProblem = 'Preview stopped.';
    if (!_disposed) _notifyInspector();
  }

  void _setPreviewRepresentation(FilePreviewRepresentation value) {
    if (previewRepresentation == value) return;
    previewRepresentation = value;
    _notifyInspector();
    unawaited(loadPreview());
  }

  Future<void> _loadPreview() async {
    final chosen = selected;
    if (_disposed || chosen == null) return;
    _cancelPreview();
    final epoch = _previewEpoch;
    preview = null;
    previewProblem = null;
    previewLoading = true;
    _notifyInspector();
    final FilePreviewRead read;
    if (archiveMode) {
      final client = _archiveClient;
      final artifact = _artifact;
      final manifest = _archiveManifest;
      final entry = _archiveEntry;
      if (client == null ||
          artifact == null ||
          manifest == null ||
          entry == null) {
        previewLoading = false;
        return;
      }
      read = client.previewEntry(
        artifact,
        manifest,
        entry,
        previewRepresentation,
      );
    } else {
      final client = _client;
      final snapshot = _snapshot;
      if (client == null || snapshot == null) {
        previewLoading = false;
        return;
      }
      read = client.preview(snapshot, chosen.source, previewRepresentation);
    }
    _previewRead = read;
    try {
      final result = await read.result;
      if (_disposed ||
          epoch != _previewEpoch ||
          FileInspectorController.key(chosen) != _selected) {
        return;
      }
      preview = result;
    } on Exception catch (error) {
      if (!_disposed && epoch == _previewEpoch) {
        previewProblem = error is FilePlanException
            ? error.detail
            : error is ArtifactProblem
            ? error.detail
            : 'Could not preview this source.';
      }
    } finally {
      if (!_disposed && epoch == _previewEpoch) {
        _previewRead = null;
        previewLoading = false;
        _notifyInspector();
      }
    }
  }
}
