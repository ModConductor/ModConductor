import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mc_client/mc_client.dart';

class FileInspectorController extends ChangeNotifier {
  final editTextFocus = FocusNode();
  FilePlansClient? _client;
  String? _snapshot;
  ArtifactsClient? _archiveClient;
  Artifact? _artifact;
  InspectedArchive? _archiveManifest;
  InspectedEntry? _archiveEntry;
  FilePreviewRead? _previewRead;
  FilePreviewRepresentation previewRepresentation =
      FilePreviewRepresentation.text;
  FilePreviewResult? preview;
  bool previewLoading = false;
  String? previewProblem;
  ManagedTextDocument? textDocument;
  bool openingText = false, savingText = false;
  String? textProblem;
  String? _textActionId;
  Future<bool> Function(FutureOr<void> Function())? _textNavigationGuard;
  int _textEpoch = 0;
  int _previewEpoch = 0;
  bool get archiveMode => _artifact != null;
  List<String>? target;
  ManagedFileCopy? requestedCopy;
  final _copies = <Object, InspectedFileCopy>{};
  List<InspectedFileCopy> get copies => List.unmodifiable(_copies.values);
  InspectedFileCopy? focusedCopy;
  InspectedFileCopy? get selected =>
      _copies[_selected] ??
      (focusedCopy != null && key(focusedCopy!) == _selected
          ? focusedCopy
          : null);
  Object? _selected;
  FilePlanCursor? _next;
  final history = <FileVisibilityAudit>[];
  int? _before;
  bool writable = false;
  bool historyLoaded = false;
  bool loading = false, loadingHistory = false;
  String? problem, historyProblem;
  int _epoch = 0, _historyEpoch = 0;
  bool _disposed = false;
  bool get visible => target != null || requestedCopy != null;
  bool get canLoad => _next != null;
  bool get canLoadHistory =>
      selected?.copy != null && (!historyLoaded || _before != null);
  static Object key(InspectedFileCopy copy) => copy.source.id;
  void _cancelPreview() {
    ++_previewEpoch;
    final read = _previewRead;
    _previewRead = null;
    if (read != null) {
      unawaited(read.cancel().onError<Exception>((_, _) {}));
    }
    previewLoading = false;
  }

  void closeTextEditor() {
    ++_textEpoch;
    textDocument = null;
    openingText = false;
    savingText = false;
    textProblem = null;
    _textActionId = null;
    if (!_disposed) notifyListeners();
  }

  void bindTextNavigationGuard(
    Future<bool> Function(FutureOr<void> Function())? guard,
  ) {
    _textNavigationGuard = guard;
  }

  Future<bool> _guardTextNavigation(FutureOr<void> Function() navigate) async {
    final guard = _textNavigationGuard;
    if (guard != null) return guard(navigate);
    await navigate();
    return true;
  }

  Future<bool> guardTextNavigation(FutureOr<void> Function() navigate) =>
      _guardTextNavigation(navigate);

  bool get canEditText =>
      !archiveMode &&
      selected?.source is ManagedPreviewSource &&
      selected?.historical == false &&
      selected?.copy != null;

  Future<void> openTextEditor() async {
    final client = _client, snapshot = _snapshot, selected = this.selected;
    if (_disposed ||
        openingText ||
        client == null ||
        snapshot == null ||
        selected == null ||
        !canEditText) {
      return;
    }
    final epoch = ++_textEpoch;
    openingText = true;
    textProblem = null;
    notifyListeners();
    try {
      final document = await client.openManagedText(
        snapshot,
        selected.source as ManagedPreviewSource,
      );
      if (_disposed || epoch != _textEpoch || key(selected) != _selected) {
        return;
      }
      textDocument = document;
      _textActionId = null;
    } on Exception catch (error) {
      if (!_disposed && epoch == _textEpoch) {
        textProblem = error is FilePlanException
            ? error.detail
            : 'This text file could not be opened for editing.';
      }
    } finally {
      if (!_disposed && epoch == _textEpoch) {
        openingText = false;
        notifyListeners();
      }
    }
  }

