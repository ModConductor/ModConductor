import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_game_contexts/src/proton_dialog.dart';

import 'proton_dialog_test.dart' show Discovery, empty;

const regional = ProtonSearchResult(
  prefixes: [
    ProtonPrefixCandidate(
      'regional',
      '/compatdata/22490',
      '/compatdata/22490/pfx',
      [
        SteamInstallationOrigin(
          root: SteamSearchRoot('/steam', 'fixture'),
          steamRoot: SteamDirectory('/steam', '/steam', 's'),
          library: SteamDirectory('/library', '/library', 'l'),
          manifest: SteamManifestEvidence(
            path: '/manifest',
            nativeIdentity: 'm',
            sha256: 'hash',
            appId: 22490,
            installDirectory: 'New Vegas',
          ),
        ),
      ],
    ),
  ],
  tools: [],
  mappings: [],
  problems: [],
  limited: false,
);

void main() {
  for (final editing in [false, true]) {
    testWidgets(
      editing
          ? 'editing a regional context keeps its AppID without discovery'
          : 'choosing a discovered regional prefix submits its AppID',
      (tester) async {
        final discovery = Discovery();
        ProtonSelection? selected;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    selected = await showDialog<ProtonSelection>(
                      context: context,
                      builder: (_) => ProtonDialog(
                        gameId: 'new-vegas-steam',
                        gameName: 'Fallout: New Vegas',
                        steamAppId: 22380,
                        gamePath: '/game',
                        client: discovery,
                        chooseDirectory: (_) async => null,
                        roots: const [],
                        initial: editing
                            ? const ProtonSelection(
                                appId: 22490,
                                association: ManualProtonAssociation(),
                                compatData: '/compatdata/22490',
                                runtimeDirectory: '/runtime',
                                toolId: '',
                              )
                            : null,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pump();
        discovery.requests.single.complete(editing ? empty : regional);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('proton-runtime-folder')),
          '/runtime',
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('submit')));
        await tester.tap(find.byKey(const ValueKey('submit')));
        await tester.pumpAndSettle();
        expect(selected?.compatData, '/compatdata/22490');
        expect(selected?.appId, 22490);
      },
    );
  }
}
