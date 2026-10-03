import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

import 'load_order_rows.dart';
export 'load_order_rows.dart';

part 'load_order_files.dart';
part 'load_order_layout.dart';

class LoadOrderController extends ChangeNotifier {
  final rows = McCollectionModel<String, LoadOrderRow>(
    idOf: (row) => row.id,
    labelOf: (row) => '${row.name} ${row.type}',
    parentOf: (row) => row.parent,
    isBranch: (row) => row.group,
  );
  ModOrganizationClient? _organization;
  ModLibraryClient? _library;
  ProfileModsClient? _selection;
  String? _profile;
  int _epoch = 0, _inputs = 0;
  int? revision;
  bool _disposed = false, _projecting = false, _layoutRead = false;
  bool reading = false, writing = false;
  String? problem;
  List<ProfileMod> _sources = [];
  List<PluginEntry> _plugins = [];
  bool _pluginsReady = false, _sourcesReady = false;
  List<String> _layout = [], _persistedLayout = [];
  bool _savingLayout = false;
  final Map<String, List<LoadOrderRow>> _files = {};
  final Set<String> _loading = {};
  final Map<String, String> _versions = {};
  Map<String, int> _positions = {};
  int position(String id) => (_positions[id] ?? -1) + 1;
  List<String> get layout => List.unmodifiable(_layout);
  Iterable<ProfileMod> get sources => _sources;
  Future<void> Function()? onChanged;
  bool get connected =>
      _organization != null &&
      _selection != null &&
      _library != null &&
      _profile != null;
  bool get canMove =>
      connected &&
      revision != null &&
      !reading &&
      !writing &&
      !_savingLayout &&
      problem == null &&
      rows.query.isEmpty &&
      rows.sortLabel == 'Order' &&
      !rows.descending;

  LoadOrderController() {
    rows.addListener(_expanded);
  }

  void attach(
    ModLibraryClient? library,
    ModOrganizationClient? organization,
    ProfileModsClient? selection,
    String? profile,
  ) {
    if (identical(library, _library) &&
        identical(organization, _organization) &&
        identical(selection, _selection) &&
        profile == _profile) {
      return;
    }
    ++_epoch;
    _library = library;
    _organization = organization;
    _selection = selection;
    _profile = profile;
    _sources = [];
    _plugins = [];
    _pluginsReady = false;
    _sourcesReady = false;
    _layout = [];
    _persistedLayout = [];
    _savingLayout = false;
    _files.clear();
    _loading.clear();
    _versions.clear();
    revision = null;
    reading = writing = _layoutRead = false;
    problem = null;
    rows.clear();
    if (connected) unawaited(read());
  }

  void invalidate() {
    ++_inputs;
    if (connected && !reading && !writing) unawaited(read());
  }