  Future<bool> saveText(String content) async {
    final client = _client, snapshot = _snapshot, opened = textDocument;
    if (_disposed ||
        savingText ||
        client == null ||
        snapshot == null ||
        opened == null) {
      return false;
    }
    final epoch = _textEpoch;
    savingText = true;
    textProblem = null;
    notifyListeners();
    try {
      final action = _textActionId ??= newOperationId();
      await client.saveManagedText(snapshot, action, opened.source, content);
      if (_disposed || epoch != _textEpoch) return false;
      _textActionId = null;
      return true;
    } on Exception catch (error) {
      if (!_disposed && epoch == _textEpoch) {
        textProblem = error is FilePlanException
            ? error.detail
            : 'The new version could not be saved.';
        if (error is FilePlanException &&
            error.failure == FilePlanFailure.cancelled) {
          _textActionId = null;
        }
      }
      return false;
    } finally {
      if (!_disposed && epoch == _textEpoch) {
        savingText = false;
        notifyListeners();
      }
    }
  }

  Future<bool> abandonPendingText() async {
    final action = _textActionId, client = _client;
    if (action == null) return true;
    if (_disposed || client == null || savingText) return false;
    savingText = true;
    textProblem = null;
    notifyListeners();
    try {
      await client.abandonManagedText(action);
      if (_disposed) return false;
      _textActionId = null;
      return true;
    } on Exception catch (error) {
      if (!_disposed) {
        textProblem = error is FilePlanException
            ? error.detail
            : 'The interrupted edit could not be abandoned.';
      }
      return false;
    } finally {
      if (!_disposed) {
        savingText = false;
        notifyListeners();
      }
    }
  }

  void attach(
    FilePlansClient? client,
    FilePlanState? state, {
    bool clear = false,
  }) {
    if (clear && textDocument != null) {
      _client = client;
      _snapshot = state?.id;
      _archiveClient = null;
      _artifact = null;
      _archiveManifest = null;
      _archiveEntry = null;
      _cancelPreview();
      ++_epoch;
      loading = false;
      notifyListeners();
      return;
    }
    _attach(client, state, clear: clear);
  }

  void _attach(
    FilePlansClient? client,
    FilePlanState? state, {
    required bool clear,
  }) {
    if (_snapshot != state?.id || _client != client) {
      _cancelPreview();
      preview = null;
      previewProblem = null;
    }
    _client = client;
    _snapshot = state?.id;
    _archiveClient = null;
    _artifact = null;
    _archiveManifest = null;
    _archiveEntry = null;
    ++_epoch;
    loading = false;
    if (clear) close();
  }

  void close() {
    closeTextEditor();
    _cancelPreview();
    ++_epoch;
    ++_historyEpoch;
    target = null;
    requestedCopy = null;
    focusedCopy = null;
    writable = false;
    _copies.clear();
    _selected = null;
    _next = null;
    loading = false;
    problem = null;
    preview = null;
    previewProblem = null;
    _clearHistory();
    if (!_disposed) notifyListeners();
  }

  Future<void> showTarget(List<String> path) async {
    await _guardTextNavigation(() async {
      close();
      target = List.unmodifiable(path);
      await reload();
    });
  }

  Future<void> showCopy(ManagedFileCopy copy) async {
    await _guardTextNavigation(() async {
      close();
      requestedCopy = copy;
      _selected = copy;
      await reload();
    });
  }

  Future<void> showArchive(
    ArtifactsClient client,
    Artifact artifact,
    InspectedArchive manifest,
    InspectedEntry entry,
  ) async {
    close();
    _archiveClient = client;
    _artifact = artifact;
    _archiveManifest = manifest;
    _archiveEntry = entry;
    target = List.unmodifiable(entry.components);
    previewRepresentation = _initialRepresentation(entry.components.last);
    final source = QualifiedArchiveEntryPreviewSource(
      workspaceId: artifact.workspaceId,
      artifactId: artifact.id,
      artifactRevision: artifact.revision,
      archiveSha256: manifest.sha256,
      format: manifest.format,
      index: entry.index,
      sourcePath: List.unmodifiable(entry.components),
      length: entry.size,
    );
    final row = InspectedFileCopy(
      sourcePath: source.sourcePath,
      name: artifact.originalName,
      versionLabel: manifest.format,
      enabled: true,
      hidden: false,
      winner: false,
      historical: false,
      length: entry.size,
      sha256: manifest.sha256,
      canHide: false,
      canUnhide: false,
      source: source,
      standing: FileSourceStanding.selected,
    );
    _copies[key(row)] = row;
    _selected = key(row);
    notifyListeners();
    await loadPreview();
  }

