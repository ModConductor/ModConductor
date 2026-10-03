import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_artifacts/src/installation_view.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

const archive = Artifact(
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

InstallationDraft draft({
  InstallationMode installer = InstallationMode.manual,
  bool canInstall = true,
  List<String> root = const ['Data'],
}) => InstallationDraft(
  id: 'draft',
  workspaceId: archive.workspaceId,
  revision: 0,
  artifactId: archive.id,
  archiveName: archive.originalName,
  manifest: const InspectedArchive('digest', 'ZIP', [
    InspectedEntry(0, ['Data', 'water.dds'], false, 4, 4),
  ], 4),
  root: root,
  files: [
    InstallationFile(0, root.isEmpty ? ['Data', 'water.dds'] : ['water.dds']),
  ],
  name: 'River',
  version: '',
  bytes: 4,
  canInstall: canInstall,
  installer: installer,
);

InstallationStatus status(String id, InstallationPhase phase) =>
    InstallationStatus(
      id: id,
      workspaceId: archive.workspaceId,
      artifactId: archive.id,
      archiveName: archive.originalName,
      name: 'River',
      version: '',
      phase: phase,
      files: phase == InstallationPhase.complete ? 1 : 0,
      totalFiles: 1,
      bytes: phase == InstallationPhase.complete ? 4 : 0,
      totalBytes: 4,
      modId: phase == InstallationPhase.complete ? 'mod' : null,
    );

class _Artifacts extends Fake implements ArtifactsClient {
  Artifact current = archive;
  int reads = 0;

  @override
  Future<ArtifactPage> list(
    String workspaceId, {
    String? after,
    bool refresh = false,
  }) async {
    reads++;
    return ArtifactPage([current], null);
  }
}

class _Installations extends Fake implements InstallationsClient {
  InstallationDraft prepared = draft();
  int preparations = 0, preparationFailures = 0, startFailures = 0;
  final starts = <({InstallationDraft draft, String id})>[];
  final changes = <InstallationLayoutChange>[];
  final events = StreamController<InstallationStatus>.broadcast();

  @override
  Future<List<InstallationStatus>> recent(String workspaceId) async => [];

  @override
  InstallationPreparation prepare(Artifact artifact) {
    preparations++;
    return InstallationPreparation(
      preparations <= preparationFailures
          ? Future.error(const ArtifactProblem('The archive is unavailable.'))
          : Future.value(prepared),
      () async {},
    );
  }

  @override
  Future<InstallationStatus> start(InstallationDraft draft, String id) async {
    starts.add((draft: draft, id: id));
    if (starts.length <= startFailures)
      throw const ArtifactProblem('The installation could not start.');
    return status(id, InstallationPhase.running);
  }

  @override
  Future<InstallationDraft> change(
    InstallationDraft current,
    InstallationLayoutChange change,
  ) async {
    changes.add(change);
    return draft(root: (change as InstallationRootChange).components);
  }

  @override
  Stream<InstallationStatus> watch(InstallationStatus status) => events.stream;

  @override
  Future<void> closeDraft(InstallationDraft draft) async {}
}

class _Fomod extends Fake implements FomodClient {
  bool selected = false;

  FomodChoices choices({bool review = false}) => FomodChoices(
    reference: const InstallationDraftReference('workspace', 'draft', 1),
    profileId: 'profile',
    name: 'River',
    stepName: 'Textures',
    stepNumber: 1,
    visibleSteps: 1,
    hasStep: !review,
    canBack: review,
    groups: [
      FomodGroup('Textures', FomodGroupKind.atLeastOne, [
        FomodOption(
          id: 1,
          name: 'Water',
          description: '',
          kind: FomodOptionKind.optional,
          selected: selected,
          canChange: true,
          image: const [],
        ),
      ]),
    ],
    files: const [
      InstallationReviewedFile(
        0,
        ['water.dds'],
        ['Data', 'water.dds'],
        'Water',
        4,
        [],
      ),
    ],
    reviewReady: review,
    reviewedDraft: review ? draft(installer: InstallationMode.fomod) : null,
  );

  @override
  Future<FomodChoices> open(
    InstallationDraftReference reference,
    String profileId,
  ) async => choices();

  @override
  Future<FomodChoices> choose(
    InstallationDraftReference reference,
    int optionId,
    bool selected,
  ) async {
    this.selected = selected;
    return choices();
  }

  @override
  Future<FomodChoices> next(InstallationDraftReference reference) async {
    expect(selected, isTrue);
    return choices(review: true);
  }

  @override
  Future<InstallationDraft> manual(
    InstallationDraftReference reference,
  ) async => draft();
}

Finder action(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is McAction && widget.label == label ||
      widget is McIconAction && widget.label == label,
);

Future<void> tap(WidgetTester tester, String label) async {
  final found = action(label).last;
  await tester.ensureVisible(found);
  await tester.tap(found);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<ArtifactController> browser(
  WidgetTester tester,
  _Installations installations, {
  _Artifacts? artifacts,
  FomodClient? fomod,
  Future<void> Function()? onInstalled,
  void Function(InstallationStatus)? onAttached,
  VoidCallback? onOpenMods,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(installations.events.close);
  final controller = ArtifactController();
  addTearDown(controller.dispose);
  controller.attach(artifacts ?? _Artifacts(), archive.workspaceId);
  await tester.pumpWidget(
    MaterialApp(
      theme: mcTheme(Brightness.dark),
      home: ArtifactBrowser(
        controller: controller,
        chooseFile: () async => null,
        workspacePath: '/fixture/workspace',
        installations: installations,
        fomod: fomod,
        profileId: 'profile',
        onInstalled: onInstalled,
        onInstallationAttached: onAttached,
        onOpenMods: onOpenMods,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('archive')).first);
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
    'one archive Install reaches completion and refreshes the archive',
    (tester) async {
      final installations = _Installations(), artifacts = _Artifacts();
      final attached = <InstallationStatus>[];
      var commits = 0, opened = 0;
      final controller = await browser(
        tester,
        installations,
        artifacts: artifacts,
        onAttached: attached.add,
        onInstalled: () async => commits++,
        onOpenMods: () => opened++,
      );
      await tap(tester, 'Install');
      expect(installations.starts, hasLength(1));
      final id = installations.starts.single.id;
      expect(attached.single.id, id);
      artifacts.current = const Artifact(
        id: 'archive',
        workspaceId: 'workspace',
        revision: 2,
        originalName: 'River.zip',
        originalPath: '/fixture/River.zip',
        path: '/fixture/River.zip',
        storage: ArtifactStorage.reference,
        state: ArtifactState.installed,
        links: [ArtifactLink('mod', 'version', 'River', '', installed: true)],
        canRetry: false,
        canLocate: true,
        canDeleteCopy: false,
        canRemove: true,
      );
      installations.events.add(status(id, InstallationPhase.complete));
      installations.events.add(status(id, InstallationPhase.complete));
      await tester.pumpAndSettle();
      expect(commits, 1);
      expect(artifacts.reads, 2);
      expect(controller.selected!.state, ArtifactState.installed);
      expect(controller.selected!.links.single.modId, 'mod');
      await tap(tester, 'Open Mods');
      expect(opened, 1);
    },
  );

  testWidgets('direct preparation retry still starts without a review action', (
    tester,
  ) async {
    final installations = _Installations()..preparationFailures = 1;
    await browser(tester, installations);
    await tap(tester, 'Install');
    expect(installations.starts, isEmpty);
    await tap(tester, 'Retry');
    expect(installations.preparations, 2);
    expect(installations.starts, hasLength(1));
  });

  testWidgets(
    'direct start retry retains the prepared draft and operation ID',
    (tester) async {
      final installations = _Installations()..startFailures = 1;
      await browser(tester, installations);
      await tap(tester, 'Install');
      final first = installations.starts.single;
      await tap(tester, 'Retry');
      expect(installations.preparations, 1);
      expect(installations.starts, hasLength(2));
      expect(installations.starts.last.id, first.id);
      expect(installations.starts.last.draft, same(first.draft));
    },
  );

  testWidgets('secondary install options can change the layout before start', (
    tester,
  ) async {
    final installations = _Installations();
    await browser(tester, installations);
    await tap(tester, 'Install options');
    await tap(tester, 'Change layout');
    expect(installations.starts, isEmpty);
    await tap(tester, 'Root folder');
    await tester.tap(find.text('Archive root').last);
    await tester.pumpAndSettle();
    expect(
      (installations.changes.single as InstallationRootChange).components,
      isEmpty,
    );
    await tap(tester, 'Review');
    expect(installations.starts, isEmpty);
    await tap(tester, 'Install');
    expect(installations.starts.single.draft.files.single.destination, [
      'Data',
      'water.dds',
    ]);
  });

  testWidgets(
    'direct archive action retains the FOMOD choice and install steps',
    (tester) async {
      final installations = _Installations()
        ..prepared = draft(
          installer: InstallationMode.fomod,
          canInstall: false,
        );
      final fomod = _Fomod();
      await browser(tester, installations, fomod: fomod);
      await tap(tester, 'Install');
      expect(installations.starts, isEmpty);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(fomod.selected, isTrue);
      await tap(tester, 'Review files');
      expect(installations.starts, isEmpty);
      await tap(tester, 'Install');
      expect(
        installations.starts.single.draft.installer,
        InstallationMode.fomod,
      );
      expect(installations.starts.single.draft.files.single.destination, [
        'water.dds',
      ]);
    },
  );

  testWidgets(
    'switching a direct FOMOD route to manual keeps its explicit install action',
    (tester) async {
      final installations = _Installations()
        ..prepared = draft(
          installer: InstallationMode.fomod,
          canInstall: false,
        );
      await browser(tester, installations, fomod: _Fomod());
      await tap(tester, 'Install');
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is McIconMenu<String> &&
              widget.label == 'Installer actions',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use manual layout').last);
      await tester.pumpAndSettle();
      await tap(tester, 'Use manual layout');
      expect(installations.starts, isEmpty);
      await tap(tester, 'Install');
      expect(
        installations.starts.single.draft.installer,
        InstallationMode.manual,
      );
    },
  );

  testWidgets(
    'the shared bundle review route does not start its initial draft',
    (tester) async {
      final installations = _Installations();
      addTearDown(installations.events.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.dark),
          home: ArchiveInstallationView(
            artifact: archive,
            client: installations,
            initialDraft: draft(),
            backLabel: 'Back to bundle',
            onBack: () {},
            onCommitted: () {},
            onOpenMods: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(installations.starts, isEmpty);
      await tap(tester, 'Install');
      expect(installations.starts, hasLength(1));
    },
  );
}
