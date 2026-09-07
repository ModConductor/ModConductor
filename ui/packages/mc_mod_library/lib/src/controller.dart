import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

import 'profile_mods_controller.dart';
export 'profile_mods_controller.dart';

typedef FileRowId = ({String versionId, String path});

class SavedFileNode {
  SavedFileNode(String version, List<String> components, this.payload)
    : path = List.unmodifiable(components),
      id = (versionId: version, path: jsonEncode(components)),
      parent = components.length == 1
          ? null
          : (
              versionId: version,
              path: jsonEncode(components.sublist(0, components.length - 1)),
            );
  final FileRowId id;
  final FileRowId? parent;
  final List<String> path;
  final ModPayload? payload;
  String get name => path.last;
  bool get folder => payload == null;
}

class ModLibraryController extends ChangeNotifier {
  final inventory = ProfileModsController();
  McCollectionModel<ModRowId, OrganizedMod> get mods => inventory.model;
  ModEntry? get selected => mods.selected?.mod;
  final files = McCollectionModel<FileRowId, SavedFileNode>(
    idOf: (row) => row.id,
    labelOf: (row) => row.path.join('/'),
    parentOf: (row) => row.parent,
    isBranch: (row) => row.folder,
  );
  ModLibraryClient? _client;
  ModOrganizationClient? organization;
  String? get workspaceId => _workspace;
  String? _workspace, _profile;
  int _epoch = 0, _fileRequest = 0;
  bool _disposed = false;
  bool loadingFiles = false;
  bool filesComplete = false;
  bool canEdit = false;
  String? fileProblem, actionProblem, activity;
  int _nextFile = 0;
  String? selectedVersionId, _selectedMod, _pendingRegistration;
  int fileCount = 0;

  bool get connected => _client != null;
  bool get canLoadFiles =>
      connected && selectedVersionId != null && !filesComplete;
  bool can(ModAction action) =>
      canEdit &&
      activity == null &&
      (selected?.actions.contains(action) ?? false);

  ModLibraryController() {
    inventory.addListener(_inventoryChanged);
    files.sort((a, b) => a.name.compareTo(b.name));
  }

