import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

import 'controller.dart';

class SortOrderRow {
  const SortOrderRow(
    this.name,
    this.current,
    this.proposed,
    this.reason,
    this.messages,
  );
  final String name, reason;
  final int current, proposed;
  final List<LootMessageView> messages;
}

class SortOrderController extends ChangeNotifier {
  final rows = McCollectionModel<String, SortOrderRow>(
    idOf: (row) => row.name,
    labelOf: (row) =>
        '${row.name} ${row.reason} ${row.messages.map((m) => m.text).join(' ')}',
  );
  LootClient? _client;
  PluginsController? _plugins;
  String? _profile;
  LootStateView? state;
  bool reading = false, writing = false, stale = false, inspecting = false;
  String? problem;
  int _epoch = 0;
  bool _disposed = false;

  LootProposalView? get proposal => state?.proposal;
  bool _sameReference(ProfileDataRef? left, ProfileDataRef right) =>
      left?.workspaceId == right.workspaceId &&
      left?.profileId == right.profileId &&
      left?.contextId == right.contextId &&
      left?.revision == right.revision;
  bool get canPreview =>
      _client != null &&
      _plugins?.order != null &&
      !reading &&
      !writing &&
      !_plugins!.stale &&
      _plugins!.order!.issues.isEmpty;
  bool get canApply =>
      proposal != null &&
      !stale &&
      !reading &&
      !writing &&
      _sameReference(_plugins?.order?.reference, proposal!.expected);

  void attach(LootClient? client, PluginsController plugins, String? profile) {
    if (identical(client, _client) &&
        identical(plugins, _plugins) &&
        profile == _profile) {
      return;
    }
    _plugins?.removeListener(_pluginsChanged);
    _client = client;
    _plugins = plugins..addListener(_pluginsChanged);
    _profile = profile;
    ++_epoch;
    state = null;
    problem = null;
    stale = false;
    inspecting = false;
    rows.clear();
    notifyListeners();
    if (client != null && profile != null) unawaited(read());
  }

  void _pluginsChanged() {
    final proposed = proposal;
    if (proposed != null &&
        (_plugins?.stale == true ||
            !_sameReference(_plugins?.order?.reference, proposed.expected))) {
      stale = true;
    }
    notifyListeners();
  }

  Future<void> read() async => _run(() => _client!.read(), requireClient: true);
  Future<void> preview() async {
    if (!canPreview) return;
    final order = _plugins!.order!;
    await _run(
      () => _client!.preview(
        order.reference.workspaceId,
        order.reference.profileId,
        order.headers.id,
      ),
    );
  }

  Future<void> refreshMetadata() async =>
      _run(() => _client!.refreshMetadata(), requireClient: true);

  Future<void> dismiss() async {
    final current = proposal;
    if (current == null || reading || writing) return;
    await _run(() => _client!.dismiss(current.id));
  }

  Future<void> apply() async {
    final current = proposal;
    if (!canApply || current == null) return;
    final epoch = _epoch;
    writing = true;
    problem = null;
    notifyListeners();
    try {
      await _client!.apply(current.id, current.expected, current.headersId);
      if (_disposed || epoch != _epoch) return;
      state = LootStateView(
        state!.capabilityId,
        state!.available,
        state!.reason,
        state!.metadata,
        null,
      );
      rows.clear();
      inspecting = false;
      await _plugins!.scan();
    } on LootFailure catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error.detail;
        stale = error.kind == LootFailureKind.stale;
      }
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        problem = 'The proposed order could not be saved. Refresh plugins and try again.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        writing = false;
        notifyListeners();
      }
    }
  }

  Future<void> _run(
    Future<LootStateView> Function() action, {
    bool requireClient = false,
  }) async {
    if ((requireClient && _client == null) ||
        reading ||
        writing ||
        _client == null) {
      return;
    }
    final epoch = _epoch;
    reading = true;
    problem = null;
    notifyListeners();
    try {
      _set(await action());
    } on LootFailure catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error.detail;
        stale = error.kind == LootFailureKind.stale;
      }
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        problem = 'The LOOT action could not finish.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        reading = false;
        notifyListeners();
      }
    }
  }

  void _set(LootStateView value) {
    final returned = value.proposal;
    final proposal = returned?.expected.profileId == _profile ? returned : null;
    state = LootStateView(
      value.capabilityId,
      value.available,
      value.reason,
      value.metadata,
      proposal,
    );
    stale = false;
    if (proposal == null) {
      rows.clear();
      return;
    }
    final current = {
      for (var i = 0; i < proposal.current.length; i++)
        proposal.current[i].toLowerCase(): i + 1,
    };
    final moves = {
      for (final move in proposal.moves) move.plugin.toLowerCase(): move,
    };
    final messages = <String, List<LootMessageView>>{};
    for (final message in proposal.messages) {
      if (message.plugin.isNotEmpty) {
        messages
            .putIfAbsent(message.plugin.toLowerCase(), () => [])
            .add(message);
      }
    }
    final next = <SortOrderRow>[];
    for (var i = 0; i < proposal.sorted.length; i++) {
      final name = proposal.sorted[i],
          key = name.toLowerCase(),
          move = moves[key];
      next.add(
        SortOrderRow(
          name,
          current[key] ?? i + 1,
          i + 1,
          move?.reason ?? 'Current relative order retained',
          List.unmodifiable(messages[key] ?? const []),
        ),
      );
    }
    rows.apply(upserts: next);
    rows.sort((a, b) => a.proposed.compareTo(b.proposed), label: 'Order');
    if (rows.selected == null && next.isNotEmpty) rows.select(next.first.name);
  }

  void select(SortOrderRow row) {
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

  @override
  void dispose() {
    _disposed = true;
    _plugins?.removeListener(_pluginsChanged);
    rows.dispose();
    super.dispose();
  }
}
