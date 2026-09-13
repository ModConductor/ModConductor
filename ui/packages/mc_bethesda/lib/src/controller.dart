import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

class PluginsController extends ChangeNotifier {
  final rows = McCollectionModel<String, PluginEntry>(
    idOf: (r) => r.name,
    labelOf: (r) => r.name,
  );
  BethesdaClient? _client;
  PluginOrderClient? _orders;
  ProfilePluginOrder? order;
  bool writing = false, multiple = false;
  Future<String?> Function()? resumeAction;
  Future<void> resume() async {
    if (resumeAction == null || reading || writing || order?.pending != true) {
      return;
    }
    final epoch = _epoch;
    writing = true;
    problem = null;
    notifyListeners();
    try {
      final failure = await resumeAction!();
      if (_disposed || epoch != _epoch) return;
      problem = failure;
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        problem = 'The plugin order could not be applied. Try Resume again.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        writing = false;
        notifyListeners();
      }
    }
    if (!_disposed && epoch == _epoch && problem == null) await scan();
  }

  VoidCallback? onChanged;
  Map<String, PluginSetting> _settings = {};
  Map<String, int> _positions = {};
  PluginSetting? setting(String name) => _settings[name.toLowerCase()];
  int position(String name) => (_positions[name.toLowerCase()] ?? -1) + 1;
  int? loadPosition(String name) {
    var active = 0;
    for (final row in order?.entries ?? const <PluginSetting>[]) {
      if (row.enabled == true) active++;
      if (row.name.toLowerCase() == name.toLowerCase()) {
        return row.enabled == true ? active : null;
      }
    }
    return null;
  }

  bool get canEdit =>
      order != null &&
      _orders != null &&
      !reading &&
      !writing &&
      !stale &&
      !order!.pending &&
      !order!.externalChanged;
  bool get canMove =>
      canEdit &&
      rows.sortLabel == 'Order' &&
      rows.query.isEmpty &&
      rows.selectedIds.isNotEmpty &&
      rows.selectedIds.every(
        (name) =>
            setting(name)?.required == false &&
            setting(name)?.lockedIndex == null,
      );
  bool canToggle(String name) =>
      canEdit &&
      setting(name)?.required == false &&
      order!.headers.entries.any((entry) => entry.name == name);
  String? issue(String name) {
    for (final issue in order?.issues ?? const <PluginOrderIssue>[]) {
      if (issue.name.toLowerCase() == name.toLowerCase()) return issue.detail;
    }
    return null;
  }

  void sort(String label) {
    if (label == 'Order') {
      rows.sort(
        (a, b) => (position(a.name) == 0 ? 2147483647 : position(a.name))
            .compareTo(position(b.name) == 0 ? 2147483647 : position(b.name)),
        label: label,
      );
    } else {
      rows.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        label: label,
      );
    }
    notifyListeners();
  }

  void toggleMultiple() {
    multiple = !multiple;
    notifyListeners();
  }

  Future<void> change(PluginOrderAction action, {String? name}) async {
    if (!canEdit) return;
    final client = _orders!, current = order!, epoch = _epoch;
    writing = true;
    problem = null;
    notifyListeners();
    try {
      final value = await client.change(
        current.reference,
        current.headers.id,
        name == null ? rows.selectedIds.toList() : [name],
        action,
      );
      if (_disposed || epoch != _epoch) return;
      _setOrder(value);
      onChanged?.call();
    } on ProfileDataProblem catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error.detail;
        if (error.kind == ProfileDataProblemKind.stale) stale = true;
      }
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        problem = 'The plugin change could not finish. Refresh to check it.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        writing = false;
        notifyListeners();
      }
    }
  }

  Future<void> useGameOrder() async {
    if (_orders == null ||
        order == null ||
        reading ||
        writing ||
        stale ||
        order!.pending) {
      return;
    }
    final current = order!, epoch = _epoch;
    writing = true;
    problem = null;
    notifyListeners();
    try {
      final value = await _orders!.useGameOrder(
        current.reference,
        current.headers.id,
      );
      if (_disposed || epoch != _epoch) return;
      _setOrder(value);
      onChanged?.call();
    } on ProfileDataProblem catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error.detail;
        if (error.kind == ProfileDataProblemKind.stale) stale = true;
      }
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        problem = 'The game order could not be saved. Refresh to check it.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        writing = false;
        notifyListeners();
      }
    }
  }

  void _setOrder(ProfilePluginOrder value) {
    order = value;
    final source = value.headers;
    final unknown = value.unknown.map(
      (row) => PluginEntry(
        row.name,
        'Unknown',
        'File not found',
        '',
        true,
        null,
        const [],
        null,
        const [],
      ),
    );
    final entries = [...source.entries, ...unknown];
    state = PluginSnapshot(
      source.id,
      source.workspaceId,
      source.profileId,
      source.observedAt,
      source.stale,
      entries,
      source.problems,
    );
    final names = entries.map((r) => r.name).toSet();
    rows.apply(
      upserts: entries,
      removed: rows.ids.where((id) => !names.contains(id)).toList(),
    );
    _settings = {
      for (final row in [...value.entries, ...value.unknown])
        row.name.toLowerCase(): row,
    };
    _positions = {
      for (var i = 0; i < value.entries.length; i++)
        value.entries[i].name.toLowerCase(): i,
    };
    if (rows.sortLabel == null || rows.sortLabel == 'Order') sort('Order');
  }

  String? _profile;
  int _epoch = 0, _inputsRevision = 0;
  bool _disposed = false, reading = false, stale = false, inspecting = false;
  PluginSnapshot? state;
  String? problem;
  bool get connected => _client != null && _profile != null;
  void attach(
    BethesdaClient? client,
    String? profile, {
    PluginOrderClient? orders,
  }) {
    if (identical(client, _client) &&
        identical(orders, _orders) &&
        profile == _profile) {
      return;
    }
    ++_epoch;
    _client = client;
    _orders = orders;
    order = null;
    writing = false;
    _settings = {};
    _positions = {};
    _profile = profile;
    rows.clear();
    state = null;
    problem = null;
    reading = false;
    stale = false;
    inspecting = false;
    notifyListeners();
  }

  void invalidate() {
    ++_inputsRevision;
    if (state == null) return;
    stale = true;
    notifyListeners();
  }

  void select(PluginEntry row) {
    rows.select(row.name);
    notifyListeners();
  }

  void inspect() {
    inspecting = true;
    notifyListeners();
  }

  void closeInspector() {
    inspecting = false;
    notifyListeners();
  }

  Future<void> scan() async {
    final client = _client, profile = _profile;
    if (client == null || profile == null || reading || writing) return;
    final epoch = _epoch, inputsRevision = _inputsRevision;
    reading = true;
    problem = null;
    notifyListeners();
    try {
      final value = await client.scan(profile);
      if (_disposed || epoch != _epoch) return;
      state = value;
      stale = value.stale || inputsRevision != _inputsRevision;
      final names = value.entries.map((r) => r.name).toSet();
      rows.apply(
        upserts: value.entries,
        removed: rows.ids.where((id) => !names.contains(id)).toList(),
      );
      if (_orders != null) {
        final current = await _orders!.read(
          value.workspaceId,
          value.profileId,
          value.id,
        );
        if (_disposed || epoch != _epoch) return;
        _setOrder(current);
      }
      if (rows.selected == null && value.entries.isNotEmpty) {
        rows.select(value.entries.first.name);
      }
    } on ProfileDataProblem catch (error) {
      if (!_disposed && epoch == _epoch) {
        stale = true;
        problem = error.detail;
      }
    } on FilePlanException catch (error) {
      if (!_disposed && epoch == _epoch) {
        stale = state != null;
        problem = error.detail;
      }
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        stale = state != null;
        problem = 'The plugin scan could not finish. Try again.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        reading = false;
        notifyListeners();
      }
    }
  }

  bool _validating = false;
  Future<void> validate() async {
    final client = _client, snapshot = state, epoch = _epoch;
    if (client == null || snapshot == null || _validating || reading) return;
    _validating = true;
    try {
      final current = await client.read(snapshot.id);
      if (!_disposed && epoch == _epoch && state?.id == snapshot.id) {
        stale = stale || current.stale;
        notifyListeners();
      }
    } on FilePlanException catch (error) {
      if (!_disposed && epoch == _epoch) {
        stale = true;
        problem = error.detail;
        notifyListeners();
      }
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        stale = true;
        problem = 'The plugin scan could not be checked. Refresh to try again.';
        notifyListeners();
      }
    } finally {
      _validating = false;
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
