import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_game_contexts/src/installation_dialog.dart';
import 'package:mc_game_contexts/src/proton_search_controller.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'game_context_test.dart' show Client, snapshot;

const empty = ProtonSearchResult(
  prefixes: [],
  tools: [],
  mappings: [],
  problems: [],
  limited: false,
);

final lateReport = ProtonSearchResult(
  prefixes: [
    ProtonPrefixCandidate('late', '/late/data', '/late/data/pfx', [
      const SteamInstallationOrigin(
        root: SteamSearchRoot('/steam', 'fixture'),
        steamRoot: SteamDirectory('/steam', '/steam', 's'),
        library: SteamDirectory('/library', '/library', 'l'),
        manifest: SteamManifestEvidence(
          path: '/manifest',
          nativeIdentity: 'm',
          sha256: 'hash',
          appId: 489830,
          installDirectory: 'Skyrim',
        ),
      ),
    ]),
  ],
  tools: const [
    ProtonInstalledTool(
      'late-tool',
      'Late tool',
      '/late/runtime',
      ProtonContextFile('/late/manifest', 'identity', 'hash'),
    ),
  ],
  mappings: const [],
  problems: const [],
  limited: false,
);

class Discovery implements ProtonContextsClient {
  final requests = <Completer<ProtonSearchResult>>[];
  int cancelled = 0;
  @override
  ProtonSearch search(
    String definitionId,
    String gamePath,
    List<String> additionalRoots,
  ) {
    final pending = Completer<ProtonSearchResult>();
    requests.add(pending);
    return ProtonSearch(pending.future, () async {
      cancelled++;
    });
  }
}

class SavingClient extends Client {
  final selections = <ProtonSelection?>[];
  @override
  Future<GameContextState> save(
    String id,
    int revision,
    String path, {
    ProtonSelection? proton,
  }) {
    selections.add(proton);
    return super.save(id, revision, path, proton: proton);
  }
}

void main() {
  test('cancelled context lookup cannot publish over its replacement or after disposal', () async {
    final client = Discovery();
    final controller = ProtonSearchController(
      client,
      'game',
      '/game',
      const [],
    );
    final first = controller.search();
    controller.cancel();
    final second = controller.search();
    client.requests[1].complete(empty);
    await second;
    client.requests[0].complete(
      const ProtonSearchResult(
        prefixes: [],
        tools: [],
        mappings: [],
        problems: [GameValidationProblem('/old', 'old')],
        limited: false,
      ),
    );
    await first;
    expect(controller.report, same(empty));
    final third = controller.search();
    controller.dispose();
    client.requests[2].complete(empty);
    await third;
    expect(client.cancelled, 2);
  });

  testWidgets(
    'choosing Proton edits only the outer draft and Save retains that selection',
    (tester) async {
      final client = SavingClient();
      final discovery = Discovery();
      var commits = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => InstallationDialog(
                    initial: snapshot('workspace', 1, '/game'),
                    client: client,
                    protonContexts: discovery,
                    chooseDirectory: (_) async => null,
                    onSaved: (_) => commits++,
                    onUnknownSave: () {},
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      Future<void> choose() async {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('select-proton')));
        await tester.tap(find.byKey(const ValueKey('select-proton')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('proton-data-folder')),
          '/selected data Ω',
        );
        await tester.enterText(
          find.byKey(const ValueKey('proton-runtime-folder')),
          '/selected runtime',
        );
        discovery.requests.last.complete(lateReport);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('submit')).last);
        await tester.tap(find.byKey(const ValueKey('submit')).last);
        await tester.pumpAndSettle();
      }

      await choose();
      expect(client.selections, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(commits, 0);
      await choose();
      await tester.ensureVisible(find.byKey(const ValueKey('submit')).last);
      await tester.tap(find.byKey(const ValueKey('submit')).last);
      await tester.pumpAndSettle();
      expect(client.selections.single!.compatData, '/selected data Ω');
      expect(client.selections.single!.runtimeDirectory, '/selected runtime');
      expect(
        client.selections.single!.association,
        isA<ManualProtonAssociation>(),
      );
      expect(commits, 1);
    },
    skip: !Platform.isLinux,
  );
}
