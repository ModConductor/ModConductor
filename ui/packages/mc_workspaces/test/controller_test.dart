import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

WorkspacePage page(
  String id, {
  int revision = 0,
  String name = 'Everyday',
  String? next,
}) => WorkspacePage(
  WorkspaceInfo(
    id: id,
    name: 'Weekend',
    path: '/fixture/$id',
    revision: revision,
    selectedProfile: ProfileInfo('profile', name),
  ),
  [ProfileInfo('profile', name)],
  next,
);

class ScriptedClient extends Fake implements WorkspacesClient {
  Future<WorkspacePage> Function(String)? onOpen;
  Future<WorkspacePage> Function(String, String?)? onRead;
  Future<ProfileChange> Function(String, int, ProfileInfo)? onRename;
  @override
  Future<WorkspaceList> recent({String? after}) async =>
      const WorkspaceList([], null);
  @override
  Future<WorkspacePage> open(String path) => onOpen!(path);
  @override
  Future<WorkspacePage> read(String id, {String? after}) => onRead!(id, after);
  @override
  Future<ProfileChange> renameProfile(
    String workspace,
    int revision,
    ProfileInfo profile,
  ) => onRename!(workspace, revision, profile);
}

class CopyClient extends ScriptedClient implements ProfileChangesClient {
  final copy = StreamController<ProfileChangeEvent>();
  @override
  Stream<ProfileChangeEvent> cloneWithProgress(
    String workspace,
    int revision,
    String source,
    ProfileInfo target,
  ) => copy.stream;
  @override
  Stream<ProfileChangeEvent> deleteWithProgress(
    String workspace,
    int revision,
    String profile,
  ) => throw UnimplementedError();
  @override
  Stream<ProfileChangeEvent> resumeProfileEdit(
    String workspace,
    String actionId,
  ) => throw UnimplementedError();
}

void main() {
  test('cancelling a streamed clone keeps the selected profile and rejects late completion', () async {
    final client = CopyClient()..onOpen = (_) async => page('one');
    final controller = WorkspaceController()..attach(client);
    await controller.open('/fixture/one');
    final pending = controller.clone(controller.page!.profiles.single, 'Copy');
    client.copy.add(const ProfileCopyProgress(2, 65536));
    await Future<void>.delayed(Duration.zero);
    expect(controller.copyProgress!.bytes, 65536);
    await controller.cancelProfileChange();
    await pending;
    final late = page('one', revision: 1, name: 'Copy');
    client.copy.add(
      ProfileChangeComplete(
        ProfileChange(late.workspace, const ProfileInfo('copy', 'Copy'), null),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.workspace!.selectedProfile!.id, 'profile');
    expect(controller.page!.profiles.map((value) => value.id), ['profile']);
    expect(controller.activity, isNull);
    expect(controller.currentProblem, isNotNull);
    controller.dispose();
    await client.copy.close();
  });

  test(
    'an old connection completion cannot replace a newly opened workspace',
    () async {
      final delayed = Completer<WorkspacePage>();
      final old = ScriptedClient()..onOpen = (_) => delayed.future;
      final current = ScriptedClient()..onOpen = (_) async => page('new');
      final controller = WorkspaceController()..attach(old);
      addTearDown(controller.dispose);
      final pending = controller.open('/fixture/old');
      controller.attach(current);
      await controller.open('/fixture/new');
      delayed.complete(page('old'));
      await pending;
      expect(controller.workspace!.id, 'new');
      expect(controller.recent.any((value) => value.id == 'old'), isFalse);
    },
  );

  test('leaving a workspace does not cancel a pending edit or navigate back on completion', () async {
    final delayed = Completer<ProfileChange>();
    final client = ScriptedClient();
    client.onOpen = (_) async => page('one');
    client.onRename = (_, _, _) => delayed.future;
    final controller = WorkspaceController()..attach(client);
    addTearDown(controller.dispose);
    await controller.open('/fixture/one');
    final pending = controller.rename(
      controller.page!.profiles.single,
      'Renamed',
    );
    controller.close();
    await Future<void>.delayed(Duration.zero);
    final saved = page('one', revision: 1, name: 'Renamed');
    delayed.complete(
      ProfileChange(saved.workspace, saved.profiles.single, null),
    );
    await pending;
    expect(controller.showingWorkspace, isFalse);
    expect(controller.page!.profiles.single.name, 'Renamed');
    client.onOpen = (_) async => saved;
    await controller.open('/fixture/one');
    expect(controller.workspace!.revision, 1);
  });

  test(
    'a rejected stale edit keeps current data until an explicit refresh',
    () async {
      final client = ScriptedClient();
      client.onOpen = (_) async => page('one');
      client.onRename = (_, _, _) async => throw const WorkspaceException(
        WorkspaceFault.staleRevision,
        'Changed',
      );
      client.onRead = (_, _) async =>
          page('one', revision: 1, name: 'External');
      final controller = WorkspaceController()..attach(client);
      addTearDown(controller.dispose);
      await controller.open('/fixture/one');
      await controller.rename(controller.page!.profiles.single, 'Draft');
      expect(controller.page!.profiles.single.name, 'Everyday');
      expect(controller.currentProblem, isNotNull);
      await controller.refresh();
      expect(controller.page!.profiles.single.name, 'External');
      expect(controller.currentProblem, isNull);
    },
  );

  test(
    'pages from another revision cannot mix with the current loaded profiles',
    () async {
      final client = ScriptedClient();
      client.onOpen = (_) async => page('one', next: 'cursor');
      client.onRead = (_, _) async => page('one', revision: 1, name: 'Changed');
      final controller = WorkspaceController()..attach(client);
      addTearDown(controller.dispose);
      await controller.open('/fixture/one');
      await controller.moreProfiles();
      expect(controller.page!.workspace.revision, 0);
      expect(controller.page!.profiles.single.name, 'Everyday');
      expect(controller.currentProblem, isNotNull);
      await controller.refresh();
      expect(controller.page!.workspace.revision, 1);
    },
  );
  test('a delayed reopen cannot replace a newer profile change', () async {
    final delayedOpen = Completer<WorkspacePage>();
    final delayedEdit = Completer<ProfileChange>();
    final client = ScriptedClient();
    client.onOpen = (_) async => page('one');
    client.onRename = (_, _, _) => delayedEdit.future;
    final controller = WorkspaceController()..attach(client);
    addTearDown(controller.dispose);
    await controller.open('/fixture/one');
    final edit = controller.rename(controller.page!.profiles.single, 'Renamed');
    client.onOpen = (_) => delayedOpen.future;
    final reopen = controller.open('/fixture/one');
    final saved = page('one', revision: 1, name: 'Renamed');
    delayedEdit.complete(
      ProfileChange(saved.workspace, saved.profiles.single, null),
    );
    await edit;
    delayedOpen.complete(page('one'));
    await reopen;
    expect(controller.workspace!.revision, 1);
    expect(controller.page!.profiles.single.name, 'Renamed');
  });
}
