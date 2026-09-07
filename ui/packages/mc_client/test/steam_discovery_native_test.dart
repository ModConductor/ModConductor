import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final engine = Platform.environment['MC_ENGINE_PATH'];
  final fixtureTool = Platform.environment['MC_NATIVE_FIXTURE'];
  test(
    'authenticated discovery preserves observations and requires explicit revalidated Save',
    () async {
      final area = await Directory.systemTemp.createTemp('mc-steam-');
      final state = await Directory('${area.path}/state').create();
      final root = await Directory('${area.path}/workspace').create();
      final fixture = '${area.path}/fixture';
      final prepared = await Process.run(fixtureTool!, [
        '--steam-files',
        fixture,
      ]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      final steam = '$fixture/Steam';
      final library = '$fixture/Second library';
      final game = '$library/steamapps/common/Skyrim Special Edition';
      final canonicalGame = await Directory(game).resolveSymbolicLinks();
      final manifest = File('$library/steamapps/appmanifest_489830.acf');
      final bytes = await manifest.readAsBytes();
      var child = await NativeChild.start(engine!, state);
      try {
        final workspace = newOperationId();
        await child.workspaces().create(workspace, 'Steam check', root.path);
        var contexts = child.gameContexts();
        final initial = await contexts.read(workspace);
        await expectLater(
          child.steamDiscovery(authenticate: false).search(
            initial.definition.id,
            [steam],
          ).result,
          throwsA(
            isA<GrpcError>().having(
              (e) => e.code,
              'code',
              StatusCode.unauthenticated,
            ),
          ),
        );
        final discovery = child.steamDiscovery();
        final first = await discovery.search(initial.definition.id, [
          steam,
        ]).result;
        final found = first.candidates.singleWhere(
          (c) => c.directory.canonicalPath == canonicalGame,
        );
        expect(
          found.origins.any(
            (o) =>
                o.manifest.appId == 489830 && o.manifest.buildId == '24914197',
          ),
          isTrue,
        );
        expect(
          first.diagnostics.any((d) => d.path.contains('Unavailable library')),
          isTrue,
        );
        expect((await contexts.read(workspace)).binding, isNull);
        final again = await discovery.search(initial.definition.id, [
          steam,
          library,
        ]).result;
        final repeated = again.candidates.singleWhere((c) => c.id == found.id);
        expect(repeated.origins.length, greaterThan(found.origins.length));
        expect(await manifest.readAsBytes(), bytes);
        final data = Directory('$game/Data');
        await data.rename('$game/temporarily-moved');
        await expectLater(
          contexts.save(
            workspace,
            initial.revision,
            found.directory.canonicalPath,
          ),
          throwsA(
            isA<GameContextException>().having(
              (e) => e.code,
              'code',
              GameContextFailure.invalidInstallation,
            ),
          ),
        );
        expect((await contexts.read(workspace)).binding, isNull);
        await Directory('$game/temporarily-moved').rename('$game/Data');
        final saved = await contexts.save(
          workspace,
          initial.revision,
          found.directory.canonicalPath,
        );
        expect(saved.binding!.path, canonicalGame);
        expect(saved.binding!.evidence.executable!.fileVersion, '1.7.104.0');
        await child.close();
        child = await NativeChild.start(engine, state);
        contexts = child.gameContexts();
        final reopened = await contexts.read(workspace);
        expect(reopened.binding!.id, saved.binding!.id);
        expect(reopened.binding!.path, canonicalGame);
        expect(reopened.binding!.needsCheck, isTrue);
      } finally {
        await child.close();
        await area.delete(recursive: true);
      }
    },
    skip: engine == null || fixtureTool == null,
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
