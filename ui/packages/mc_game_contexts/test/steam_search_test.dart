import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_game_contexts/mc_game_contexts.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'game_context_test.dart' show Client;

SteamInstallationCandidate candidate(String id, String path) =>
    SteamInstallationCandidate(
      id,
      SteamDirectory(path, path, 'native-$id'),
      const [],
    );
SteamSearchResult report(List<SteamInstallationCandidate> rows) =>
    SteamSearchResult(
      appId: 489830,
      roots: const [],
      candidates: rows,
      diagnostics: const [],
      limited: false,
    );

class DiscoveryClient implements SteamDiscoveryClient {
  final requests = <Completer<SteamSearchResult>>[];
  final roots = <List<String>>[];
  int cancellations = 0;
  @override
  SteamSearch search(String definitionId, List<String> additionalRoots) {
    final pending = Completer<SteamSearchResult>();
    requests.add(pending);
    roots.add(additionalRoots);
    return SteamSearch(pending.future, () async {
      cancellations++;
    });
  }
}

void main() {
  test('cancelled searches cannot replace newer results and refresh retains stable selection', () async {
    final client = DiscoveryClient();
    final controller = SteamSearchController(client, 'skyrim');
    final first = controller.search();
    controller.cancel();
    final next = controller.addRoot('/selected-steam');
    client.requests[1].complete(
      report([candidate('a', '/a'), candidate('b', '/b')]),
    );
    await next;
    controller.model.select('b');
    client.requests[0].complete(report([candidate('old', '/old')]));
    await first;
    expect(controller.model.selectedId, 'b');
    expect(controller.model.ids, isNot(contains('old')));
    expect(client.cancellations, 1);
    final refresh = controller.search();
    client.requests[2].complete(
      report([candidate('b', '/renamed'), candidate('a', '/a')]),
    );
    await refresh;
    expect(controller.model.selectedId, 'b');
    expect(client.roots.last, ['/selected-steam']);
    final removal = controller.search();
    client.requests[3].complete(report([candidate('a', '/a')]));
    await removal;
    expect(controller.model.selected, isNull);
    controller.dispose();
  });

  testWidgets(
    'choosing a discovered installation edits only the draft until explicit Save',
    (tester) async {
      final discovery = DiscoveryClient();
      final client = Client();
      final saves = <String>[];
      final save = client.onSave;
      client.onSave = (id, revision, path) {
        saves.add(path);
        return save(id, revision, path);
      };
      final controller = GameContextController()
        ..attach(
          client,
          workspaceId: 'workspace',
          profileId: 'profile',
          editable: true,
        );
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Scaffold(
            body: GameContextBrowser(
              controller: controller,
              steamDiscovery: discovery,
              chooseDirectory: (_) async => '/steam',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> choose() async {
        await tester.tap(find.byKey(const ValueKey('change-installation')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('find-in-steam')));
        await tester.pump();
        discovery.requests.last.complete(
          report([candidate('found', '/discovered-game')]),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('choose-steam-installation')),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('installation-folder')),
              )
              .controller!
              .text,
          '/discovered-game',
        );
        expect(controller.state!.binding!.path, '/game');
        expect(saves, isEmpty);
      }

      await choose();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.state!.binding!.path, '/game');
      expect(saves, isEmpty);
      await choose();
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(saves, ['/discovered-game']);
      expect(controller.state!.binding!.path, '/discovered-game');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
