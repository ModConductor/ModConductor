import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final engine = Platform.environment['MC_ENGINE_PATH'];
  final fixture = Platform.environment['MC_NATIVE_FIXTURE'];
  test(
    'authenticated file snapshots retain pins, page lineage and one atomic visibility result',
    () async {
      final area = await Directory.systemTemp.createTemp('mc-file-plans-');
      final root = await Directory('${area.path}/root').create();
      final state = await Directory('${area.path}/state').create();
      final inputs = '${area.path}/inputs';
      final prepared = await Process.run(fixture!, ['--proton-files', inputs]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      final game =
          '$inputs/Second library/steamapps/common/Skyrim Special Edition';
      await File('$game/Data/shared.txt').writeAsString('Game folder');
      var child = await NativeChild.start(engine!, state);
      final workspace = newOperationId(),
          profile = newOperationId(),
          mod = newOperationId(),
          version = newOperationId();
      try {
        await child.workspaces().create(workspace, 'Files', root.path);
        await child.workspaces().createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        final folder = await Directory('${root.path}/source/branch')
            .create(recursive: true);
        await File('${root.path}/source/shared.txt').writeAsString('Mod copy');
        for (var i = 0; i < 70; i++) {
          await File('${folder.path}/file-${i.toString().padLeft(3, '0')}.txt')
              .writeAsString('$i');
        }
        final registered = await child.modLibrary().register(
          workspace,
          mod,
          const ModMetadata(name: 'Textures'),
          const DirectoryMod(ModKind.regular, ['source']),
        );
        await child.modLibrary().publish(mod, registered.revision, version);
        final inventory = await child.modOrganization().query(
          profile,
          const ModQuery(),
        );
        await child.profileMods().enable(profile, inventory.selectionRevision, [
          mod,
        ], true);
        await child.gameContexts().save(
          workspace,
          0,
          game,
          proton: Platform.isLinux
              ? ProtonSelection(
                  appId: 489830,
                  association: SteamProtonAssociation(
                    '$inputs/Steam',
                    '$inputs/Second library',
                  ),
                  compatData:
                      '$inputs/Second library/steamapps/compatdata/489830',
                  runtimeDirectory:
                      '$inputs/Steam/compatibilitytools.d/Custom Ω Proton',
                  toolId: 'fixture_tool',
                )
              : null,
        );
        await expectLater(
          child.filePlans(authenticate: false).open(profile),
          throwsA(
            isA<GrpcError>().having(
              (e) => e.code,
              'authentication',
              StatusCode.unauthenticated,
            ),
          ),
        );
        final files = child.filePlans();
        expect((await files.open(profile)).loaded, isFalse);
        final events = await files.acquire(profile, refresh: true).toList();
        final loaded = events.whereType<FilePlanLoaded>().single.state;
        expect(loaded.loaded, isTrue);
        expect(loaded.problems, isEmpty);
        final copy = ManagedFileCopy(mod, version, ['shared.txt']);
        final inspected = await files.inspectCopy(loaded.id, copy);
        expect(inspected.focusedCopy!.copy, copy);
        expect(inspected.focusedCopy!.winner, isTrue);
        final first = await files.children(loaded.id, parent: ['branch']);
        expect(first.next, isNotNull);
        final results = await Future.wait([
          for (var i = 0; i < 2; i++)
            files
                .change(loaded.id, copy, hidden: true)
                .then<Object>((v) => v, onError: (Object e) => e),
        ]);
        final changed = results.whereType<FileVisibilityChange>().single;
        expect(
          results.whereType<FilePlanException>().single.failure,
          anyOf(FilePlanFailure.stale, FilePlanFailure.busy),
        );
        expect(changed.state.fingerprint, isNot(loaded.fingerprint));
        final next = await files.children(
          changed.state.id,
          parent: ['branch'],
          cursor: first.next,
        );
        expect(next.state.id, changed.state.id);
        expect(
          next.nodes
              .map((row) => row.path.join('/'))
              .toSet()
              .intersection(
                first.nodes.map((row) => row.path.join('/')).toSet(),
              ),
          isEmpty,
        );
        await expectLater(
          files.children(
            changed.state.id,
            parent: ['branch'],
            filter: 'file-001',
            cursor: first.next,
          ),
          throwsA(
            isA<FilePlanException>().having(
              (e) => e.failure,
              'stale cursor',
              FilePlanFailure.stale,
            ),
          ),
        );
        final fallback = await files.inspect(changed.state.id, ['shared.txt']);
        expect(fallback.copies.singleWhere((row) => row.winner).copy, isNull);
        final audit = await files.history(changed.state.id, copy);
        expect(audit.changes.single.copy, copy);
        expect(audit.changes.single.beforeHidden, isFalse);
        expect(audit.changes.single.hidden, isTrue);
        expect(
          await File('${root.path}/source/shared.txt').readAsString(),
          'Mod copy',
        );
        await child.close();
        child = await NativeChild.start(engine, state);
        final reopened = await child.filePlans().open(profile);
        expect(reopened.loaded, isFalse);
        final historical = await child.filePlans().inspectCopy(
          reopened.id,
          copy,
        );
        expect(historical.focusedCopy!.hidden, isTrue);
        expect(historical.focusedCopy!.canUnhide, isTrue);
        expect(
          (await child.filePlans().history(
            reopened.id,
            copy,
          )).changes.single.id,
          audit.changes.single.id,
        );
      } finally {
        await child.close();
        await area.delete(recursive: true);
      }
    },
    skip: engine == null || fixture == null
        ? 'Set MC_ENGINE_PATH and MC_NATIVE_FIXTURE to published native tools.'
        : false,
  );
  test(
    'valid large source pages and multibyte filters pass the authenticated file service',
    () async {
      final area = await Directory.systemTemp.createTemp('mc-file-envelope-');
      final root = await Directory('${area.path}/root').create();
      final state = await Directory('${area.path}/state').create();
      final child = await NativeChild.start(engine!, state);
      final workspace = newOperationId(), profile = newOperationId();
      final copies = <ManagedFileCopy>{};
      final path = ['界' * 50, '路' * 50, 'copy.txt'];
      try {
        await child.workspaces().create(workspace, 'File sources', root.path);
        await child.workspaces().createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        for (var index = 0; index < 30; index++) {
          final mod = newOperationId(), version = newOperationId();
          final source = 'source$index';
          final folder = await Directory(
            '${root.path}/$source/${path.take(2).join('/')}',
          ).create(recursive: true);
          await File('${folder.path}/${path.last}')
              .writeAsString('Owned fixture payload');
          final registered = await child.modLibrary().register(
            workspace,
            mod,
            ModMetadata(name: '${'名' * 250}$index', version: '版' * 256),
            DirectoryMod(ModKind.regular, [source]),
          );
          await child.modLibrary().publish(mod, registered.revision, version);
          copies.add(ManagedFileCopy(mod, version, path));
        }
        final inventory = await child.modOrganization().query(
          profile,
          const ModQuery(),
        );
        await child.profileMods().enable(
          profile,
          inventory.selectionRevision,
          copies.map((copy) => copy.modId),
          true,
        );
        final files = child.filePlans();
        final opened = await files.open(profile);
        final inspected = await files.inspect(opened.id, path);
        expect(inspected.copies.map((row) => row.copy).toSet(), copies);
        expect(
          inspected.copies.every(
            (row) => row.versionLabel == '版' * 256 && !row.hidden,
          ),
          isTrue,
        );
        final byteFloor = inspected.copies.fold<int>(
          0,
          (sum, row) =>
              sum +
              utf8.encode(row.name).length +
              utf8.encode(row.versionLabel).length +
              utf8.encode(row.sha256).length +
              utf8.encode(row.copy!.modId).length +
              utf8.encode(row.copy!.versionId).length +
              2 * utf8.encode(row.sourcePath.join('/')).length,
        );
        stdout.writeln(
          'Authenticated source-page UTF-8 field bytes (excluding protobuf overhead): $byteFloor',
        );
        final filtered = await files.children(opened.id, filter: '界' * 2048);
        expect(filtered.nodes, isEmpty);
        expect(filtered.state.id, opened.id);
        expect(
          (await files.inspect(
            opened.id,
            path,
          )).copies.map((row) => row.copy).toSet(),
          copies,
        );
      } finally {
        await child.close();
        await area.delete(recursive: true);
      }
    },
    skip: engine == null
        ? 'Set MC_ENGINE_PATH to the published native engine.'
        : false,
  );
}
