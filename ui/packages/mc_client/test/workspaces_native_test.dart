import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final executable = Platform.environment['MC_ENGINE_PATH'];
  late Directory fixture;
  late Directory state;
  late Directory root;
  final children = <NativeChild>[];
  Future<NativeChild> start() async {
    final child = await NativeChild.start(executable!, state);
    children.add(child);
    return child;
  }

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('mc-workspaces-wire-');
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
  group(
    'native workspace wire',
    skip: executable == null
        ? 'Set MC_ENGINE_PATH to a published NativeAOT engine.'
        : false,
    () {
      test('name-only concurrent creation uses stable distinct owned roots', () async {
        final client = (await start()).workspaces();
        final firstId = newOperationId(), secondId = newOperationId();
        final created = await Future.wait([
          client.create(firstId, 'Same name'),
          client.create(secondId, 'Same name'),
        ]);
        expect(
          created.map((value) => value.workspace.path).toSet(),
          hasLength(2),
        );
        expect(created.map((value) => value.workspace.path).toSet(), {
          '${state.path}${Platform.pathSeparator}workspaces${Platform.pathSeparator}$firstId',
          '${state.path}${Platform.pathSeparator}workspaces${Platform.pathSeparator}$secondId',
        });
        for (final page in created) {
          expect(Directory(page.workspace.path).existsSync(), isTrue);
          expect(page.workspace.pendingRoot, isNull);
        }
      });

      test('profile lifecycle and explicit folder reopen preserve selection independently of runtime results', () async {
        final child = await start();
        final client = child.workspaces();
        final id = newOperationId();
        final initial = await client.create(id, 'Weekend', root.path);
        expect(initial.workspace.pendingRoot, isNull);
        expect(
          (await client.create(id, 'Weekend', root.path)).workspace.revision,
          0,
        );
        final first = ProfileInfo(newOperationId(), 'Everyday');
        final copy = ProfileInfo(newOperationId(), 'Everyday copy');
        final created = await client.createProfile(id, 0, first);
        final cloned = await client.cloneProfile(
          id,
          created.workspace.revision,
          first.id,
          copy,
        );
        expect(cloned.workspace.selectedProfile!.id, first.id);
        final renamed = await client.renameProfile(
          id,
          cloned.workspace.revision,
          ProfileInfo(first.id, 'Daily'),
        );
        expect(renamed.workspace.selectedProfile!.name, 'Daily');
        await expectLater(
          client.deleteProfile(id, renamed.workspace.revision, first.id),
          throwsA(
            isA<WorkspaceException>().having(
              (e) => e.fault,
              'fault',
              WorkspaceFault.selectedProfile,
            ),
          ),
        );
        await expectLater(
          client.renameProfile(
            id,
            cloned.workspace.revision,
            ProfileInfo(first.id, 'Stale'),
          ),
          throwsA(
            isA<WorkspaceException>().having(
              (e) => e.fault,
              'fault',
              WorkspaceFault.staleRevision,
            ),
          ),
        );
        final selected = await client.selectProfile(
          id,
          renamed.workspace.revision,
          copy.id,
        );
        final deleted = await client.deleteProfile(
          id,
          selected.workspace.revision,
          first.id,
        );
        expect(deleted.workspace.revision, 5);
        expect((await child.operations().check()).runtime.nativeAot, isTrue);
        expect((await client.read(id)).workspace.revision, 5);
        await child.close();
        final restarted = await start();
        final reopened = await restarted.workspaces().open(root.path);
        expect(reopened.workspace.id, id);
        expect(reopened.workspace.selectedProfile!.id, copy.id);
        expect(reopened.profiles.map((profile) => profile.id), [copy.id]);
        expect(reopened.profiles.single.name, copy.name);
        expect((await restarted.operations().state()).revision, 1);
      });

      test('workspace RPC authentication rejects missing and wrong capabilities before a file effect', () async {
        final child = await start();
        for (final client in [
          child.workspaces(authenticate: false),
          child.workspaces(token: 'wrong'),
        ]) {
          await expectLater(
            client.create(newOperationId(), 'Unauthorized', root.path),
            throwsA(
              isA<GrpcError>().having(
                (e) => e.code,
                'status',
                StatusCode.unauthenticated,
              ),
            ),
          );
        }
        expect(await root.list().toList(), isEmpty);
        expect((await child.workspaces().recent()).workspaces, isEmpty);
      });

      test('profile cursors cover all rows and preserve a selection outside the first page', () async {
        final client = (await start()).workspaces();
        final id = newOperationId();
        await client.create(id, 'Many profiles', root.path);
        for (var i = 1; i <= 40; i++) {
          await client.createProfile(
            id,
            i - 1,
            ProfileInfo(i.toRadixString(16).padLeft(32, '0'), 'Profile $i'),
          );
        }
        final last = 40.toRadixString(16).padLeft(32, '0');
        await client.selectProfile(id, 40, last);
        final first = await client.read(id);
        final second = await client.read(id, after: first.nextProfile);
        expect(first.profiles.length, 32);
        expect(second.profiles.length, 8);
        expect(second.nextProfile, isNull);
        expect(
          {
            ...first.profiles.map((p) => p.id),
            ...second.profiles.map((p) => p.id),
          }.length,
          40,
        );
        expect(first.workspace.selectedProfile!.id, last);
        expect(first.profiles.any((p) => p.id == last), isFalse);
        final otherRoot = await Directory('${fixture.path}/other').create();
        final other = await client.create(
          newOperationId(),
          'Other',
          otherRoot.path,
        );
        await expectLater(
          client.deleteProfile(other.workspace.id, 0, last),
          throwsA(
            isA<WorkspaceException>().having(
              (e) => e.fault,
              'fault',
              WorkspaceFault.notFound,
            ),
          ),
        );
        expect((await client.read(id)).workspace.selectedProfile!.id, last);
      });

      test('an unregistered folder and a substituted registered root fail without adopting files', () async {
        final client = (await start()).workspaces();
        final id = newOperationId();
        await client.create(id, 'Identity', root.path);
        final foreign = await Directory('${fixture.path}/foreign').create();
        await File('${foreign.path}/keep.txt').writeAsString('foreign');
        await expectLater(
          client.open(foreign.path),
          throwsA(
            isA<WorkspaceException>().having(
              (e) => e.fault,
              'fault',
              WorkspaceFault.invalidRoot,
            ),
          ),
        );
        await root.rename('${root.path}-original');
        await root.create();
        await File('${root.path}/keep.txt').writeAsString('replacement');
        await expectLater(client.read(id), throwsA(isA<WorkspaceException>()));
        expect(
          await File('${root.path}/keep.txt').readAsString(),
          'replacement',
        );
        expect((await root.list().toList()).length, 1);
        expect(
          await File('${foreign.path}/keep.txt').readAsString(),
          'foreign',
        );
      });
    },
  );
}