  Future<void> read() async {
    final organization = _organization,
        profile = _profile,
        epoch = _epoch,
        inputs = _inputs;
    if (organization == null || profile == null || reading || writing) return;
    reading = true;
    problem = null;
    notifyListeners();
    try {
      if (!_layoutRead) {
        final layout = await organization.loadOrderLayout(profile);
        if (_disposed || epoch != _epoch) return;
        _layout = layout;
        _persistedLayout = layout;
        _layoutRead = true;
      }
      ModQueryCursor? cursor;
      final sources = <ProfileMod>[];
      int? nextRevision;
      do {
        final page = await organization.query(
          profile,
          const ModQuery(),
          cursor: cursor,
        );
        if (_disposed || epoch != _epoch) return;
        sources.addAll(
          page.entries
              .map((row) => row.entry)
              .where(
                (entry) =>
                    entry.selection is ManagedProfileMod &&
                    entry.mod.currentVersionId != null,
              ),
        );
        nextRevision = page.selectionRevision;
        cursor = page.next;
      } while (cursor != null);
      sources.sort(
        (a, b) => a.selection.priority!.compareTo(b.selection.priority!),
      );
      _sources = sources;
      _sourcesReady = true;
      revision = nextRevision;
      final present = sources.map((source) => source.mod.id).toSet();
      _files.removeWhere((id, _) => !present.contains(id));
      _versions.removeWhere((id, _) => !present.contains(id));
      for (final source in sources) {
        if (_versions[source.mod.id] != source.mod.currentVersionId) {
          _files.remove(source.mod.id);
        }
        _versions[source.mod.id] = source.mod.currentVersionId!;
      }
      _project();
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error is LibraryException
            ? error.detail
            : 'Could not load the load order.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        reading = false;
        _rememberLayout();
        notifyListeners();
        if (inputs != _inputs) unawaited(read());
      }
    }
  }

  void syncPlugins(
    List<PluginEntry> plugins,
    List<String> names, {
    bool ready = true,
  }) {
    _pluginsReady = ready;
    final oldSources = _plugins
        .expand((plugin) => [plugin.winner, ...plugin.alternatives])
        .whereType<PluginSource>()
        .map((source) => '${source.modId}:${source.versionId}:${source.path}')
        .toSet();
    final newSources = plugins
        .expand((plugin) => [plugin.winner, ...plugin.alternatives])
        .whereType<PluginSource>()
        .map((source) => '${source.modId}:${source.versionId}:${source.path}')
        .toSet();
    if (!setEquals(oldSources, newSources)) _files.clear();
    final entries = {
      for (final plugin in plugins) plugin.name.toLowerCase(): plugin,
    };
    _plugins = [for (final name in names) ?entries[name.toLowerCase()]];
    _plugins.addAll(
      plugins.where(
        (plugin) => !names.any(
          (name) => name.toLowerCase() == plugin.name.toLowerCase(),
        ),
      ),
    );
    _project();
  }

  void _project() {
    if (_disposed) return;
    final plugins = _pluginsReady
        ? _plugins.map((plugin) => LoadOrderRow.pluginId(plugin.name)).toList()
        : _layout.where((id) => id.startsWith('plugin:')).toList();
    final files = _sourcesReady
        ? _sources
              .map((source) => LoadOrderRow.sourceId(source.mod.id))
              .toList()
        : _layout.where((id) => id.startsWith('files:')).toList();
    _layout = reconcileLoadOrder(_layout, plugins, files);
    _positions = {
      for (var index = 0; index < _layout.length; index++)
        _layout[index]: index,
    };
    final entries = [
      for (final plugin in _plugins)
        LoadOrderRow(
          id: LoadOrderRow.pluginId(plugin.name),
          name: plugin.name,
          type: plugin.kind,
          plugin: plugin,
        ),
      for (final source in _sources) ...[
        LoadOrderRow(
          id: LoadOrderRow.sourceId(source.mod.id),
          name: source.mod.metadata.name,
          type: 'Loose files',
          source: source,
        ),
        ...?_files[source.mod.id],
      ],
    ];
    final ids = entries.map((row) => row.id).toSet();
    _projecting = true;
    rows.apply(
      upserts: entries,
      removed: rows.ids.where((id) => !ids.contains(id)).toList(),
    );
    if (rows.sortLabel != 'Entry') {
      rows.sort(
        (a, b) => a.parent == null
            ? (_positions[a.id] ?? 0).compareTo(_positions[b.id] ?? 0)
            : a.name.compareTo(b.name),
        label: 'Order',
        descending: rows.descending,
      );
    }
    _projecting = false;
    _expanded();
    _rememberLayout();
    notifyListeners();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _expanded() {
    if (_projecting || _disposed) return;
    for (final source in _sources) {
      if (rows.expanded(LoadOrderRow.sourceId(source.mod.id)) &&
          !_files.containsKey(source.mod.id) &&
          !_loading.contains(source.mod.id)) {
        unawaited(_readFiles(source.mod));
      }
    }
    notifyListeners();
  }

  Future<void> move(
    ProfileModMove direction, {
    Future<bool> Function(List<String>, ProfileModMove)? movePlugins,
  }) async {
    final selected = rows.selectedIds
        .where((id) => _layout.contains(id))
        .toSet();
    if (!canMove || selected.isEmpty) return;
    final next = List<String>.of(_layout);
    final movedPlugins = <String>{}, movedFiles = <String>{};
    final up = direction == ProfileModMove.up;
    for (final index
        in up
            ? List.generate(next.length - 1, (i) => i + 1)
            : List.generate(next.length - 1, (i) => next.length - 2 - i)) {
      final other = up ? index - 1 : index + 1;
      if (selected.contains(next[index]) && !selected.contains(next[other])) {
        final row = next[index];
        if (row.startsWith('plugin:') && next[other].startsWith('plugin:')) {
          movedPlugins.add(row);
        } else if (row.startsWith('files:') &&
            next[other].startsWith('files:')) {
          movedFiles.add(row);
        }
        next[index] = next[other];
        next[other] = row;
      }
    }
    final pluginsChanged = movedPlugins.isNotEmpty,
        filesChanged = movedFiles.isNotEmpty;
    if (pluginsChanged && movePlugins == null) return;
    final epoch = _epoch,
        inputs = _inputs,
        organization = _organization!,
        selection = _selection!,
        profile = _profile!,
        expectedRevision = revision!,
        changed = onChanged;
    writing = true;
    problem = null;
    notifyListeners();
    try {
      if (pluginsChanged) {
        final names = _plugins
            .where(
              (plugin) =>
                  movedPlugins.contains(LoadOrderRow.pluginId(plugin.name)),
            )
            .map((plugin) => plugin.name)
            .toList();
        final applied = await movePlugins!(names, direction);
        if (_disposed || epoch != _epoch || !applied) return;
      }
      if (filesChanged) {
        final ids = _sources
            .where(
              (source) =>
                  movedFiles.contains(LoadOrderRow.sourceId(source.mod.id)),
            )
            .map((source) => source.mod.id)
            .toList();
        final result = await selection.move(
          profile,
          expectedRevision,
          ids,
          direction,
          fileSourcesOnly: true,
        );
        if (_disposed || epoch != _epoch) return;
        revision = result.revision;
      }
      if (_disposed || epoch != _epoch) return;
      await organization.saveLoadOrderLayout(profile, next);
      if (_disposed || epoch != _epoch) return;
      _layout = next;
      _persistedLayout = next;
      // Domain events can arrive during the save; re-read precedence before reconciling slots.
      writing = false;
      if (filesChanged) {
        await changed?.call();
        if (_disposed || epoch != _epoch) return;
      }
      if (filesChanged || inputs != _inputs) {
        await read();
      } else {
        _project();
      }
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error is LibraryException
            ? error.detail
            : 'Could not save the load order. Reload it before another move.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        writing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    rows.removeListener(_expanded);
    rows.dispose();
    super.dispose();
  }
}