  void _inventoryChanged() {
    final row = mods.selected;
    if (_pendingRegistration != null &&
        row?.mod.id == _pendingRegistration &&
        !inventory.stale &&
        inventory.problem == null) {
      _pendingRegistration = null;
      actionProblem = null;
    }
    if (row != null && row.mod.id != _selectedMod) {
      select(row.entry);
    } else {
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void attach(
    ModLibraryClient? client,
    ProfileModsClient? selectionClient, {
    ModOrganizationClient? organizationClient,
    String? workspaceId,
    String? profileId,
    required bool editable,
  }) {
    organization = organizationClient;
    canEdit =
        editable &&
        client != null &&
        selectionClient != null &&
        profileId != null;
    inventory.attach(
      selectionClient,
      organizationClient,
      workspaceId,
      profileId,
    );
    if (identical(client, _client) &&
        workspaceId == _workspace &&
        profileId == _profile) {
      return;
    }
    final newScope = workspaceId != _workspace || profileId != _profile;
    _client = client;
    _workspace = workspaceId;
    _profile = profileId;
    ++_epoch;
    cancelFiles();
    activity = null;
    actionProblem = null;
    if (newScope) {
      _selectedMod = null;
      _pendingRegistration = null;
      _pin(null);
    }
    if (client != null && profileId != null) {
      if (selectedVersionId != null) unawaited(loadFiles());
    }
    _notify();
  }

  void select(ProfileMod value) {
    final row = value.mod;
    final changed = _selectedMod != row.id;
    _selectedMod = row.id;
    if (mods.focusedId != (modId: row.id)) mods.select((modId: row.id));
    if (changed ||
        (selectedVersionId == null && row.currentVersionId != null)) {
      _pin(row.currentVersionId);
      unawaited(loadFiles());
    }
    _notify();
  }

  void _pin(String? version) {
    cancelFiles();
    selectedVersionId = version;
    _nextFile = 0;
    fileCount = 0;
    filesComplete = false;
    fileProblem = null;
    files.clear();
  }

  void showLatestVersion() {
    _pin(selected?.currentVersionId);
    unawaited(loadFiles());
    _notify();
  }

  Future<void> loadFiles() async {
    final client = _client, version = selectedVersionId;
    if (client == null || version == null || loadingFiles || filesComplete) {
      return;
    }
    final epoch = _epoch, request = ++_fileRequest, offset = _nextFile;
    loadingFiles = true;
    fileProblem = null;
    _notify();
    try {
      final page = await client.version(version, offset: offset);
      if (_disposed ||
          epoch != _epoch ||
          request != _fileRequest ||
          selectedVersionId != version) {
        return;
      }
      if (page.id != version ||
          page.modId != selected?.id ||
          (page.nextOffset != null && page.nextOffset! <= offset)) {
        fileProblem = 'Could not load this saved version.';
        return;
      }
      final additions = <FileRowId, SavedFileNode>{};
      for (final entry in page.entries) {
        for (var length = 1; length <= entry.path.length; length++) {
          final node = SavedFileNode(
            version,
            entry.path.sublist(0, length),
            length == entry.path.length ? entry.payload : null,
          );
          if (files[node.id] == null && !additions.containsKey(node.id)) {
            additions[node.id] = node;
            if (!node.folder) fileCount++;
          }
        }
      }
      files.apply(upserts: additions.values);
      if (offset == 0) {
        for (final node in additions.values.where(
          (node) => node.folder && node.parent == null,
        )) {
          files.toggle(node.id);
        }
      }
      _nextFile = page.nextOffset ?? offset;
      filesComplete = page.nextOffset == null;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch && request == _fileRequest) {
        fileProblem = error is LibraryException
            ? error.detail
            : 'Could not load saved files.';
      }
    } finally {
      if (!_disposed && epoch == _epoch && request == _fileRequest) {
        loadingFiles = false;
        _notify();
      }
    }
  }

  void cancelFiles() {
    ++_fileRequest;
    loadingFiles = false;
    _notify();
  }

  Future<void> _action(
    String label,
    Future<ModEntry> Function(ModLibraryClient) run, {
    bool showVersion = false,
    bool registered = false,
  }) async {
    final client = _client;
    if (!canEdit || client == null || activity != null) return;
    final epoch = _epoch;
    activity = label;
    actionProblem = null;
    _notify();
    try {
      final row = await run(client);
      if (_disposed || epoch != _epoch) return;
      if (registered) {
        final loaded = await inventory.registered(row.id);
        if (_disposed || epoch != _epoch) return;
        if (!loaded) {
          _pendingRegistration = row.id;
          actionProblem = 'The mod folder was added. Reload its profile state.';
        } else {
          select(mods[(modId: row.id)]!.entry);
        }
      } else {
        inventory.mergeMetadata([row]);
      }
      if (showVersion && selected?.id == row.id) {
        _pin(row.currentVersionId);
        unawaited(loadFiles());
      }
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        actionProblem = error is LibraryException
            ? error.detail
            : '$label did not return a result. Refresh the mods.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        activity = null;
        _notify();
      }
    }
  }

  Future<void> addFolder(ModMetadata metadata, String path) {
    final workspace = _workspace;
    if (workspace == null) return Future.value();
    final id = newOperationId();
    return _action(
      'Add mod folder',
      (client) => client.register(
        workspace,
        id,
        metadata,
        NativeDirectoryMod(ModKind.regular, path),
      ),
      registered: true,
    );
  }

  Future<void> edit(ModEntry original, ModMetadata metadata) => _action(
    'Save mod details',
    (client) => client.edit(original.id, original.revision, metadata),
  );

  Future<void> saveVersion() {
    final original = selected;
    if (original == null || !can(ModAction.publish)) return Future.value();
    final version = newOperationId();
    return _action(
      'Save version',
      (client) => client.publish(original.id, original.revision, version),
      showVersion: true,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    inventory.removeListener(_inventoryChanged);
    inventory.dispose();
    files.dispose();
    super.dispose();
  }
}
