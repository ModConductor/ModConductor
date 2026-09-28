import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

import 'package:mc_client/src/generated/modconductor/v1/mod_library.pbgrpc.dart'
    as wire;

void main() {
  final executable = Platform.environment['MC_ENGINE_PATH'];
  late Directory fixture, state, root, source;
  final children = <NativeChild>[];
  String childPath(String parent, String name) =>
      '$parent${Platform.pathSeparator}$name';
  Future<NativeChild> start() async {
    final child = await NativeChild.start(executable!, state);
    children.add(child);
    return child;
  }

  Future<(NativeChild, String, String)> workspace() async {
    final child = await start();
    final id = newOperationId(), profile = newOperationId();
    await child.workspaces().create(id, 'Library', root.path);
    await child.workspaces().createProfile(
      id,
      0,
      ProfileInfo(profile, 'Everyday'),
    );
    return (child, id, profile);
  }

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('mc-library-wire-');
    state = await Directory(childPath(fixture.path, 'state')).create();
    root = await Directory(childPath(fixture.path, 'root')).create();
    source = await Directory(childPath(root.path, 'source')).create();
  });
  tearDown(() async {
    for (final child in children) {
      await child.close();
    }
    children.clear();
    if (Platform.isWindows) {
      // Only this test's owned payloads; the application has no permission-reset command.
      final result = await Process.run('attrib', [
        '-R',
        childPath(root.path, '*.payload'),
        '/S',
      ]);
      if (result.exitCode != 0) {
        throw StateError('Fixture permission cleanup failed.');
      }
    }
    await fixture.delete(recursive: true);
  });
  Future<({List<ModEntry> entries, ModQueryCursor? next})> inventory(
    NativeChild child,
    String profile, {
    ModQueryCursor? cursor,
  }) async {
    final page = await child.modOrganization().query(
      profile,
      const ModQuery(),
      cursor: cursor,
    );
    return (
      entries: page.entries.map((row) => row.mod).toList(),
      next: page.next,
    );
  }

  group(
    'native mod library wire',
    skip: executable == null
        ? 'Set MC_ENGINE_PATH to a published NativeAOT engine.'
        : false,
    () {
      test('native folder choices retain original components and reject root or outside candidates without registration', () async {
        final (child, workspaceId, profile) = await workspace();
        final client = child.modLibrary();
        final component = Platform.isLinux ? r'native\folder' : 'native folder';
        final folder = await Directory(childPath(root.path, component))
            .create();
        await File(childPath(folder.path, 'payload.txt'))
            .writeAsString('unchanged');
        final entry = await client.register(
          workspaceId,
          newOperationId(),
          const ModMetadata(name: 'Native folder'),
          NativeDirectoryMod(ModKind.regular, folder.path),
        );
        expect(entry.sourcePath, [component]);
        final saved = await client.publish(
          entry.id,
          entry.revision,
          newOperationId(),
        );
        final version = await client.version(saved.currentVersionId!);
        expect(
          utf8.decode(
            await client.readPayload(
              version.id,
              version.entries.single.payload.id,
            ),
          ),
          'unchanged',
        );
        for (final invalid in [root.path, fixture.path, state.path]) {
          await expectLater(
            client.register(
              workspaceId,
              newOperationId(),
              const ModMetadata(name: 'Outside'),
              NativeDirectoryMod(ModKind.regular, invalid),
            ),
            throwsA(isA<LibraryException>()),
          );
        }
        expect((await inventory(child, profile)).entries.map((row) => row.id), [
          entry.id,
        ]);
        expect(
          await File(childPath(folder.path, 'payload.txt')).readAsString(),
          'unchanged',
        );
      });
      test('ambiguous native and logical registration rejects before any mod is stored', () async {
        final (child, workspaceId, profile) = await workspace();
        await expectLater(
          child.rawModLibrary().registerMod(
            wire.RegisterModRequest(
              workspaceId: workspaceId,
              modId: newOperationId(),
              metadata: wire.InventoryModMetadata(name: 'Ambiguous'),
              kind: wire.InventoryModKind.INVENTORY_MOD_KIND_REGULAR,
              sourcePath: wire.ModLogicalPath(components: ['source']),
              nativeSourcePath: source.path,
            ),
          ),
          throwsA(
            isA<GrpcError>().having(
              (error) => error.code,
              'code',
              StatusCode.invalidArgument,
            ),
          ),
        );
        expect((await inventory(child, profile)).entries, isEmpty);
      });
      test('immutable versions retain bytes and shared profile identity through rename and restart', () async {
        final (child, workspaceId, profile) = await workspace();
        final copy = newOperationId();
        await child.workspaces().cloneProfile(
          workspaceId,
          1,
          profile,
          ProfileInfo(copy, 'Weekend'),
        );
        final client = child.modLibrary();
        final id = newOperationId(),
            firstId = newOperationId(),
            secondId = newOperationId();
        await File(childPath(source.path, 'changed.txt'))
            .writeAsString('old bytes');
        await File(childPath(source.path, 'same.txt'))
            .writeAsString('same bytes');
        await client.register(
          workspaceId,
          id,
          const ModMetadata(
            name: 'Trees',
            notes: 'Keep this',
            source: 'Local directory',
            version: '1.0',
            categories: [
              CategoryReference(
                'fc53e8b36ac0432ab049235ff80102ec',
                'Visual',
                missing: true,
              ),
            ],
            comment: 'Fixture',
          ),
          const DirectoryMod(ModKind.regular, ['source']),
        );
        final first = await client.publish(id, 0, firstId);
        final before = await client.version(firstId);
        await File(childPath(source.path, 'changed.txt'))
            .writeAsString('new bytes');
        final second = await client.publish(id, first.revision, secondId);
        final after = await client.version(secondId);
        ManifestEntry named(ModVersionPage version, String name) =>
            version.entries.singleWhere((entry) => entry.path.single == name);
        expect(
          named(before, 'same.txt').payload.id,
          named(after, 'same.txt').payload.id,
        );
        expect(
          named(before, 'changed.txt').payload.id,
          isNot(named(after, 'changed.txt').payload.id),
        );
        expect(
          utf8.decode(
            await client.readPayload(
              firstId,
              named(before, 'changed.txt').payload.id,
            ),
          ),
          'old bytes',
        );
        final renamed = await client.edit(
          id,
          second.revision,
          const ModMetadata(
            name: 'Trees renamed',
            notes: 'Keep this',
            source: 'Local directory',
            version: '1.0',
            categories: [
              CategoryReference(
                'fc53e8b36ac0432ab049235ff80102ec',
                'Visual',
                missing: true,
              ),
            ],
            comment: 'Fixture',
          ),
        );
        for (final selected in [profile, copy]) {
          final entry = (await inventory(child, selected)).entries.single;
          expect(entry.id, id);
          expect(entry.metadata.name, renamed.metadata.name);
        }
        await expectLater(
          client.edit(id, second.revision, const ModMetadata(name: 'Stale')),
          throwsA(
            isA<LibraryException>().having(
              (e) => e.fault,
              'fault',
              LibraryFault.staleRevision,
            ),
          ),
        );
        expect(
          (await client.publish(id, 0, firstId)).currentVersionId,
          secondId,
        );
        expect(
          (await client.cancelPublication(firstId)).phase,
          PublicationPhase.complete,
        );
        expect((await child.operations().check()).runtime.nativeAot, isTrue);
        await child.close();
        final restarted = await start();
        await restarted.workspaces().open(root.path);
        final entry = (await inventory(restarted, profile)).entries.single;
        expect(entry.metadata.notes, 'Keep this');
        expect(entry.metadata.name, 'Trees renamed');
        expect(entry.currentVersionId, secondId);
        expect(
          utf8.decode(
            await restarted.modLibrary().readPayload(
              firstId,
              named(before, 'changed.txt').payload.id,
            ),
          ),
          'old bytes',
        );
      });
      test(
        'authentication refuses library mutation before any directory effect',
        () async {
          final (child, workspaceId, profile) = await workspace();
          for (final client in [
            child.modLibrary(authenticate: false),
            child.modLibrary(token: 'wrong'),
          ]) {
            await expectLater(
              client.register(
                workspaceId,
                newOperationId(),
                const ModMetadata(name: 'Denied'),
                const SeparatorMod(),
              ),
              throwsA(
                isA<GrpcError>().having(
                  (e) => e.code,
                  'status',
                  StatusCode.unauthenticated,
                ),
              ),
            );
          }
          expect((await inventory(child, profile)).entries, isEmpty);
          expect(
            (await root.list().toList()).whereType<Directory>().map(
              (d) => d.path,
            ),
            [source.path],
          );
        },
      );
      test('special entries enforce their actions and detached sources remain registered', () async {
        final (child, workspaceId, profile) = await workspace();
        final client = child.modLibrary();
        await File(childPath(source.path, 'item')).writeAsString('original');
        final id = newOperationId(), version = newOperationId();
        await client.register(
          workspaceId,
          id,
          const ModMetadata(name: 'Regular'),
          const DirectoryMod(ModKind.regular, ['source']),
        );
        final published = await client.publish(id, 0, version);
        final backup = await client.register(
          workspaceId,
          newOperationId(),
          const ModMetadata(name: 'Original backup'),
          BackupMod(version),
        );
        expect(backup.actions, [ModAction.readVersion]);
        await expectLater(
          client.edit(backup.id, 0, const ModMetadata(name: 'Not mutable')),
          throwsA(
            isA<LibraryException>().having(
              (e) => e.fault,
              'fault',
              LibraryFault.unsupportedAction,
            ),
          ),
        );
        final separator = await client.register(
          workspaceId,
          newOperationId(),
          const ModMetadata(name: 'Visual'),
          const SeparatorMod(),
        );
        expect(
          (await client.edit(
            separator.id,
            0,
            const ModMetadata(name: 'Visual mods'),
          )).metadata.name,
          'Visual mods',
        );
        await expectLater(
          client.publish(separator.id, 1, newOperationId()),
          throwsA(
            isA<LibraryException>().having(
              (e) => e.fault,
              'fault',
              LibraryFault.unsupportedAction,
            ),
          ),
        );
        final output = await Directory(childPath(root.path, 'output')).create();
        await File(childPath(output.path, 'result'))
            .writeAsString('tool output');
        final generated = await client.register(
          workspaceId,
          newOperationId(),
          const ModMetadata(name: 'Tool output'),
          const DirectoryMod(ModKind.generatedOutput, ['output']),
        );
        await expectLater(
          client.publish(generated.id, 0, newOperationId()),
          throwsA(
            isA<LibraryException>().having(
              (e) => e.fault,
              'fault',
              LibraryFault.unsupportedAction,
            ),
          ),
        );
        await Directory(childPath(root.path, 'unknown')).create();
        await source.rename(childPath(root.path, 'detached-source'));
        final scan = await client.scan(workspaceId, candidateLimit: 1000);
        await expectLater(
          client.publish(id, published.revision, newOperationId()),
          throwsA(
            isA<LibraryException>().having(
              (error) => error.fault,
              'fault',
              LibraryFault.fileUnavailable,
            ),
          ),
        );
        expect(
          scan.unmanaged.any((entry) => entry.path.single == 'unknown'),
          isTrue,
        );
        expect(
          (await inventory(
            child,
            profile,
          )).entries.any((entry) => entry.id == id),
          isTrue,
        );
        final manifest = await client.version(version);
        expect(
          utf8.decode(
            await client.readPayload(
              version,
              manifest.entries.single.payload.id,
            ),
          ),
          'original',
        );
        expect(
          await File(childPath(output.path, 'result')).readAsString(),
          'tool output',
        );
      });
      test('large saved notes keep inventory pages bounded without dropping entries', () async {
        final (child, workspaceId, profile) = await workspace();
        final client = child.modLibrary();
        final notes = List.filled(4096, '界').join();
        final comment = List.filled(1024, '界').join();
        for (var i = 0; i < 30; i++) {
          await client.register(
            workspaceId,
            newOperationId(),
            ModMetadata(
              name: 'Section $i',
              notes: notes,
              comment: comment,
              source: comment,
              categories: [
                CategoryReference(
                  'fc53e8b36ac0432ab049235ff80102ec',
                  List.filled(256, '界').join(),
                  missing: true,
                ),
              ],
            ),
            const SeparatorMod(),
          );
        }
        final first = await inventory(child, profile);
        expect(first.entries.length, lessThan(30));
        expect(first.entries, isNotEmpty);
        final second = await inventory(child, profile, cursor: first.next);
        expect(second.next, isNull);
        final entries = [...first.entries, ...second.entries];
        expect(entries.length, 30);
        expect(entries.map((entry) => entry.id).toSet().length, 30);
        expect(entries.every((entry) => entry.metadata.notes == notes), isTrue);
      });

      test('version pages preserve original names without imposing a Windows target policy', () async {
        final (child, workspaceId, _) = await workspace();
        for (var i = 0; i < 66; i++) {
          await File(childPath(source.path, 'file-$i'))
              .writeAsString('item $i');
        }
        if (Platform.isLinux) {
          await File(childPath(source.path, r'back\slash'))
              .writeAsString('native name');
        }
        final client = child.modLibrary(),
            id = newOperationId(),
            version = newOperationId();
        await client.register(
          workspaceId,
          id,
          const ModMetadata(name: 'Many files'),
          const DirectoryMod(ModKind.regular, ['source']),
        );
        await client.publish(id, 0, version);
        final first = await client.version(version),
            second = await client.version(version, offset: 64);
        expect(first.entries.length, 64);
        expect(first.nextOffset, 64);
        expect(second.nextOffset, isNull);
        final all = [...first.entries, ...second.entries];
        expect(all.length, Platform.isLinux ? 67 : 66);
        if (Platform.isLinux) {
          expect(
            all.any((entry) => entry.path.single == r'back\slash'),
            isTrue,
          );
        }
      });
    },
  );
}