  static FilePreviewRepresentation _initialRepresentation(String name) {
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

  void select(InspectedFileCopy copy) {
    unawaited(
      _guardTextNavigation(() {
        closeTextEditor();
        _selected = key(copy);
        _clearHistory();
        previewRepresentation = _initialRepresentation(copy.sourcePath.last);
        notifyListeners();
        unawaited(loadPreview());
      }),
    );
  }

  void _clearHistory() {
    ++_historyEpoch;
    history.clear();
    _before = null;
    historyLoaded = false;
    loadingHistory = false;
    historyProblem = null;
  }

  Future<void> reload() async {
    _cancelPreview();
    preview = null;
    previewProblem = null;
    ++_epoch;
    _next = null;
    _copies.clear();
    focusedCopy = null;
    writable = false;
    _clearHistory();
    final chosen =
        selected?.copy ??
        (_selected is ManagedFileCopy
            ? _selected as ManagedFileCopy
            : requestedCopy);
    if (chosen != null) requestedCopy = chosen;
    await load(first: true);
  }

  Future<void> load({bool first = false}) async {
    final client = _client, snapshot = _snapshot;
    if (_disposed ||
        loading ||
        client == null ||
        snapshot == null ||
        !visible ||
        (!first && _next == null)) {
      return;
    }
    final epoch = _epoch;
    loading = true;
    problem = null;
    notifyListeners();
    try {
      final result = first && requestedCopy != null
          ? await client.inspectCopy(snapshot, requestedCopy!)
          : await client.inspect(
              snapshot,
              target!,
              cursor: first ? null : _next,
            );
      if (_disposed || epoch != _epoch || snapshot != _snapshot) return;
      if (result.state.id != snapshot) {
        throw const FormatException(
          'The inspection belongs to a different snapshot.',
        );
      }
      target = result.target;
      writable = result.writable;
      _next = result.next;
      focusedCopy = result.focusedCopy ?? focusedCopy;
      for (final copy in result.copies) {
        _copies[key(copy)] = copy;
      }
      _selected ??=
          result.copies.where((copy) => copy.winner).firstOrNull == null
          ? (result.copies.isEmpty ? null : key(result.copies.first))
          : key(result.copies.firstWhere((copy) => copy.winner));
      final chosen = selected;
      if (chosen != null) {
        previewRepresentation = _initialRepresentation(chosen.sourcePath.last);
        unawaited(loadPreview());
      }
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error is FilePlanException
            ? error.detail
            : 'Could not inspect this file.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void cancelPreview() {
    _cancelPreview();
    previewProblem = 'Preview stopped.';
    if (!_disposed) notifyListeners();
  }

  void setPreviewRepresentation(FilePreviewRepresentation value) {
    if (previewRepresentation == value) return;
    previewRepresentation = value;
    notifyListeners();
    unawaited(loadPreview());
  }

  Future<void> loadPreview() async {
    final chosen = selected;
    if (_disposed || chosen == null) return;
    _cancelPreview();
    final epoch = _previewEpoch;
    preview = null;
    previewProblem = null;
    previewLoading = true;
    notifyListeners();
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
      if (_disposed || epoch != _previewEpoch || key(chosen) != _selected) {
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
        notifyListeners();
      }
    }
  }

  Future<void> loadHistory() async {
    final client = _client, snapshot = _snapshot, copy = selected?.copy;
    if (_disposed ||
        loadingHistory ||
        client == null ||
        snapshot == null ||
        copy == null ||
        !canLoadHistory) {
      return;
    }
    final epoch = _historyEpoch;
    loadingHistory = true;
    historyProblem = null;
    notifyListeners();
    try {
      final page = await client.history(snapshot, copy, beforeId: _before);
      if (_disposed || epoch != _historyEpoch) return;
      history.addAll(page.changes);
      _before = page.nextBeforeId;
      historyLoaded = true;
    } on Exception catch (error) {
      if (!_disposed && epoch == _historyEpoch) {
        historyProblem = error is FilePlanException
            ? error.detail
            : 'Could not load file history.';
      }
    } finally {
      if (!_disposed && epoch == _historyEpoch) {
        loadingHistory = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelPreview();
    ++_epoch;
    ++_historyEpoch;
    editTextFocus.dispose();
    super.dispose();
  }
}
