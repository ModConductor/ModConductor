import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_artifacts/src/nexus_view.dart';

class _Nexus extends Fake implements NexusClient {
  final requested = <int>[];

  @override
  Future<NexusAccount> status() async =>
      const NexusAccount(true, false, 'Rowan', true, null);

  @override
  Future<NexusMod> mod(String workspace, String profile, int id) async {
    expect((workspace, profile), ('workspace', 'profile'));
    requested.add(id);
    return const NexusMod(64012, 'Quiet Rivers', 'River textures', [
      NexusFile(501, 'Quiet Rivers.7z', '1.0', 'Main files', '', null),
    ]);
  }
}

void main() {
  testWidgets('discovery file action enters the existing exact mod file flow', (
    tester,
  ) async {
    final nexus = _Nexus();
    tester.view.physicalSize = const Size(1200, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.dark),
        home: Scaffold(
          body: NexusFilesView(
            client: nexus,
            workspace: 'workspace',
            profile: 'profile',
            initialModId: 64012,
            onBack: () {},
            onDownloaded: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(nexus.requested, [64012]);
    expect(find.text('Quiet Rivers.7z'), findsWidgets);
  });
}
