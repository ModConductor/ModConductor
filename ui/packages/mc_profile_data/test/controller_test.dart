import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_profile_data/mc_profile_data.dart';

ProfileDataState state(String profile) => ProfileDataState(
  reference: ProfileDataRef(
    workspaceId: 'workspace',
    profileId: profile,
    contextId: 'context',
    revision: 1,
  ),
  options: const ProfileDataOptions(settings: false, saves: false),
  settingsPath: '',
  savesPath: '',
  settingsFiles: 0,
  saveFiles: 0,
);

class Client implements ProfileDataClient {
  final reads = <String, Completer<ProfileDataState>>{};
  final cancelled = Completer<void>();
  late final events = StreamController<ProfileDataEvent>(
    onCancel: () => cancelled.future,
  );
  @override
  Future<ProfileDataState> read(String workspaceId, String profileId) =>
      reads.putIfAbsent(profileId, Completer<ProfileDataState>.new).future;
  @override
  Stream<ProfileDataEvent> edit(
    String id,
    ProfileDataRef expected,
    ProfileDataOptions options, {
    required InitialProfileSaves initialSaves,
    required DisabledProfileFiles disabledFiles,
  }) => events.stream;
  @override
  Stream<ProfileDataEvent> restore(String id, ProfileDataRef expected) =>
      throw UnimplementedError();
  @override
  Stream<ProfileDataEvent> resume(String workspaceId, String id) =>
      throw UnimplementedError();
  @override
  Future<ProfileSavePage> saveFiles(
    String workspaceId,
    String profileId,
    List<String> path, {
    String? after,
  }) => throw UnimplementedError();
  @override
  Future<ProfileSaveGroupPage> saveGroups(
    String workspaceId,
    String profileId,
    ProfileSaveSource source, {
    String? after,
  }) => throw UnimplementedError();
  @override
  Future<ProfileSaveInspection> inspectSave(
    String workspaceId,
    String profileId,
    ProfileSaveSource source,
    String name, {
    String? headersId,
  }) => throw UnimplementedError();
  @override
  Future<ProfileSaveActionPreview> previewSaveAction(
    ProfileDataRef expected,
    ProfileSaveAction action,
    List<String> names,
  ) => throw UnimplementedError();
  @override
  Stream<ProfileDataEvent> applySaveAction(
    String id,
    String previewId,
    ProfileDataRef expected,
  ) => throw UnimplementedError();
}

void main() {
  test('a delayed read and cancellation from the previous profile cannot clear the new profile', () async {
    final client = Client(), controller = ProfileDataController();
    controller.attach(client, 'workspace', 'old', available: true);
    controller.attach(client, 'workspace', 'first', available: true);
    client.reads['first']!.complete(state('first'));
    await Future<void>.delayed(Duration.zero);
    client.reads['old']!.complete(state('old'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.state!.reference.profileId, 'first');
    final edit = controller.edit(
      const ProfileDataOptions(settings: true, saves: true),
      InitialProfileSaves.empty,
      DisabledProfileFiles.keep,
    );
    client.events.add(const ProfileDataProgress(1, 100));
    await Future<void>.delayed(Duration.zero);
    final cancel = controller.cancel();
    controller.attach(client, 'workspace', 'second', available: true);
    client.reads['second']!.complete(state('second'));
    await Future<void>.delayed(Duration.zero);
    client.cancelled.complete();
    await cancel;
    await edit;
    expect(controller.state!.reference.profileId, 'second');
    expect(controller.needsRead, isFalse);
    expect(controller.problem, isNull);
    expect(controller.busy, isFalse);
    controller.dispose();
    await client.events.close();
  });
}
