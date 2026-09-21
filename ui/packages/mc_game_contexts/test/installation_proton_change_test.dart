import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_game_contexts/src/installation_dialog.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'game_context_test.dart' show snapshot;
import 'proton_dialog_test.dart' show Discovery, SavingClient, empty;
import 'steam_search_test.dart' show DiscoveryClient, candidate, report;

const oldSelection = ProtonSelection(
  appId: 489830,
  association: ManualProtonAssociation(),
  compatData: '/old-prefix',
  runtimeDirectory: '/old-runtime',
  toolId: 'old-tool',
);
GameContextState manualState() {
  final state = snapshot('workspace', 1, '/old-game');
  final e = state.binding!.evidence;
  return GameContextState(
    workspaceId: state.workspaceId,
    profileId: state.profileId,
    revision: state.revision,
    definition: state.definition,
    binding: GameBindingInfo(
      id: state.binding!.id,
      path: '/old-game',
      needsCheck: false,
      proton: oldSelection,
      evidence: GameInstallationEvidence(
        definitionId: e.definitionId,
        definitionRevision: e.definitionRevision,
        platform: GameContextPlatform.proton,
        rootPath: e.rootPath,
        dataPath: e.dataPath,
        executable: e.executable,
        launcherPath: e.launcherPath,
        documents: e.documents,
        saves: e.saves,
        localAppData: e.localAppData,
        problems: e.problems,
        checkedAt: e.checkedAt,
        fingerprint: e.fingerprint,
        proton: const ProtonEvidence(
          selection: oldSelection,
          prefixPath: '/old-prefix/pfx',
          prefixIdentity: 'prefix',
          compatDataIdentity: 'data',
          runtimeIdentity: 'runtime',
          runtimeName: 'Old Proton',
          runtimeVersion: '1',
          launcher: ProtonContextFile(
            '/old-runtime/proton',
            'launcher',
            'hash',
          ),
          metadata: [],
          paths: [],
        ),
      ),
    ),
  );
}

void main() {
  for (final input in ['text', 'browse', 'steam']) {
    testWidgets(
      '$input changes clear manual Proton only when the game path changes',
      (tester) async {
        final initial = manualState();
        final client = SavingClient();
        final steam = DiscoveryClient();
        var selectedFolder = '/old-game';
        GameContextState? accepted;
        await tester.pumpWidget(
          MaterialApp(
            theme: mcTheme(Brightness.light),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => InstallationDialog(
                      initial: initial,
                      client: client,
                      steamDiscovery: steam,
                      chooseDirectory: (_) async => selectedFolder,
                      onSaved: (state) => accepted = state,
                      onUnknownSave: () {},
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        Future<void> tap(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        Future<void> change(String path) async {
          await tap(find.text('Open'));
          switch (input) {
            case 'text':
              await tester.enterText(
                find.byKey(const ValueKey('installation-folder')),
                path,
              );
            case 'browse':
              selectedFolder = path;
              await tap(find.byKey(const ValueKey('browse-installation')));
            case 'steam':
              await tap(find.byKey(const ValueKey('find-in-steam')));
              steam.requests.last.complete(
                report([candidate('selected', path)]),
              );
              await tester.pumpAndSettle();
              await tap(
                find.byKey(const ValueKey('choose-steam-installation')),
              );
          }
          await tester.pumpAndSettle();
        }

        await change('/old-game');
        await tap(find.byKey(const ValueKey('submit')));
        expect(client.selections.single, same(oldSelection));
        final beforeCancel = accepted;
        await change('/new-game');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(accepted, same(beforeCancel));
        expect(client.selections.length, 1);
        await change('/new-game');
        await tap(find.byKey(const ValueKey('submit')));
        expect(client.selections.last, isNull);
        expect(accepted!.binding!.path, '/new-game');
      },
    );
  }
  testWidgets(
    'reselecting Proton for the replacement game supplies a new Save association',
    (tester) async {
      final initial = manualState();
      final client = SavingClient();
      final discovery = Discovery();
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => InstallationDialog(
                    initial: initial,
                    client: client,
                    protonContexts: discovery,
                    chooseDirectory: (_) async => null,
                    onSaved: (_) {},
                    onUnknownSave: () {},
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tap(find.text('Open'));
      await tester.enterText(
        find.byKey(const ValueKey('installation-folder')),
        '/new-game',
      );
      final selectProton = find.byKey(const ValueKey('select-proton'));
      await tester.ensureVisible(selectProton);
      await tester.pumpAndSettle();
      await tester.tap(selectProton);
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('proton-data-folder')),
        '/new-prefix',
      );
      await tester.enterText(
        find.byKey(const ValueKey('proton-runtime-folder')),
        '/new-runtime',
      );
      discovery.requests.single.complete(empty);
      await tester.pumpAndSettle();
      await tap(find.byKey(const ValueKey('submit')).last);
      expect(client.selections, isEmpty);
      await tap(find.byKey(const ValueKey('submit')));
      expect(client.selections.single!.compatData, '/new-prefix');
      expect(client.selections.single!.runtimeDirectory, '/new-runtime');
      expect(
        client.selections.single!.association,
        isA<ManualProtonAssociation>(),
      );
    },
    skip: !Platform.isLinux,
  );
}
