import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final executable = Platform.environment['MC_ENGINE_PATH'];
  late Directory fixture, state, root, source;
  final children = <NativeChild>[];

  Future<NativeChild> start() async {
    final child = await NativeChild.start(executable!, state);
    children.add(child);
    return child;
  }

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('mc-migration-wire-');
    state = await Directory('${fixture.path}/state').create();
    root = await Directory('${fixture.path}/workspace').create();
    source = await Directory('${fixture.path}/source').create();
    await Directory('${source.path}/mods/Example/data').create(recursive: true);
    await File('${source.path}/mods/Example/data/file.txt')
        .writeAsString('migrated payload');
    await File('${source.path}/mods/Example/meta.ini')
        .writeAsString('[General]\nversion=1.0\nnotes=Native wire fixture\n');
    await Directory('${source.path}/profiles/Default').create(recursive: true);
    await File('${source.path}/profiles/Default/modlist.txt')
        .writeAsString('+Example\n');
    await File('${source.path}/profiles/Default/settings.ini')
        .writeAsString('[General]\nLocalSaves=false\nLocalSettings=false\n');
    await Directory('${source.path}/downloads').create();
    await File('${source.path}/ModOrganizer.ini').writeAsString(
      '[General]\nselected_profile=@ByteArray(Default)\n'
      '[Settings]\nbase_directory=%BASE_DIR%\n'
      'mod_directory=%BASE_DIR%/mods\n'
      'profiles_directory=%BASE_DIR%/profiles\n'
      'download_directory=%BASE_DIR%/downloads\n',
    );
  });

  tearDown(() async {
    for (final child in children) {
      await child.close();
    }
    children.clear();
    await fixture.delete(recursive: true);
  });

  group(
    'native migration wire',
    skip: executable == null
        ? 'Set MC_ENGINE_PATH to a published NativeAOT engine.'
        : false,
    () {
      test('authenticated migration streams progress and writes queryable owned data', () async {
        final child = await start();
        final id = newOperationId();
        await child.workspaces().create(id, 'Empty', root.path);
        final events = await child
            .migration()
            .migrate(id, MigrationManager.modOrganizer, source.path)
            .toList();
        expect(events.whereType<MigrationProgress>(), isNotEmpty);
        expect(events.last, isA<MigrationResult>());
        final workspace = await child.workspaces().read(id);
        expect(workspace.profiles.single.name, 'Default');
        final mods = await child.modLibrary().scan(id, candidateLimit: 100);
        expect(mods.entries.single.metadata.name, 'Example');
        expect(mods.entries.single.status, InventoryStatus.ready);
        expect((await child.operations().check()).runtime.nativeAot, isTrue);
      });

      test(
        'missing authentication rejects migration before target mutation',
        () async {
          final child = await start();
          final id = newOperationId();
          await child.workspaces().create(id, 'Empty', root.path);
          await expectLater(
            child
                .migration(authenticate: false)
                .migrate(id, MigrationManager.modOrganizer, source.path)
                .toList(),
            throwsA(
              isA<GrpcError>().having(
                (error) => error.code,
                'status',
                StatusCode.unauthenticated,
              ),
            ),
          );
          expect((await child.workspaces().read(id)).profiles, isEmpty);
          expect(
            (await child.modLibrary().scan(id, candidateLimit: 100)).entries,
            isEmpty,
          );
        },
      );
    },
  );
}
