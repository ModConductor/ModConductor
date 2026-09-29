import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final engine = Platform.environment['MC_ENGINE_PATH'];
  final fixture = Platform.environment['MC_NATIVE_FIXTURE'];
  test(
    'Linux Proton save groups use the versioned protocol and refuse a changed companion before copying',
    () async {
      final area = await Directory.systemTemp.createTemp('mc-save-management-');
      final state = await Directory('${area.path}/state').create();
      final root = await Directory('${area.path}/workspace').create();
      final files = '${area.path}/files';
      final prepared = await Process.run(fixture!, ['--proton-files', files]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      final steam = '$files/Steam';
      final library = '$files/Second library';
      final game = '$library/steamapps/common/Skyrim Special Edition';
      final runtime = '$steam/compatibilitytools.d/Custom Ω Proton';
      final child = await NativeChild.start(engine!, state);
      try {
        final workspace = newOperationId(), profile = newOperationId();
        await child.workspaces().create(workspace, 'Save protocol', root.path);
        await child.workspaces().createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        final checked = await child.gameContexts().save(
          workspace,
          profile,
          'skyrim-se-steam',
          0,
          game,
          proton: ProtonSelection(
            appId: 489830,
            association: SteamProtonAssociation(steam, library),
            compatData: '$library/steamapps/compatdata/489830',
            runtimeDirectory: runtime,
            toolId: 'fixture_tool',
          ),
        );
        final documents =
            (checked.binding!.evidence.documents as LocatedGameFolder).path;
        final global = await Directory('$documents/Saves').create();
        final save = File('${global.path}/Opaque.ess');
        final companion = File('${global.path}/Opaque.skse');
        await save.writeAsBytes([1, 2, 3, 4]);
        await companion.writeAsBytes([5, 6, 7, 8]);
        await File('${global.path}/steam_autocloud.vdf').writeAsString('keep');

        final client = child.profileData();
        final initial = await client.read(workspace, profile);
        final enabled =
            (await client
                    .edit(
                      newOperationId(),
                      initial.reference,
                      const ProfileDataOptions(settings: false, saves: true),
                      initialSaves: InitialProfileSaves.empty,
                      disabledFiles: DisabledProfileFiles.keep,
                    )
                    .toList())
                .whereType<ProfileDataResult>()
                .single;
        expect(enabled.complete, isTrue);

        final page = await client.saveGroups(
          workspace,
          profile,
          ProfileSaveSource.global,
        );
        final group = page.entries.singleWhere(
          (entry) => entry.name == 'Opaque.ess',
        );
        expect(group.companion, 'Opaque.skse');
        expect(page.path.windowsPath, isNotNull);
        final inspected = await client.inspectSave(
          workspace,
          profile,
          ProfileSaveSource.global,
          group.name,
        );
        expect(inspected.metadata, isNull);
        expect(inspected.metadataProblem, isNotNull);

        final preview = await client.previewSaveAction(
          enabled.state.reference,
          ProfileSaveAction.copyToProfile,
          [group.name],
        );
        expect(
          preview.files.map((file) => file.name),
          containsAll(['Opaque.ess', 'Opaque.skse']),
        );
        await companion.writeAsBytes([9, 9, 9]);
        await expectLater(
          client
              .applySaveAction(newOperationId(), preview.id, preview.expected)
              .toList(),
          throwsA(
            isA<ProfileDataProblem>().having(
              (error) => error.kind,
              'kind',
              ProfileDataProblemKind.conflict,
            ),
          ),
        );
        expect(
          await File('${enabled.state.savesPath}/Opaque.ess').exists(),
          isFalse,
        );
        expect(
          await File('${enabled.state.savesPath}/Opaque.skse').exists(),
          isFalse,
        );
        expect(
          await File('${global.path}/steam_autocloud.vdf').readAsString(),
          'keep',
        );

        await companion.writeAsBytes([5, 6, 7, 8]);
        final current = await client.read(workspace, profile);
        final retry = await client.previewSaveAction(
          current.reference,
          ProfileSaveAction.copyToProfile,
          [group.name],
        );
        final copied =
            (await client
                    .applySaveAction(newOperationId(), retry.id, retry.expected)
                    .toList())
                .whereType<ProfileDataResult>()
                .single;
        expect(copied.complete, isTrue);
        expect(
          await File('${copied.state.savesPath}/Opaque.ess').readAsBytes(),
          [1, 2, 3, 4],
        );
        expect(
          await File('${copied.state.savesPath}/Opaque.skse').readAsBytes(),
          [5, 6, 7, 8],
        );
      } finally {
        await child.close();
        await area.delete(recursive: true);
      }
    },
    skip: !Platform.isLinux || engine == null || fixture == null,
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
