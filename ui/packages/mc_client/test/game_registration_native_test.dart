import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final engine = Platform.environment['MC_ENGINE_PATH'];
  test(
    'custom definitions cross the NativeAOT v1 boundary and survive restart with duplicate names',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'mc-game-registration-wire-',
      );
      final state = await Directory('${root.path}/state').create();
      var child = await NativeChild.start(engine!, state);
      try {
        expect((await child.operations().check()).runtime.nativeAot, isTrue);
        final client = child.gameCatalogue();
        final first = await client.saveCustomGame(
          CustomGameDraft(
            name: 'Duplicate',
            mechanism: 'ue4ss',
            executable: 'Example/Binaries/Win64/Example.exe',
            content: 'Example/Content',
            proxy: 'dwmapi.dll',
            core: 'ue4ss',
            mods: 'ue4ss/Mods',
            settingsFile: 'ue4ss/UE4SS-settings.ini',
            log: 'ue4ss/UE4SS.log',
          ),
        );
        final other = await client.saveCustomGame(
          CustomGameDraft(
            name: 'Duplicate',
            mechanism: 'unity-il2cpp',
            executable: 'Other.exe',
            content: 'Other_Data',
            windowsRuntime: 'GameAssembly.dll',
            metadata: 'il2cpp_data/Metadata/global-metadata.dat',
            unityMetadata: 'globalgamemanagers',
          ),
        );
        expect(first.problem, isNull);
        expect(other.problem, isNull);
        expect(first.game!.id, isNot(other.game!.id));
        final before = await File('${state.path}/games.toml').readAsBytes();
        final invalid = await client.saveCustomGame(
          CustomGameDraft(
            name: 'Invalid',
            mechanism: 'ue4ss',
            executable: '../escape.exe',
            content: 'Example/Content',
          ),
        );
        expect(invalid.game, isNull);
        expect(invalid.problem, isNotNull);
        expect(await File('${state.path}/games.toml').readAsBytes(), before);
        await child.close();
        child = await NativeChild.start(engine, state);
        final restarted = child.gameCatalogue();
        final ids = (await restarted.read())
            .where((game) => game.name == 'Duplicate')
            .map((game) => game.id)
            .toSet();
        expect(ids, {first.game!.id, other.game!.id});
        final edit = await restarted.readCustomGame(first.game!.id);
        edit!.name = 'Renamed';
        final saved = await restarted.saveCustomGame(edit);
        expect(saved.game!.id, first.game!.id);
        expect(
          (await restarted.read())
              .singleWhere((game) => game.id == other.game!.id)
              .name,
          'Duplicate',
        );
      } finally {
        await child.close();
        await root.delete(recursive: true);
      }
    },
    skip: engine == null
        ? 'Set MC_ENGINE_PATH to the final NativeAOT engine.'
        : false,
  );
  test('Unity saves reject missing consumed paths without mutation and retain optional Proton-only fields', () async {
    final root = await Directory.systemTemp.createTemp(
      'mc-unity-required-paths-',
    );
    final state = await Directory('${root.path}/state').create();
    final child = await NativeChild.start(engine!, state);
    try {
      final client = child.gameCatalogue();
      for (final mechanism in ['unity-mono', 'unity-il2cpp']) {
        final draft = CustomGameDraft(
          name: mechanism,
          mechanism: mechanism,
          executable: 'Example.exe',
          content: 'Example_Data',
          windowsRuntime: mechanism == 'unity-mono'
              ? 'MonoBleedingEdge/EmbedRuntime/mono-2.0-bdwgc.dll'
              : 'GameAssembly.dll',
          metadata: mechanism == 'unity-mono'
              ? 'Managed/Assembly-CSharp.dll'
              : 'il2cpp_data/Metadata/global-metadata.dat',
          unityMetadata: 'globalgamemanagers',
        );
        final saved = await client.saveCustomGame(draft);
        expect(saved.problem, isNull);
        final existing = await client.readCustomGame(saved.game!.id);
        expect(existing!.linuxExecutable, isEmpty);
        expect(existing.linuxRuntime, isEmpty);
        final before = await File('${state.path}/games.toml').readAsBytes();
        for (final field in ['unityMetadata', 'linuxRuntime']) {
          final invalid = CustomGameDraft.fromBuffer(existing.writeToBuffer());
          if (field == 'unityMetadata') {
            invalid.id = '';
            invalid.unityMetadata = '';
          } else {
            invalid.linuxExecutable = 'Example.x86_64';
            invalid.linuxRuntime = '';
          }
          final rejected = await client.saveCustomGame(invalid);
          expect(rejected.game, isNull);
          expect(rejected.problem, isNotEmpty);
          expect(await client.readCustomGame(existing.id), existing);
          expect(await File('${state.path}/games.toml').readAsBytes(), before);
        }
      }
    } finally {
      await child.close();
      await root.delete(recursive: true);
    }
  }, skip: engine == null);
  final portable = Platform.environment['MC_GAME_PORTABLE'];
  final installation = Platform.environment['MC_GAME_INSTALLATION'];
  test('embedded custom definition remains read-only until profile creation, then binds and imports on the destination', () async {
    final root = await Directory.systemTemp.createTemp(
      'mc-portable-game-wire-',
    );
    final state = await Directory('${root.path}/state').create();
    final workspaceRoot = await Directory('${root.path}/workspace').create();
    final child = await NativeChild.start(engine!, state);
    try {
      final transport = child.profileTransport();
      final preview = await transport.inspect(portable!);
      final catalogue = child.gameCatalogue();
      expect(preview.registrationGame!.id, preview.game);
      expect(preview.registrationGame!.nativeLinux, isTrue);
      expect(await catalogue.readCustomGame(preview.game), isNull);
      final registered = await catalogue.saveCustomGame(
        preview.gameDefinition!,
      );
      expect(registered.game!.id, preview.game);
      final page = await child.workspaces().create(
        newOperationId(),
        'Destination',
        workspaceRoot.path,
      );
      final profile = ProfileInfo(newOperationId(), 'Installation');
      await child.workspaces().createProfile(
        page.workspace.id,
        page.workspace.revision,
        profile,
      );
      final contexts = child.gameContexts();
      final initial = await contexts.read(page.workspace.id, profile.id);
      final bound = await contexts.save(
        page.workspace.id,
        profile.id,
        preview.game,
        initial.revision,
        installation!,
      );
      expect(bound.binding!.evidence.problems, isEmpty);
      final imported = await transport.import(
        portable,
        page.workspace.id,
        profile.id,
        'Imported',
      );
      final result = await contexts.read(page.workspace.id, imported);
      expect(result.binding!.path, installation);
      expect(result.definition!.id, preview.game);
      final before = await catalogue.readCustomGame(preview.game);
      await transport.import(
        portable,
        page.workspace.id,
        profile.id,
        'Imported again',
      );
      expect(await catalogue.readCustomGame(preview.game), before);
    } finally {
      await child.close();
      await root.delete(recursive: true);
    }
  }, skip: engine == null || portable == null || installation == null);
}
