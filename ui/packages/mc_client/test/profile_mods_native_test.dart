import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final executable = Platform.environment['MC_ENGINE_PATH'];
  late Directory fixture, state, root;
  final children = <NativeChild>[];
  String id(int value) => value.toRadixString(16).padLeft(32, '0');
  Future<NativeChild> start() async {
    final child = await NativeChild.start(executable!, state);
    children.add(child);
    return child;
  }

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('mc-profile-mods-');
    state = await Directory('${fixture.path}/state').create();
    root = await Directory('${fixture.path}/root').create();
  });
  tearDown(() async {
    for (final child in children) {
      await child.close();
    }
    children.clear();
    await fixture.delete(recursive: true);
  });
  Future<List<ProfileMod>> all(ProfileModsClient client, String profile) async {
    final first = await client.read(profile);
    final rows = [...first.entries];
    var next = first.nextModId;
    while (next != null) {
      final page = await client.read(
        profile,
        afterModId: next,
        expectedRevision: first.revision,
      );
      rows.addAll(page.entries);
      next = page.nextModId;
    }
    return rows;
  }

  List<(String, int?, bool?)> values(List<ProfileMod> rows) {
    final ordered = [...rows]..sort((a, b) => a.mod.id.compareTo(b.mod.id));
    return [
      for (final row in ordered)
        (
          row.mod.id,
          row.selection.priority,
          row.selection is ManagedProfileMod
              ? (row.selection as ManagedProfileMod).enabled
              : null,
        ),
    ];
  }

  group(
    'native profile mods',
    skip: executable == null
        ? 'Set MC_ENGINE_PATH to a published NativeAOT engine.'
        : false,
    () {
      test('joined cursor rejects membership changes while exact lookup, atomic moves and restart preserve profile state', () async {
        var child = await start();
        final workspace = newOperationId(), profile = newOperationId();
        await child.workspaces().create(
          workspace,
          'Profile fixture',
          root.path,
        );
        await child.workspaces().createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        var client = child.profileMods();
        expect((await client.read(profile, expectedRevision: 0)).revision, 0);
        for (var i = 100; i < 135; i++) {
          final folder = 'mod-$i';
          await Directory('${root.path}/$folder').create();
          await child.modLibrary().register(
            workspace,
            id(i),
            ModMetadata(name: folder),
            DirectoryMod(ModKind.regular, [folder]),
          );
        }
        final before = await client.read(profile);
        expect(before.nextModId, isNotNull);
        await Directory('${root.path}/local').create();
        await child.modLibrary().register(
          workspace,
          id(1),
          const ModMetadata(name: 'Local'),
          const DirectoryMod(ModKind.unmanaged, ['local']),
        );
        await expectLater(
          client.read(
            profile,
            afterModId: before.nextModId,
            expectedRevision: before.revision,
          ),
          throwsA(
            isA<LibraryException>().having(
              (e) => e.fault,
              'fault',
              LibraryFault.staleRevision,
            ),
          ),
        );
        final latest = await client.read(profile);
        expect(
          (await client.find(
            profile,
            id(134),
            expectedRevision: latest.revision,
          )).entry.mod.id,
          id(134),
        );
        expect(
          (await client.find(
            profile,
            id(1),
            expectedRevision: latest.revision,
          )).entry.selection,
          isA<LockedProfileMod>(),
        );
        final moved = await client.move(profile, latest.revision, [
          id(106),
          id(103),
          id(102),
        ], ProfileModMove.up);
        final projection = {
          for (final row in await all(client, profile))
            row.mod.id: row.selection.priority,
        };
        expect(
          [
            for (final i in [100, 102, 103, 101, 104, 106, 105])
              projection[id(i)],
          ],
          [0, 1, 2, 3, 4, 5, 6],
        );
        expect(moved.revision, latest.revision + 1);
        final enabled = await client.enable(profile, moved.revision, [
          id(102),
          id(106),
        ], true);
        expect(enabled.enabledCount, 2);
        await expectLater(
          client.enable(profile, moved.revision, [id(100), id(101)], true),
          throwsA(
            isA<LibraryException>().having(
              (e) => e.fault,
              'fault',
              LibraryFault.staleRevision,
            ),
          ),
        );
        final saved = values(await all(client, profile));
        final workspaceState = await child.workspaces().read(workspace);
        final copy = newOperationId();
        await child.workspaces().cloneProfile(
          workspace,
          workspaceState.workspace.revision,
          profile,
          ProfileInfo(copy, 'Copy'),
        );
        expect(values(await all(client, copy)), saved);
        await child.close();
        children.remove(child);
        child = await start();
        client = child.profileMods();
        expect(values(await all(client, profile)), saved);
        expect((await client.read(profile)).revision, enabled.revision);
      });
      test('separator and locked-entry refusals leave whole batches unchanged and the new service enforces authentication', () async {
        final child = await start();
        final workspace = newOperationId(), profile = newOperationId();
        await child.workspaces().create(workspace, 'Constraints', root.path);
        await child.workspaces().createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        await Directory('${root.path}/source').create();
        await child.modLibrary().register(
          workspace,
          id(1),
          const ModMetadata(name: 'Managed'),
          const DirectoryMod(ModKind.regular, ['source']),
        );
        await child.modLibrary().register(
          workspace,
          id(2),
          const ModMetadata(name: 'Separator'),
          const SeparatorMod(),
        );
        await child.modLibrary().register(
          workspace,
          id(3),
          const ModMetadata(name: 'Automatic'),
          const DirectoryMod(ModKind.generatedOutput, ['source']),
        );
        final client = child.profileMods(),
            before = await child.profileMods().read(profile);
        await expectLater(
          client.enable(profile, before.revision, [id(1), id(2)], true),
          throwsA(
            isA<LibraryException>().having(
              (e) => e.fault,
              'fault',
              LibraryFault.unsupportedAction,
            ),
          ),
        );
        await expectLater(
          client.move(profile, before.revision, [
            id(1),
            id(3),
          ], ProfileModMove.up),
          throwsA(
            isA<LibraryException>().having(
              (e) => e.fault,
              'fault',
              LibraryFault.unsupportedAction,
            ),
          ),
        );
        final after = await client.read(profile);
        expect(values(after.entries), values(before.entries));
        expect(after.revision, before.revision);
        final moved = await client.move(profile, before.revision, [
          id(2),
        ], ProfileModMove.up);
        final separator = await client.find(
          profile,
          id(2),
          expectedRevision: moved.revision,
        );
        expect(separator.entry.selection, isA<OrderedProfileMod>());
        expect(separator.entry.selection.priority, 0);
        await expectLater(
          child.profileMods(authenticate: false).read(profile),
          throwsA(
            isA<GrpcError>().having(
              (e) => e.code,
              'code',
              StatusCode.unauthenticated,
            ),
          ),
        );
        expect((await client.read(profile)).revision, moved.revision);
      });
    },
  );
}
