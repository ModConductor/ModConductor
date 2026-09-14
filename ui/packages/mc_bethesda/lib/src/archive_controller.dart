import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

import 'controller.dart';

class ArchivePolicyController extends ChangeNotifier {
  final rows = McCollectionModel<String, ArchivePolicyEntry>(
    idOf: (row) => row.name,
    labelOf: (row) => row.name,
  );
  ArchivePolicyClient? _client;
  PluginsController? _plugins;
  String? _workspace, _profile;
  ArchivePolicyView? state;
  bool reading = false, writing = false, stale = false, inspecting = false;
  String? problem;
  Future<String?> Function()? resumeAction;
  VoidCallback? onChanged;
  int _epoch = 0, _inputsRevision = 0;
  bool _disposed = false;

  bool get connected =>
      _client != null && _workspace != null && _profile != null;
  bool get canApply =>
      state != null &&
      !reading &&
      !writing &&
      !stale &&
      !state!.pending &&
      !state!.applied &&
      state!.blockingProblems.isEmpty;
  bool get canRestore =>
      state != null &&
      !reading &&
      !writing &&
      !stale &&
      !state!.pending &&
      state!.saved;

  void attach(
    ArchivePolicyClient? client,
    PluginsController? plugins,
    String? workspace,
    String? profile,
  ) {
    if (identical(client, _client) &&
        identical(plugins, _plugins) &&
        workspace == _workspace &&
        profile == _profile) {
      return;
    }
    ++_epoch;
    _client = client;
    _plugins = plugins;
    _workspace = workspace;
    _profile = profile;
    state = null;
    problem = null;
    reading = writing = stale = inspecting = false;
    rows.clear();
    notifyListeners();
  }

  void invalidate() {
    ++_inputsRevision;
    if (state != null) {
      stale = true;
      notifyListeners();
    }
  }

  void inspect() {
    if (rows.selected == null) return;
    inspecting = true;
    notifyListeners();
  }

  void closeInspector() {
    inspecting = false;
    notifyListeners();
  }

  Future<void> scan() async {
    final client = _client, plugins = _plugins;
    final workspace = _workspace, profile = _profile;
    if (client == null ||
        plugins == null ||
        workspace == null ||
        profile == null ||
        reading ||
        writing) {
      return;
    }
    final epoch = _epoch, revision = _inputsRevision;
    reading = true;
    problem = null;
    notifyListeners();
    try {
      if (plugins.order == null || plugins.stale) await plugins.scan();
      final headers = plugins.order?.headers.id;
      if (headers == null || plugins.stale) {
        throw const FormatException('Refresh the plugins before archives.');
      }
      final value = await client.scan(workspace, profile, headers);
      if (_disposed || epoch != _epoch) return;
      _set(value);
      stale = value.stale || revision != _inputsRevision;
    } on ProfileDataProblem catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error.detail;
        stale = state != null;
      }
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error is FormatException
            ? error.message.toString()
            : 'The archive scan could not finish. Try again.';
        stale = state != null;
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        reading = false;
        notifyListeners();
      }
    }
  }

  Future<void> apply() => _change(true);
  Future<void> restore() => _change(false);

  Future<void> _change(bool apply) async {
    final client = _client, current = state;
    if (client == null ||
        current == null ||
        (apply ? !canApply : !canRestore)) {
      return;
    }
    final epoch = _epoch;
    writing = true;
    problem = null;
    notifyListeners();
    try {
      if (apply) {
        await client.apply(
          newOperationId(),
          current.reference,
          current.snapshotId,
        );
      } else {
        await client.restore(newOperationId(), current.reference);
      }
      if (_disposed || epoch != _epoch) return;
      onChanged?.call();
      writing = false;
      await scan();
    } on ProfileDataProblem catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error.detail;
        if (error.kind == ProfileDataProblemKind.stale) stale = true;
      }
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        problem = 'The archive change could not finish. Refresh to check it.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        writing = false;
        notifyListeners();
      }
    }
  }

  Future<void> resume() async {
    if (resumeAction == null || state?.pending != true || reading || writing) {
      return;
    }
    final epoch = _epoch;
    writing = true;
    problem = null;
    notifyListeners();
    try {
      problem = await resumeAction!();
      if (!_disposed && epoch == _epoch && problem == null) {
        writing = false;
        await scan();
      }
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        problem = 'The archive change could not resume. Try again.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        writing = false;
        notifyListeners();
      }
    }
  }

  Future<void> validate() async {
    final client = _client, current = state;
    final workspace = _workspace, profile = _profile, epoch = _epoch;
    if (client == null ||
        current == null ||
        workspace == null ||
        profile == null ||
        reading ||
        writing) {
      return;
    }
    try {
      final value = await client.read(workspace, profile, current.snapshotId);
      if (!_disposed &&
          epoch == _epoch &&
          state?.snapshotId == current.snapshotId) {
        stale = stale || value.stale;
        notifyListeners();
      }
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        stale = true;
        notifyListeners();
      }
    }
  }

  void _set(ArchivePolicyView value) {
    state = value;
    final names = value.entries.map((row) => row.name).toSet();
    rows.apply(
      upserts: value.entries,
      removed: rows.ids.where((name) => !names.contains(name)).toList(),
    );
    rows.sort(
      (a, b) => (a.position ?? 1 << 30).compareTo(b.position ?? 1 << 30),
      label: 'Order',
    );
    if (rows.selected == null && value.entries.isNotEmpty) {
      rows.select(value.entries.first.name);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    rows.dispose();
    super.dispose();
  }
}
