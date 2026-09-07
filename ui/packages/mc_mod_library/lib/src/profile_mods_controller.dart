import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

typedef ModRowId = ({String modId});

class ProfileModsController extends ChangeNotifier {
  final model = McCollectionModel<ModRowId, ProfileMod>(
    idOf: (row) => (modId: row.mod.id),
    labelOf: (row) => row.mod.metadata.name,
  );
  ProfileModsClient? _client;
  String? _workspace, _profile, _nextMod, _pendingFocus;
  int _epoch = 0, _request = 0;
  bool _disposed = false;
  bool loading = false, changing = false, complete = false, stale = false;
  int? revision;
  int total = 0, enabledCount = 0;
  String? problem;
  bool get connected => _client != null && _profile != null;
  bool get byPriority => model.sortLabel == 'Priority' && !model.descending;
  bool get canLoad => connected && (!complete || stale);
  bool get canChange =>
      connected &&
      !changing &&
      !stale &&
      revision != null &&
      model.selectedIds.isNotEmpty &&
      model.selectedIds.every((id) => model[id] != null);
  bool get canToggle =>
      canChange &&
      model.selectedIds.every(
        (id) => model[id]!.selection is ManagedProfileMod,
      );
  bool get canMove =>
      canChange &&
      byPriority &&
      model.selectedIds.every(
        (id) => model[id]!.selection is! LockedProfileMod,
      );
  int get hiddenSelected =>
      model.selectedIds.where((id) => model.position(id) == null).length;

  ProfileModsController() {
    showPriority();
    model.addListener(_notify);
  }
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void showPriority() => model.sort(comparePriority, label: 'Priority');
  int comparePriority(ProfileMod a, ProfileMod b) {
    final left = a.selection.priority, right = b.selection.priority;
    if (left == null && right != null) return 1;
    if (right == null && left != null) return -1;
    return left == null ? a.mod.id.compareTo(b.mod.id) : left.compareTo(right!);
  }

  void attach(ProfileModsClient? client, String? workspace, String? profile) {
    if (identical(_client, client) &&
        _workspace == workspace &&
        _profile == profile) {
      return;
    }
    final newScope = _workspace != workspace || _profile != profile;
    _client = client;
    _workspace = workspace;
    _profile = profile;
    ++_epoch;
    ++_request;
    loading = changing = false;
    if (newScope) {
      revision = null;
      total = enabledCount = 0;
      _pendingFocus = null;
      complete = stale = false;
      problem = null;
      _nextMod = null;
      model.clear();
      showPriority();
    }
    if (connected) unawaited(load(refresh: true));
    _notify();
  }

  void mergeMetadata(Iterable<ModEntry> entries) {
    model.apply(
      upserts: entries
          .where(
            (mod) =>
                mod.workspaceId == _workspace &&
                model[(modId: mod.id)] != null &&
                model[(modId: mod.id)]!.mod.revision <= mod.revision,
          )
          .map((mod) => ProfileMod(mod, model[(modId: mod.id)]!.selection)),
    );
  }

