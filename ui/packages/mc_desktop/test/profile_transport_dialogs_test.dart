import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_desktop/mc_desktop.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class _Transport implements ProfileTransportClient {
  bool? exportedSaves;
  String? exportedPath;

  @override
  Future<ProfileTransportPreview> inspect(String path) =>
      throw UnimplementedError();

  @override
  Future<void> export(
    String workspace,
    String profile,
    String destination, {
    required bool includeSaves,
  }) async {
    exportedSaves = includeSaves;
    exportedPath = destination;
  }

  @override
  Future<String> import(
    String path,
    String workspace,
    String gameProfile,
    String name, {
    Map<int, String> manualSources = const {},
  }) => throw UnimplementedError();
}

void main() {
  testWidgets('profile export leaves saves out until selected', (tester) async {
    final transport = _Transport();
    const workspace = WorkspaceInfo(
      id: 'workspace',
      name: 'Workspace',
      path: '/workspace',
      revision: 1,
    );
    const profile = ProfileInfo('profile', 'Weekend');

    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (_) => ProfileExportDialog(
                  client: transport,
                  workspace: workspace,
                  profile: profile,
                  chooseDestination: (_) async => '/owned/Weekend.mcprof',
                ),
              ),
              child: const Text('Open export'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open export'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      false,
    );
    await tester.tap(find.text('Export profile').last);
    await tester.pumpAndSettle();

    expect(transport.exportedPath, '/owned/Weekend.mcprof');
    expect(transport.exportedSaves, false);
    expect(tester.takeException(), isNull);
  });
}
