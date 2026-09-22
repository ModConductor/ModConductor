import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class WorkspaceController extends ChangeNotifier {
  WorkspacesClient? _client;
  int _epoch = 0;
  int _navigation = 0;
  bool _disposed = false;
  WorkspacePage? page;
  bool showingWorkspace = false;
  int archiveNavigation = 0;
  int gameNavigation = 0;
  int helpNavigation = 0;
  void showArchives() {
    ++archiveNavigation;
    _notify();
  }

  void showHelp() {
    ++helpNavigation;
    _notify();
  }

  void showGame() {
    ++gameNavigation;
    _notify();
  }

  List<WorkspaceInfo> recent = const [];
  String? nextWorkspace;
  String? problem;
  String? _problemWorkspace;
  final Map<String, String> _activities = {};
  ({String id, String name, String? path})? _creation;

  StreamSubscription<ProfileChangeEvent>? _profileChange;
  Completer<ProfileChange>? _profileResult;
  ProfileCopyProgress? copyProgress;
  bool get canCancelProfileChange => _profileChange != null;

  Future<ProfileChange> _profileEvents(Stream<ProfileChangeEvent> events) {
    final done = Completer<ProfileChange>();
    _profileResult = done;
    copyProgress = null;
    final epoch = _epoch;
    _profileChange = events.listen(
      (event) {
        if (_disposed || epoch != _epoch) return;
        switch (event) {
          case ProfileCopyProgress():
            copyProgress = event;
            _notify();
          case ProfileChangeComplete():
            if (!done.isCompleted) done.complete(event.change);
        }
      },
      onError: (Object error) {
        if (!done.isCompleted) done.completeError(error);
      },
      onDone: () {
        if (!done.isCompleted) {
          done.completeError(
            const WorkspaceException(
              WorkspaceFault.profileData,
              'The profile action did not return a result. Read Settings and saves to continue.',
            ),
          );
        }
      },
    );
    return done.future.whenComplete(() {
      if (identical(_profileResult, done)) {
        _profileChange = null;
        _profileResult = null;
        copyProgress = null;
      }
    });
  }

  Future<void> cancelProfileChange() async {
    final pending = _profileResult;
    final subscription = _profileChange;
    await subscription?.cancel();
    if (pending != null && !pending.isCompleted) {
      pending.completeError(
        const WorkspaceException(
          WorkspaceFault.profileData,
          'The profile action was cancelled. Read Settings and saves to see any remaining action.',
        ),
      );
    }
  }

  Future<void> resumeProfileChange(String actionId) =>
      _edit('Continue profile change', (client, current) {
        if (client is! ProfileChangesClient) {
          throw const WorkspaceException(
            WorkspaceFault.profileData,
            'Profile recovery is unavailable.',
          );
        }
        return _profileEvents(
          (client as ProfileChangesClient).resumeProfileEdit(
            current.id,
            actionId,
          ),
        );
      });

  bool get connected => _client != null;
  WorkspaceInfo? get workspace => showingWorkspace ? page?.workspace : null;
  String? get activity => _activities[workspace?.id ?? ''];
  String? get currentProblem =>
      _problemWorkspace == workspace?.id ? problem : null;
  bool get canEdit =>
      connected &&
      workspace != null &&
      activity == null &&
      workspace!.pendingRoot == null &&
      _creation?.id != workspace!.id;
  bool get needsCheck =>
      workspace?.pendingRoot != null ||
      (workspace != null && _creation?.id == workspace!.id);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void attach(WorkspacesClient? client) {
    if (identical(client, _client)) return;
    unawaited(cancelProfileChange());
    _client = client;
    ++_epoch;
    _activities.clear();
    if (client != null) {
      unawaited(loadRecent());
      if (showingWorkspace && page != null) unawaited(refresh());
    }
    _notify();
  }

  Future<T?> _run<T>(
    String? id,
    String label,
    Future<T> Function(WorkspacesClient) action,
    void Function(T) apply,
  ) async {
    final client = _client;
    if (client == null || _activities.containsKey(id ?? '')) return null;
    final epoch = _epoch;
    _activities[id ?? ''] = label;
    problem = null;
    _problemWorkspace = id;
    _notify();
    try {
      final result = await action(client);
      if (!_disposed && epoch == _epoch) apply(result);
      return result;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error is WorkspaceException
            ? error.detail
            : '$label did not return a result.';
        _problemWorkspace = id;
      }
      return null;
    } finally {
      if (!_disposed && epoch == _epoch) {
        _activities.remove(id ?? '');
        _notify();
      }
    }
  }

  void _remember(WorkspaceInfo value) {
    if (recent.any(
      (item) => item.id == value.id && item.revision > value.revision,
    )) {
      return;
    }
    recent = [value, ...recent.where((item) => item.id != value.id)];
  }

  Future<void> loadRecent({bool more = false}) async {
    final client = _client;
    if (client == null) return;
    final epoch = _epoch;
    try {
      final result = await client.recent(after: more ? nextWorkspace : null);
      if (_disposed || epoch != _epoch) return;
      final existing = more ? recent : <WorkspaceInfo>[];
      recent = [
        ...existing,
        ...result.workspaces.where(
          (item) => !existing.any((old) => old.id == item.id),
        ),
      ];
      nextWorkspace = result.nextWorkspace;
      if (_problemWorkspace == null) problem = null;
      _notify();
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch && !showingWorkspace) {
        problem = error is WorkspaceException
            ? error.detail
            : 'The workspace list is unavailable.';
        _problemWorkspace = null;
        _notify();
      }
    }
  }

  Future<void> create(String name, [String? path]) async {
    final id = newOperationId();
    _creation = (id: id, name: name, path: path);
    final navigation = ++_navigation;
    showingWorkspace = true;
    page = WorkspacePage(
      WorkspaceInfo(id: id, name: name, path: path ?? '', revision: 0),
      const [],
      null,
    );
    await _run(
      id,
      'Workspace creation',
      (client) => client.create(id, name, path),
      (value) {
        if (_creation?.id == id) _creation = null;
        _remember(value.workspace);
        if (_navigation == navigation) page = value;
      },
    );
  }

  Future<void> open(String path) async {
    final navigation = ++_navigation;
    await _run(null, 'Open workspace', (client) => client.open(path), (value) {
      _remember(value.workspace);
      if (_navigation == navigation) {
        if (page?.workspace.id != value.workspace.id ||
            page!.workspace.revision <= value.workspace.revision) {
          page = value;
        }
        showingWorkspace = true;
      }
    });
  }

  void close() {
    showingWorkspace = false;
    ++_navigation;
    _notify();
    unawaited(loadRecent());
  }

  Future<void> refresh() async {
    final id = workspace?.id;
    if (id == null) return;
    final navigation = _navigation;
    await _run(id, 'Workspace refresh', (client) => client.read(id), (value) {
      _remember(value.workspace);
      if (_navigation == navigation) {
        page = value;
        if (_creation?.id == id) _creation = null;
      }
    });
  }

  Future<void> moreProfiles() async {
    final current = page;
    if (current == null || current.nextProfile == null) return;
    final navigation = _navigation;
    await _run(
      current.workspace.id,
      'Load profiles',
      (client) => client.read(current.workspace.id, after: current.nextProfile),
      (value) {
        if (_navigation != navigation) return;
        if (value.workspace.revision != current.workspace.revision) {
          problem = 'The workspace changed. Refresh the profiles.';
          _problemWorkspace = current.workspace.id;
          return;
        }
        page = WorkspacePage(value.workspace, [
          ...current.profiles,
          ...value.profiles.where(
            (item) => !current.profiles.any((old) => old.id == item.id),
          ),
        ], value.nextProfile);
      },
    );
  }

  Future<void> check() async {
    final current = workspace;
    if (current == null) return;
    final pendingCreate = _creation?.id == current.id ? _creation : null;
    final navigation = _navigation;
    await _run<WorkspacePage>(
      current.id,
      'Workspace check',
      (client) async {
        WorkspacePage latest;
        try {
          latest = await client.read(current.id);
        } on WorkspaceException catch (error) {
          if (error.fault != WorkspaceFault.notFound || pendingCreate == null) {
            rethrow;
          }
          return client.create(
            pendingCreate.id,
            pendingCreate.name,
            pendingCreate.path,
          );
        }
        final issue = latest.workspace.pendingRoot;
        return issue == null
            ? latest
            : client.check(current.id, issue.revision);
      },
      (value) {
        if (_creation?.id == current.id) _creation = null;
        _remember(value.workspace);
        if (_navigation == navigation) page = value;
      },
    );
  }

  Future<ProfileChange?> _edit(
    String label,
    Future<ProfileChange> Function(WorkspacesClient, WorkspaceInfo) action,
  ) async {
    final current = workspace;
    if (current == null || !canEdit) return null;
    return _run(current.id, label, (client) => action(client, current), (
      value,
    ) {
      _remember(value.workspace);
      if (page?.workspace.id != current.id ||
          page!.workspace.revision > value.workspace.revision) {
        return;
      }
      final changed = value.changed;
      final profiles = page!.profiles
          .where(
            (profile) =>
                profile.id != value.deleted && profile.id != changed?.id,
          )
          .toList();
      if (changed != null) profiles.add(changed);
      profiles.sort((a, b) => a.id.compareTo(b.id));
      page = WorkspacePage(value.workspace, profiles, page!.nextProfile);
    });
  }

  Future<ProfileInfo?> createProfile(String name, {String? profileId}) async {
    final profile = ProfileInfo(profileId ?? newOperationId(), name);
    final change = await _edit('Profile creation: $name', (
      client,
      current,
    ) async {
      try {
        return await client.createProfile(
          current.id,
          current.revision,
          profile,
        );
      } on WorkspaceException {
        rethrow;
      } on Exception {
        var refreshed = await client.read(current.id);
        while (true) {
          final committed = refreshed.profiles
              .where((candidate) => candidate.id == profile.id)
              .firstOrNull;
          if (committed != null) {
            return ProfileChange(refreshed.workspace, committed, null);
          }
          final next = refreshed.nextProfile;
          if (next == null) break;
          refreshed = await client.read(current.id, after: next);
        }
        return client.createProfile(
          current.id,
          refreshed.workspace.revision,
          profile,
        );
      }
    });
    return change?.changed;
  }

  Future<void> clone(ProfileInfo source, String name) =>
      _edit('Profile clone: ${source.name}', (client, current) {
        final target = ProfileInfo(newOperationId(), name);
        return client is ProfileChangesClient
            ? _profileEvents(
                (client as ProfileChangesClient).cloneWithProgress(
                  current.id,
                  current.revision,
                  source.id,
                  target,
                ),
              )
            : client.cloneProfile(
                current.id,
                current.revision,
                source.id,
                target,
              );
      });
  Future<void> rename(ProfileInfo profile, String name) => _edit(
    'Profile rename: ${profile.name}',
    (client, current) => client.renameProfile(
      current.id,
      current.revision,
      ProfileInfo(profile.id, name),
    ),
  );
  Future<void> select(ProfileInfo profile) => _edit(
    'Profile selection: ${profile.name}',
    (client, current) =>
        client.selectProfile(current.id, current.revision, profile.id),
  );
  Future<void> delete(ProfileInfo profile) => _edit(
    'Profile deletion: ${profile.name}',
    (client, current) => client is ProfileChangesClient
        ? _profileEvents(
            (client as ProfileChangesClient).deleteWithProgress(
              current.id,
              current.revision,
              profile.id,
            ),
          )
        : client.deleteProfile(current.id, current.revision, profile.id),
  );

  @override
  void dispose() {
    unawaited(cancelProfileChange());
    _disposed = true;
    ++_epoch;
    super.dispose();
  }
}
