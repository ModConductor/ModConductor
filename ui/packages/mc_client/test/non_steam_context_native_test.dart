import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final engine = Platform.environment['MC_ENGINE_PATH'];
  final fixture = Platform.environment['MC_NATIVE_FIXTURE'];
  final scratch = Platform.environment['MC_CONTEXT_TEST_ROOT'];
  test(
    'Wine selection crosses the native service and survives restart without Steam provenance',
    () async {
      final area = await Directory(scratch!).createTemp('context-wire-');
      final state = await Directory('${area.path}/state').create();
      final root = await Directory('${area.path}/workspace').create();
      final game = '${area.path}/game';
      final prepared = await Process.run(fixture!, ['--game-files', game]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      final wine = File('${area.path}/wine');
      await wine.writeAsString('#!/bin/sh\nexit 0\n');
      expect((await Process.run('chmod', ['700', wine.path])).exitCode, 0);
      final prefix = await Directory('${area.path}/prefix').create();
      await Directory(
        '${prefix.path}/drive_c/users/player/Documents/My Games/Skyrim Special Edition GOG/Saves',
      ).create(recursive: true);
      await Directory(
        '${prefix.path}/drive_c/users/player/AppData/Local/Skyrim Special Edition GOG',
      ).create(recursive: true);
      await Directory('${prefix.path}/dosdevices').create();
      await Link('${prefix.path}/dosdevices/c:').create('../drive_c');
      await File('${prefix.path}/user.reg')
          .writeAsString(r'''WINE REGISTRY Version 2
[Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders]
"Personal"="C:\\users\\player\\Documents"
"Local AppData"="C:\\users\\player\\AppData\\Local"
''');
      var child = await NativeChild.start(engine!, state);
      final workspace = newOperationId(), profile = newOperationId();
      try {
        await child.workspaces().create(workspace, 'Wine', root.path);
        await child.workspaces().createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'GOG'),
        );
        final pending = await child.gameContexts().save(
          workspace,
          profile,
          'skyrim-se-gog',
          0,
          game,
          wine: WineSelection(executable: wine.path, prefix: ''),
        );
        expect(pending.binding!.evidence.runtimeReady, isFalse);
        expect(pending.binding!.needsCheck, isFalse);
        expect(pending.binding!.failure, isNull);
        expect(pending.binding!.wine!.executable, wine.path);
        final selection = WineSelection(
          executable: wine.path,
          prefix: prefix.path,
        );
        final saved = await child.gameContexts().save(
          workspace,
          profile,
          'skyrim-se-gog',
          pending.revision,
          game,
          wine: selection,
        );
        expect(saved.binding!.evidence.runtimeReady, isTrue);
        expect(saved.binding!.evidence.platform, GameContextPlatform.wine);
        expect(saved.binding!.proton, isNull);
        expect(saved.definition!.declaredSteamAppId, 0);
        expect(
          (saved.binding!.evidence.documents as LocatedGameFolder).path,
          endsWith('Skyrim Special Edition GOG'),
        );
        await child.close();
        child = await NativeChild.start(engine, state);
        final restarted = await child.gameContexts().read(workspace, profile);
        expect(restarted.binding!.id, saved.binding!.id);
        expect(restarted.binding!.wine, selection);
        expect(restarted.binding!.needsCheck, isTrue);
        final checked = await child.gameContexts().refresh(
          workspace,
          profile,
          restarted.revision,
        );
        expect(checked.binding!.evidence.wine, selection);
        final steam = await child.gameContexts().save(
          workspace,
          profile,
          'skyrim-se-steam',
          checked.revision,
          game,
        );
        expect(steam.binding!.wine, isNull);
        expect(steam.binding!.evidence.wine, isNull);
        final reread = await child.gameContexts().read(workspace, profile);
        expect(reread.binding!.id, steam.binding!.id);
        expect(reread.binding!.id, isNot(saved.binding!.id));
      } finally {
        await child.close();
        await area.delete(recursive: true);
      }
    },
    skip:
        !Platform.isLinux ||
        engine == null ||
        fixture == null ||
        scratch == null,
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