  Future<bool> load({bool refresh = false, String? focusId}) async {
    final client = _client, profile = _profile;
    if (client == null || profile == null || loading || changing) return false;
    refresh = refresh || stale || revision == null;
    if (!refresh && complete) return true;
    _pendingFocus = focusId ?? _pendingFocus;
    final epoch = _epoch, request = ++_request;
    final cursor = refresh ? null : _nextMod,
        expected = refresh ? null : revision;
    loading = true;
    problem = null;
    _notify();
    bool current() => !_disposed && epoch == _epoch && request == _request;
    try {
      final page = await client.read(
        profile,
        afterModId: cursor,
        expectedRevision: expected,
      );
      if (!current()) return false;
      if ((expected != null && page.revision != expected) ||
          (page.nextModId != null &&
              cursor != null &&
              page.nextModId!.compareTo(cursor) <= 0)) {
        throw const FormatException(
          'The profile page changed. Reload its mods.',
        );
      }
      final entries = [...page.entries];
      final inspect = _pendingFocus ?? model.selectedId?.modId;
      if (refresh &&
          inspect != null &&
          !entries.any((row) => row.mod.id == inspect)) {
        final exact = await client.find(
          profile,
          inspect,
          expectedRevision: page.revision,
        );
        if (!current()) return false;
        if (exact.revision != page.revision) {
          throw const FormatException('The profile changed during reload.');
        }
        entries.add(exact.entry);
      }
      final merged = entries
          .where((row) => row.mod.workspaceId == _workspace)
          .map((row) {
            final old = model[(modId: row.mod.id)];
            return old != null && old.mod.revision > row.mod.revision
                ? ProfileMod(old.mod, row.selection)
                : row;
          })
          .toList();
      final present = merged.map((row) => (modId: row.mod.id)).toSet();
      final evicted = refresh && page.revision != revision
          ? model.ids.where((id) => !present.contains(id)).toList()
          : <ModRowId>[];
      revision = page.revision;
      total = page.total;
      enabledCount = page.enabledCount;
      _nextMod = page.nextModId;
      complete = _nextMod == null;
      stale = false;
      loading = false;
      model.apply(upserts: merged, evicted: evicted);
      if (_pendingFocus != null) {
        model.select((modId: _pendingFocus!));
        _pendingFocus = null;
      }
      _notify();
      return true;
    } on Exception catch (error) {
      if (current()) {
        stale =
            stale ||
            error is FormatException ||
            (error is LibraryException &&
                error.fault == LibraryFault.staleRevision);
        problem = error is LibraryException
            ? error.detail
            : 'Could not load the profile mods.';
      }
      return false;
    } finally {
      if (current() && loading) {
        loading = false;
        _notify();
      }
    }
  }

  void cancel() {
    ++_request;
    loading = false;
    _notify();
  }

  Future<bool> registered(String id) {
    cancel();
    stale = true;
    return load(refresh: true, focusId: id);
  }

  Future<void> enable(bool value, {String? onlyModId}) async {
    final client = _client, profile = _profile, expected = revision;
    if (client == null ||
        profile == null ||
        expected == null ||
        changing ||
        stale) {
      return;
    }
    final ids = onlyModId == null
        ? model.selectedIds.map((id) => id.modId).toList()
        : [onlyModId];
    await _change(() => client.enable(profile, expected, ids, value), expected);
  }

  Future<void> move(ProfileModMove direction) async {
    final client = _client, profile = _profile, expected = revision;
    if (client == null || profile == null || expected == null || !canMove) {
      return;
    }
    final ids = model.selectedIds.map((id) => id.modId).toList();
    await _change(
      () => client.move(profile, expected, ids, direction),
      expected,
    );
  }

  Future<void> _change(
    Future<ProfileModsDelta> Function() action,
    int expected,
  ) async {
    final epoch = _epoch;
    ++_request;
    loading = false;
    changing = true;
    problem = null;
    _notify();
    try {
      final delta = await action();
      if (_disposed || epoch != _epoch) return;
      if (delta.revision != expected + 1) {
        throw const FormatException('The profile revision changed.');
      }
      final upserts = <ProfileMod>[];
      for (final selection in delta.changed) {
        final row = model[(modId: selection.modId)];
        if (row != null) upserts.add(ProfileMod(row.mod, selection));
      }
      revision = delta.revision;
      enabledCount = delta.enabledCount;
      changing = false;
      model.apply(upserts: upserts);
      if (upserts.isEmpty) _notify();
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        stale =
            error is FormatException ||
            (error is LibraryException &&
                error.fault == LibraryFault.staleRevision);
        problem = error is LibraryException
            ? error.detail
            : 'Could not save the profile change. Reload its mods.';
        // A lost reply can follow a committed command. Reload before issuing another write.
        if (error is! LibraryException) stale = true;
      }
    } finally {
      if (!_disposed && epoch == _epoch && changing) {
        changing = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    model.removeListener(_notify);
    model.dispose();
    super.dispose();
  }
}
