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
  Future<List<ProfileMod>> all(
    ModOrganizationClient client,
    String profile,
  ) async {
    final first = await client.query(profile, const ModQuery());
    final rows = first.entries.map((row) => row.entry).toList();
    var next = first.next;
    while (next != null) {
      final page = await client.query(profile, const ModQuery(), cursor: next);
      rows.addAll(page.entries.map((row) => row.entry));
      next = page.next;
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
        var inventory = child.modOrganization();
        expect(
          (await inventory.query(profile, const ModQuery())).selectionRevision,
          0,
        );
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
        final before = await inventory.query(profile, const ModQuery());
        expect(before.next, isNotNull);
        await Directory('${root.path}/local').create();
        await child.modLibrary().register(
          workspace,
          id(1),
          const ModMetadata(name: 'Local'),
          const DirectoryMod(ModKind.unmanaged, ['local']),
        );
        await expectLater(
          inventory.query(profile, const ModQuery(), cursor: before.next),
          throwsA(
            isA<LibraryException>().having(
              (e) => e.fault,
              'fault',
              LibraryFault.staleRevision,
            ),
          ),
        );
        final latest = await inventory.query(profile, const ModQuery());
        expect(
          (await inventory.query(
            profile,
            const ModQuery(),
            inspectedId: id(134),
          )).inspected!.entry.mod.id,
          id(134),
        );
        expect(
          (await inventory.query(
            profile,
            const ModQuery(),
            inspectedId: id(1),
          )).inspected!.entry.selection,
          isA<LockedProfileMod>(),
        );
        final moved = await client.move(profile, latest.selectionRevision, [
          id(106),
          id(103),
          id(102),
        ], ProfileModMove.up);
        final projection = {
          for (final row in await all(inventory, profile))
            row.mod.id: row.selection.priority,
        };
        expect(
          [
            for (final i in [100, 102, 103, 101, 104, 106, 105])
              projection[id(i)],
          ],
          [0, 1, 2, 3, 4, 5, 6],
        );
        expect(moved.revision, latest.selectionRevision + 1);
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
        final saved = values(await all(inventory, profile));
        final workspaceState = await child.workspaces().read(workspace);
        final copy = newOperationId();
        await child.workspaces().cloneProfile(
          workspace,
          workspaceState.workspace.revision,
          profile,
          ProfileInfo(copy, 'Copy'),
        );
        expect(values(await all(inventory, copy)), saved);
        await child.close();
        children.remove(child);
        child = await start();
        client = child.profileMods();
        inventory = child.modOrganization();
        expect(values(await all(inventory, profile)), saved);
        expect(
          (await inventory.query(profile, const ModQuery())).selectionRevision,
          enabled.revision,
        );
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
        final client = child.profileMods();
        final inventory = child.modOrganization();
        final before = await inventory.query(profile, const ModQuery());
        await expectLater(
          client.enable(profile, before.selectionRevision, [
            id(1),
            id(2),
          ], true),
          throwsA(
            isA<LibraryException>().having(
              (e) => e.fault,
              'fault',
              LibraryFault.unsupportedAction,
            ),
          ),
        );
        await expectLater(
          client.move(profile, before.selectionRevision, [
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
        final after = await inventory.query(profile, const ModQuery());
        expect(
          values(after.entries.map((row) => row.entry).toList()),
          values(before.entries.map((row) => row.entry).toList()),
        );
        expect(after.selectionRevision, before.selectionRevision);
        final moved = await client.move(profile, before.selectionRevision, [
          id(2),
        ], ProfileModMove.up);
        final separator = await inventory.query(
          profile,
          const ModQuery(),
          inspectedId: id(2),
        );
        expect(separator.inspected!.entry.selection, isA<OrderedProfileMod>());
        expect(separator.inspected!.entry.selection.priority, 0);
        await expectLater(
          child
              .modOrganization(authenticate: false)
              .query(profile, const ModQuery()),
          throwsA(
            isA<GrpcError>().having(
              (e) => e.code,
              'code',
              StatusCode.unauthenticated,
            ),
          ),
        );
        expect(
          (await inventory.query(profile, const ModQuery())).selectionRevision,
          moved.revision,
        );
      });
    },
  );
}
