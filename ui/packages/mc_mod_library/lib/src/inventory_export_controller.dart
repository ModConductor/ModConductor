import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

typedef InventoryExportLocationChooser = Future<String?> Function();

enum InventoryExportView { choices, progress, stale, failed }

class InventoryExportDialogResult {
  const InventoryExportDialogResult._(
    this.completed,
    this.cancelled,
    this.retry,
    this.destinationPath,
  ) : fileName = null,
      rowCount = null;

  const InventoryExportDialogResult.completed(
    this.destinationPath,
    this.fileName,
    this.rowCount,
  ) : completed = true,
      cancelled = false,
      retry = false;
  const InventoryExportDialogResult.cancelled()
    : this._(false, true, false, null);
  const InventoryExportDialogResult.retry() : this._(false, false, true, null);

  final bool completed, cancelled, retry;
  final String? destinationPath;
  final String? fileName;
  final int? rowCount;
}

class InventoryExportController extends ChangeNotifier {
  InventoryExportController({
    required this.client,
    required this.capture,
    required this.chooseLocation,
  });

  static const defaultFields = {
    InventoryExportField.name,
    InventoryExportField.modId,
    InventoryExportField.priority,
    InventoryExportField.enabled,
    InventoryExportField.version,
    InventoryExportField.status,
  };

  final InventoryExportClient client;
  final InventoryExportCapture capture;
  final InventoryExportLocationChooser chooseLocation;
  InventoryExportScope scope = InventoryExportScope.selected;
  final fields = Set<InventoryExportField>.of(defaultFields);
  InventoryExportView view = InventoryExportView.choices;
  PreparedInventoryExport? prepared;
  InventoryExportDestination? destination;
  String? destinationPath;
  bool replacing = false, choosing = false;
  int writtenRows = 0, totalRows = 0;
  StreamSubscription<InventoryExportEvent>? _write;
  bool _disposed = false;

  bool get busy => choosing || view == InventoryExportView.progress;
  bool get hasIdentity =>
      fields.contains(InventoryExportField.name) ||
      fields.contains(InventoryExportField.modId);
  bool get canExport =>
      view == InventoryExportView.choices &&
      destination != null &&
      hasIdentity &&
      (!destination!.exists || replacing);

  void changeScope(InventoryExportScope value) {
    if (busy || scope == value) return;
    scope = value;
    _invalidate();
  }

  void toggleField(InventoryExportField field) {
    if (busy) return;
    fields.contains(field) ? fields.remove(field) : fields.add(field);
    _invalidate();
  }

  void setReplacing(bool value) {
    if (busy) return;
    replacing = value;
    _notify();
  }

  Future<void> choose() async {
    if (busy || !hasIdentity) return;
    choosing = true;
    view = InventoryExportView.choices;
    _notify();
    try {
      await _discardPrepared();
      final next = await client.prepare(
        InventoryExportCapture(
          workspaceId: capture.workspaceId,
          workspaceRevision: capture.workspaceRevision,
          profileId: capture.profileId,
          scope: scope,
          selectedModIds: capture.selectedModIds,
          query: capture.query,
          queryIdentity: capture.queryIdentity,
          catalogueRevision: capture.catalogueRevision,
          selectionRevision: capture.selectionRevision,
          fields: fields.toList(growable: false),
        ),
      );
      prepared = next;
      final path = await chooseLocation();
      if (path == null) {
        await _discardPrepared();
        return;
      }
      final checked = await client.inspect(next.id, path);
      destination = checked;
      destinationPath = path;
      replacing = false;
    } on InventoryExportException catch (error) {
      _setFailure(error);
    } on Exception {
      view = InventoryExportView.failed;
    } finally {
      choosing = false;
      _notify();
    }
  }

  Future<InventoryExportDialogResult?> export() async {
    final snapshot = prepared, target = destination;
    if (!canExport || snapshot == null || target == null) return null;
    view = InventoryExportView.progress;
    writtenRows = 0;
    totalRows = snapshot.rowCount;
    _notify();
    final done = Completer<InventoryExportDialogResult?>();
    _write = client
        .write(snapshot.id, target.id, replaceExisting: replacing)
        .listen(
          (event) {
            switch (event) {
              case InventoryExportProgress():
                writtenRows = event.writtenRows;
                totalRows = event.totalRows;
                _notify();
              case InventoryExportCompleted():
                prepared = null;
                destination = null;
                done.complete(
                  InventoryExportDialogResult.completed(
                    destinationPath!,
                    event.fileName,
                    event.rowCount,
                  ),
                );
            }
          },
          onError: (Object error) {
            if (error is InventoryExportException) {
              _setFailure(error);
            } else {
              view = InventoryExportView.failed;
            }
            if (!done.isCompleted) done.complete(null);
          },
          onDone: () {
            if (!done.isCompleted) {
              view = InventoryExportView.failed;
              _notify();
              done.complete(null);
            }
          },
          cancelOnError: true,
        );
    return done.future;
  }

  Future<InventoryExportDialogResult> cancel() async {
    if (view == InventoryExportView.progress) {
      final writing = _write;
      _write = null;
      unawaited(writing?.cancel());
      view = InventoryExportView.choices;
      _notify();
    } else {
      await _discardPrepared();
    }
    return const InventoryExportDialogResult.cancelled();
  }

  void useCurrentSelection() => view = InventoryExportView.stale;

  Future<void> chooseAgain() async {
    view = InventoryExportView.choices;
    destination = null;
    destinationPath = null;
    replacing = false;
    await choose();
  }

  void _setFailure(InventoryExportException error) {
    view = switch (error.fault) {
      InventoryExportFault.stale ||
      InventoryExportFault.notFound => InventoryExportView.stale,
      _ => InventoryExportView.failed,
    };
  }

  void _invalidate() {
    unawaited(_discardPrepared());
    destination = null;
    destinationPath = null;
    replacing = false;
    _notify();
  }

  Future<void> _discardPrepared() async {
    final value = prepared;
    prepared = null;
    destination = null;
    destinationPath = null;
    if (value != null) {
      try {
        await client.discard(value.id);
      } on Exception {
        // The session expires without changing a file.
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_write?.cancel());
    unawaited(_discardPrepared());
    super.dispose();
  }
}
