import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

import 'mod_query_cache.dart';
export 'mod_query_cache.dart' show ModRowId;

class ProfileModsController extends ChangeNotifier {
  final _cache = ModQueryCache();
  McCollectionModel<ModRowId, OrganizedMod> get model => _cache.model;
  ProfileModsClient? _client;
  ModOrganizationClient? _organization;
  String? _workspace, _profile, _pendingFocus;
  ModQueryCursor? _next;
  ModQuery query = const ModQuery();
  int _epoch = 0, _request = 0;
  Timer? _debounce;
  bool _disposed = false, _publishing = false, _catalogueRefresh = false;
  bool loading = false, changing = false, complete = false, stale = false;
  int? revision, catalogueRevision;
  int total = 0,
      enabledCount = 0,
      matchingMods = 0,
      matchingSeparators = 0,
      matchingGroups = 0;
  String? problem;
  int get loaded => _cache.loaded;
  bool get connected =>
      _client != null && _organization != null && _profile != null;
  bool get byPriority =>
      query.view == OrganizationView.flat &&
      query.sort == OrganizationSort.priority;
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
    model.sort(comparePriority, label: 'Priority');
    model.addListener(_notify);
  }
  void _notify() {
    if (!_disposed && !_publishing) notifyListeners();
  }

  void showPriority() => setQuery(
    query.copyWith(
      view: OrganizationView.flat,
      sort: OrganizationSort.priority,
    ),
  );
  int comparePriority(OrganizedMod a, OrganizedMod b) =>
      _cache.comparePriority(a, b);
  void sort(String label) => setQuery(
    query.copyWith(
      sort: label == 'Name' ? OrganizationSort.name : OrganizationSort.priority,
    ),
  );
  void search(String value) {
    _debounce?.cancel();
    cancel();
    query = query.copyWith(text: value);
    stale = true;
    _notify();
    _debounce = Timer(
      const Duration(milliseconds: 200),
      () => unawaited(load(refresh: true)),
    );
  }

  void setQuery(ModQuery value) {
    _debounce?.cancel();
    cancel();
    query = value;
    stale = true;
    unawaited(load(refresh: true));
  }

  void attach(
    ProfileModsClient? client,
    ModOrganizationClient? organization,
    String? workspace,
    String? profile,
  ) {
    if (identical(_client, client) &&
        identical(_organization, organization) &&
        _workspace == workspace &&
        _profile == profile) {
      return;
    }
    final newScope = _workspace != workspace || _profile != profile;
    _client = client;
    _organization = organization;
    _workspace = workspace;
    _profile = profile;
    ++_epoch;
    ++_request;
    _debounce?.cancel();
    loading = changing = _catalogueRefresh = false;
    if (newScope) {
      revision = catalogueRevision = null;
      total = enabledCount = matchingMods = matchingSeparators =
          matchingGroups = 0;
      _pendingFocus = null;
      complete = stale = false;
      problem = null;
      _next = null;
      _cache.clear();
      query = const ModQuery();
    }
    if (connected) unawaited(load(refresh: true));
    _notify();
  }

  void mergeMetadata(Iterable<ModEntry> entries) {
    cancel();
    model.apply(
      upserts: entries
          .where(
            (mod) =>
                mod.workspaceId == _workspace &&
                model[(modId: mod.id)] != null &&
                model[(modId: mod.id)]!.mod.revision <= mod.revision,
          )
          .map((mod) {
            final old = model[(modId: mod.id)]!;
            return OrganizedMod(
              ProfileMod(mod, old.selection),
              old.groupId,
              groupSize: old.groupSize,
            );
          }),
    );
    if (connected) {
      stale = true;
      unawaited(load(refresh: true));
    }
  }

  Future<void> refreshCatalogue() async {
    _debounce?.cancel();
    ++_request;
    loading = false;
    stale = true;
    _catalogueRefresh = true;
    _notify();
    if (!changing) {
      _catalogueRefresh = false;
      await load(refresh: true);
    }
  }

  Future<bool> load({
    bool refresh = false,
    String? focusId,
    int? expectedSelection,
    List<ProfileModSelection> delta = const [],
  }) async {
    final client = _organization, profile = _profile;
    if (client == null ||
        profile == null ||
        loading ||
        (changing && expectedSelection == null)) {
      return false;
    }
    refresh = refresh || stale || revision == null;
    if (!refresh && complete) return true;
    _pendingFocus = focusId ?? _pendingFocus;
    final epoch = _epoch, request = ++_request;
    final cursor = refresh ? null : _next;
    final requested = query;
    loading = true;
    problem = null;
    _notify();
    bool current() => !_disposed && epoch == _epoch && request == _request;
    try {
      final page = await client.query(
        profile,
        requested,
        cursor: cursor,
        inspectedId: _pendingFocus ?? model.selectedId?.modId,
      );
      if (!current()) return false;
      if ((expectedSelection != null &&
              page.selectionRevision != expectedSelection) ||
          (cursor != null &&
              (page.catalogueRevision != cursor.catalogueRevision ||
                  page.selectionRevision != cursor.selectionRevision ||
                  page.queryIdentity != cursor.queryIdentity)) ||
          (page.next != null && page.next!.offset <= (cursor?.offset ?? 0))) {
        throw const FormatException('The mod query changed. Reload its mods.');
      }
      if ([
        ...page.entries,
        ...page.context,
        if (page.inspected != null) page.inspected!,
      ].any(
        (row) =>
            (model[(modId: row.mod.id)]?.mod.revision ?? -1) > row.mod.revision,
      )) {
        throw const FormatException('The mod metadata changed during reload.');
      }
      revision = page.selectionRevision;
      catalogueRevision = page.catalogueRevision;
      total = page.totalMods;
      enabledCount = page.enabledCount;
      matchingMods = page.matchingMods;
      matchingSeparators = page.matchingSeparators;
      matchingGroups = page.matchingGroups;
      _next = page.next;
      complete = _next == null;
      stale = false;
      loading = false;
      if (expectedSelection != null) changing = false;
      _publishing = true;
      _cache.accept(
        page,
        requested,
        refresh: refresh,
        offset: cursor?.offset ?? 0,
        delta: delta,
      );
      if (_pendingFocus != null) {
        model.select((modId: _pendingFocus!));
        _pendingFocus = null;
      }
      _publishing = false;
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
            : 'Could not load the mods.';
      }
      return false;
    } finally {
      _publishing = false;
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
      // Repeat only when a category edit invalidated the in-flight projection, retaining the accepted delta.
      bool refreshed;
      do {
        _catalogueRefresh = false;
        refreshed = await load(
          refresh: true,
          expectedSelection: delta.revision,
          delta: delta.changed,
        );
      } while (_catalogueRefresh && !_disposed && epoch == _epoch);
      if (!refreshed && !_disposed && epoch == _epoch) {
        stale = true;
        problem = 'The profile change was saved. Could not reload its mods.';
        _notify();
      }
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        stale =
            error is! LibraryException ||
            error.fault == LibraryFault.staleRevision;
        problem = error is LibraryException
            ? error.detail
            : 'Could not confirm the profile change. Reload its mods.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        final wasChanging = changing;
        changing = false;
        if (_catalogueRefresh) {
          _catalogueRefresh = false;
          final changeProblem = problem;
          if (await load(refresh: true) && changeProblem != null) {
            problem = changeProblem;
            _notify();
          }
        } else if (wasChanging) {
          _notify();
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    _debounce?.cancel();
    model.removeListener(_notify);
    model.dispose();
    super.dispose();
  }
}
