import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_desktop/mc_desktop.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

const _preview = ProfileTransportPreview(
  'Weekend',
  'skyrim-se-steam',
  2,
  3,
  2,
  84000000,
  [],
);

class _UnusedWorkspaceClient implements WorkspacesClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedGameContexts implements GameContextsClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transport implements ProfileTransportClient {
  bool? exportedSaves;
  String? exportedPath;

  @override
  Future<ProfileTransportPreview> inspect(String path) async {
    expect(path, '/owned/Weekend.mcprof');
    return _preview;
  }

  @override
  Future<ProfileTransportPreview> previewExport(
    String workspace,
    String profile,
  ) async {
    expect(workspace, 'workspace');
    expect(profile, 'profile');
    return _preview;
  }

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
  testWidgets('profile import shows the selected file and effective summary', (
    tester,
  ) async {
    final controller = WorkspaceController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: Scaffold(
          body: ProfileImportDialog(
            path: '/owned/Weekend.mcprof',
            client: _Transport(),
            workspaces: controller,
            workspaceClient: _UnusedWorkspaceClient(),
            gameContexts: _UnusedGameContexts(),
            createWorkspace: (_) async => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekend.mcprof'), findsOneWidget);
    expect(
      find.text('Skyrim Special Edition · 2 mods · 3 mod files'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

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

    expect(find.text('Weekend'), findsOneWidget);
    expect(
      find.text('Skyrim Special Edition · 2 mods · 3 mod files'),
      findsOneWidget,
    );
    expect(find.text('2 files · 84 MB'), findsOneWidget);

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
