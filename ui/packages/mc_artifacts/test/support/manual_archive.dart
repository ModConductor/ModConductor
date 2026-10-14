import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_artifacts/src/installation_file_collection.dart';
import 'package:mc_artifacts/src/installation_view.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

const manualArchive = Artifact(
  id: 'archive',
  workspaceId: 'workspace',
  revision: 1,
  originalName: 'River.zip',
  originalPath: '/fixture/River.zip',
  path: '/fixture/River.zip',
  storage: ArtifactStorage.reference,
  state: ArtifactState.ready,
  links: [],
  canRetry: false,
  canLocate: true,
  canDeleteCopy: false,
  canRemove: true,
);

InstallationDraft manualDraft({
  int revision = 0,
  InspectedArchive? manifest,
  List<InstallationFile> files = const [
    InstallationFile(0, ['custom', 'body.nif']),
    InstallationFile(2, ['textures', 'skin.dds']),
  ],
}) => InstallationDraft(
  id: 'draft',
  workspaceId: manualArchive.workspaceId,
  revision: revision,
  artifactId: manualArchive.id,
  archiveName: manualArchive.originalName,
  manifest:
      manifest ??
      const InspectedArchive('digest', 'ZIP', [
        InspectedEntry(
          0,
          ['Data', 'meshes', 'actors', 'body.nif'],
          false,
          4,
          4,
        ),
        InspectedEntry(
          1,
          ['Data', 'meshes', 'armor', 'armor.nif'],
          false,
          4,
          4,
        ),
        InspectedEntry(2, ['Data', 'textures', 'skin.dds'], false, 4, 4),
        InspectedEntry(3, ['Data', 'readme.txt'], false, 4, 4),
        InspectedEntry(4, ['Extras', 'license.txt'], false, 4, 4),
      ], 20),
  root: const ['Data'],
  files: files,
  name: 'River',
  version: '',
  bytes: files.length * 4,
  canInstall: files.isNotEmpty,
);

// Replies are supplied by each scenario, not computed by a second planner.
class ManualInstallations extends Fake implements InstallationsClient {
  final changes =
      <({InstallationDraft draft, InstallationLayoutChange change})>[];
  final replies = <Completer<InstallationDraft>>[];
  final starts = <InstallationDraft>[];

  @override
  Future<InstallationDraft> change(
    InstallationDraft draft,
    InstallationLayoutChange change,
  ) {
    changes.add((draft: draft, change: change));
    final reply = Completer<InstallationDraft>();
    replies.add(reply);
    return reply.future;
  }

  @override
  Future<InstallationStatus> start(InstallationDraft draft, String id) async {
    starts.add(draft);
    throw const ArtifactProblem('This fixture must not start installation.');
  }

  @override
  Future<void> closeDraft(InstallationDraft draft) async {}
}

Finder manualAction(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is McAction && widget.label == label ||
      widget is McIconAction && widget.label == label,
);

InstallationFileCollection manualCollection(WidgetTester tester) =>
    tester.widget<InstallationFileCollection>(
      find.byType(InstallationFileCollection),
    );

Future<void> openManualArchive(
  WidgetTester tester,
  ManualInstallations client, {
  Size size = const Size(1400, 900),
  InstallationDraft? draft,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: mcTheme(Brightness.dark),
      home: ArchiveInstallationView(
        artifact: manualArchive,
        client: client,
        initialDraft: draft ?? manualDraft(),
        onBack: () {},
        onCommitted: () => fail('Editing a draft must not commit an install.'),
        onOpenMods: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (!manualCollection(tester).manual) {
    await tester.tap(manualAction('Change layout'));
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
}
