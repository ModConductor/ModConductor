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
  arrivalOrder: 30,
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
  List<Artifact>? entries;
  Completer<ArtifactPage>? nextPage;
  int reads = 0;

  @override
  Future<ArtifactPage> list(
    String workspaceId, {
    String? after,
    bool refresh = false,
  }) async {
    reads++;
    final pending = nextPage;
    nextPage = null;
    return pending == null
        ? ArtifactPage(entries ?? [current], null)
        : pending.future;
  }
}

class _Installations extends Fake implements InstallationsClient {
  InstallationDraft prepared = draft();
  InstallationDraft Function(Artifact)? preparedFor;
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
          : Future.value(preparedFor?.call(artifact) ?? prepared),
      () async {},
    );
  }

  @override
  Future<InstallationStatus> start(InstallationDraft draft, String id) async {
    starts.add((draft: draft, id: id));
    if (starts.length <= startFailures)
      throw const ArtifactProblem('The installation could not start.');
    return queueStatus(draft.artifactId, id, InstallationPhase.running);
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

class _Bain extends Fake implements BainClient {
  BainChoices choices(bool review) => BainChoices(
    reference: const InstallationDraftReference('workspace', 'draft', 1),
    packages: const [BainPackage(0, 'Textures', 1, 4, true)],
    files: const [
      InstallationReviewedFile(
        0,
        ['water.dds'],
        ['Data', 'water.dds'],
        'Textures',
        4,
        [],
      ),
    ],
    reviewing: review,
    hasNotes: false,
    reviewedDraft: review ? draft(installer: InstallationMode.bain) : null,
  );

  @override
  Future<BainChoices> open(InstallationDraftReference reference) async =>
      choices(false);
  @override
  Future<BainChoices> review(InstallationDraftReference reference) async =>
      choices(true);
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
  BainClient? bain,
  Future<bool> Function()? onQueueInstalled,
  Future<void> Function()? onInstalled,
  void Function(InstallationStatus)? onAttached,
  VoidCallback? onOpenMods,
  void Function(InstallationStatus)? onDetached,
  ValueNotifier<String>? profile,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(installations.events.close);
  final controller = ArtifactController();
  addTearDown(controller.dispose);
  controller.attach(artifacts ?? _Artifacts(), archive.workspaceId);
  final selectedProfile = profile ?? ValueNotifier('profile');
  if (profile == null) addTearDown(selectedProfile.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: mcTheme(Brightness.dark),
      home: ValueListenableBuilder<String>(
        valueListenable: selectedProfile,
        builder: (_, profile, _) => ArtifactBrowser(
          controller: controller,
          chooseFile: () async => null,
          workspacePath: '/fixture/workspace',
          installations: installations,
          fomod: fomod,
          bain: bain,
          onQueueInstalled: onQueueInstalled,
          profileId: profile,
          onInstallationDetached: onDetached,
          onInstalled: onInstalled,
          onInstallationAttached: onAttached,
          onOpenMods: onOpenMods,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('archive')).first);
  await tester.pumpAndSettle();
  return controller;
}

Artifact queueArchive(
  String id,
  int order, {
  ArtifactState state = ArtifactState.ready,
}) => Artifact(
  id: id,
  workspaceId: archive.workspaceId,
  revision: 1,
  arrivalOrder: order,
  originalName: '$id.zip',
  originalPath: '/fixture/$id.zip',
  path: '/fixture/$id.zip',
  storage: ArtifactStorage.reference,
  state: state,
  links: const [],
  canRetry: false,
  canLocate: true,
  canDeleteCopy: false,
  canRemove: true,
);

InstallationDraft queueDraft(Artifact artifact, {bool canInstall = true}) =>
    InstallationDraft(
      id: 'draft-${artifact.id}',
      workspaceId: artifact.workspaceId,
      revision: 0,
      artifactId: artifact.id,
      archiveName: artifact.originalName,
      manifest: draft().manifest,
      root: const ['Data'],
      files: draft().files,
      name: artifact.id,
      version: '',
      bytes: 4,
      canInstall: canInstall,
    );

InstallationStatus queueStatus(
  String artifactId,
  String id,
  InstallationPhase phase,
) => InstallationStatus(
  id: id,
  workspaceId: archive.workspaceId,
  artifactId: artifactId,
  archiveName: '$artifactId.zip',
  name: artifactId,
  version: '',
  phase: phase,
  files: phase == InstallationPhase.complete ? 1 : 0,
  totalFiles: 1,
  bytes: phase == InstallationPhase.complete ? 4 : 0,
  totalBytes: 4,
);

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
    'checked hidden archives run newest first only after committed refresh and duplicate completion is harmless',
    (tester) async {
      final older = queueArchive('older', 10),
          middle = queueArchive('middle', 20);
      final artifacts = _Artifacts()..entries = [older, archive, middle];
      final installations = _Installations()..preparedFor = queueDraft;
      final committed = Completer<void>(), page = Completer<ArtifactPage>();
      final controller = await browser(
        tester,
        installations,
        artifacts: artifacts,
        onInstalled: () => committed.future,
      );
      controller.check(older, true);
      controller.check(archive, true);
      controller.check(middle, true);
      controller.model.filter('River');
      await tester.pumpAndSettle();
      final submit = tester.widget<McAction>(action('Install all')).onPressed!;
      submit();
      submit();
      await tester.pumpAndSettle();
      expect(installations.starts.map((start) => start.draft.artifactId), [
        'archive',
      ]);
      final id = installations.starts.single.id;
      artifacts.nextPage = page;
      installations.events.add(status(id, InstallationPhase.complete));
      installations.events.add(status(id, InstallationPhase.complete));
      installations.events.add(status(id, InstallationPhase.stopped));
      await tester.pumpAndSettle();
      expect(installations.starts, hasLength(1));
      expect(controller.checked, {'middle', 'older'});
      committed.complete();
      await tester.pumpAndSettle();
      expect(artifacts.reads, 2);
      expect(installations.starts, hasLength(1));
      page.complete(ArtifactPage([older, archive, middle], null));
      await tester.pumpAndSettle();
      expect(installations.starts.map((start) => start.draft.artifactId), [
        'archive',
        'middle',
      ]);
      // A late terminal observation from the previous operation cannot complete this item.
      installations.events.add(status(id, InstallationPhase.complete));
      await tester.pumpAndSettle();
      expect(installations.starts, hasLength(2));
      final second = installations.starts.last;
      installations.events.add(
        queueStatus('middle', second.id, InstallationPhase.complete),
      );
      await tester.pumpAndSettle();
      expect(installations.starts.map((start) => start.draft.artifactId), [
        'archive',
        'middle',
        'older',
      ]);
    },
  );

  for (final mode in [InstallationMode.fomod, InstallationMode.bain]) {
    testWidgets(
      '$mode choices pause the queue until explicit review and install complete',
      (tester) async {
        final older = queueArchive('older', 10);
        final installations = _Installations()
          ..preparedFor = (artifact) => artifact.id == 'archive'
              ? draft(installer: mode, canInstall: false)
              : queueDraft(artifact);
        final controller = await browser(
          tester,
          installations,
          artifacts: _Artifacts()..entries = [archive, older],
          fomod: _Fomod(),
          bain: _Bain(),
        );
        controller.check(archive, true);
        controller.check(older, true);
        await tester.pumpAndSettle();
        await tap(tester, 'Install all');
        expect(installations.starts, isEmpty);
        if (mode == InstallationMode.fomod) {
          await tester.tap(find.byType(CheckboxListTile));
          await tester.pumpAndSettle();
        }
        await tap(tester, 'Review files');
        expect(installations.starts, isEmpty);
        await tap(tester, 'Install');
        expect(installations.starts.single.draft.installer, mode);
        installations.events.add(
          status(installations.starts.single.id, InstallationPhase.complete),
        );
        await tester.pumpAndSettle();
        expect(installations.starts.map((start) => start.draft.artifactId), [
          'archive',
          'older',
        ]);
      },
    );
  }

  testWidgets(
    'failed installed-mod refresh cannot admit the next queued archive',
    (tester) async {
      final older = queueArchive('older', 10);
      final installations = _Installations()..preparedFor = queueDraft;
      final refreshed = Completer<bool>();
      final controller = await browser(
        tester,
        installations,
        artifacts: _Artifacts()..entries = [archive, older],
        onQueueInstalled: () => refreshed.future,
      );
      controller.check(archive, true);
      controller.check(older, true);
      await tester.pumpAndSettle();
      await tap(tester, 'Install all');
      installations.events.add(
        status(installations.starts.single.id, InstallationPhase.complete),
      );
      await tester.pumpAndSettle();
      refreshed.complete(false);
      await tester.pumpAndSettle();
      expect(installations.starts, hasLength(1));
      expect(controller.checked, {'older'});
    },
  );

  testWidgets('checkboxes do not inspect or include unavailable archives', (
    tester,
  ) async {
    final other = queueArchive('other', 10),
        missing = queueArchive('missing', 20, state: ArtifactState.detached);
    final artifacts = _Artifacts()..entries = [archive, other, missing];
    final installations = _Installations()..preparedFor = queueDraft;
    final controller = await browser(
      tester,
      installations,
      artifacts: artifacts,
    );
    final checkbox = find.byWidgetPredicate(
      (widget) =>
          widget is Checkbox &&
          widget.semanticLabel == 'Select other.zip for installation',
    );
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(controller.selected!.id, archive.id);
    expect(controller.checked, {'other'});
    controller.check(missing, true);
    await tap(tester, 'Install all');
    expect(installations.starts.single.draft.artifactId, 'other');
  });

  testWidgets(
    'a failed queued start can retry the same operation without advancing pending archives',
    (tester) async {
      final older = queueArchive('older', 10);
      final installations = _Installations()
        ..preparedFor = queueDraft
        ..startFailures = 1;
      final controller = await browser(
        tester,
        installations,
        artifacts: _Artifacts()..entries = [archive, older],
      );
      controller.check(archive, true);
      controller.check(older, true);
      await tester.pumpAndSettle();
      await tap(tester, 'Install all');
      final first = installations.starts.single;
      expect(controller.checked, {'archive', 'older'});
      await tap(tester, 'Retry');
      expect(installations.starts.last.id, first.id);
      installations.events.add(status(first.id, InstallationPhase.complete));
      await tester.pumpAndSettle();
      expect(installations.starts, hasLength(2));
      expect(controller.checked, {'older'});
      await tap(tester, 'Back to archives');
      expect(controller.checked, {'older'});
    },
  );

  for (final interruption in ['cancel', 'observation', 'refresh']) {
    testWidgets(
      '$interruption failure stops the queue and preserves pending selection',
      (tester) async {
        final older = queueArchive('older', 10);
        final artifacts = _Artifacts()..entries = [archive, older];
        final installations = _Installations()..preparedFor = queueDraft;
        final controller = await browser(
          tester,
          installations,
          artifacts: artifacts,
        );
        controller.check(archive, true);
        controller.check(older, true);
        await tester.pumpAndSettle();
        await tap(tester, 'Install all');
        final id = installations.starts.single.id;
        if (interruption == 'observation') {
          installations.events.addError(
            const ArtifactProblem('Progress unavailable'),
          );
        } else if (interruption == 'refresh') {
          final failed = Completer<ArtifactPage>();
          artifacts.nextPage = failed;
          installations.events.add(status(id, InstallationPhase.complete));
          await tester.pump();
          failed.completeError(const ArtifactProblem('Refresh failed'));
        } else {
          installations.events.add(status(id, InstallationPhase.stopped));
        }
        await tester.pumpAndSettle();
        expect(installations.starts, hasLength(1));
        expect(controller.checked, contains('older'));
        await tap(tester, 'Back to archives');
        expect(controller.checked, contains('older'));
      },
    );
  }

  for (final navigation in [
    'stop',
    'back',
    'profile',
    'workspace',
    'dispose',
  ]) {
    testWidgets(
      '$navigation during committed refresh cannot launch another queued archive',
      (tester) async {
        final older = queueArchive('older', 10), committed = Completer<void>();
        final artifacts = _Artifacts()..entries = [archive, older];
        final installations = _Installations()..preparedFor = queueDraft;
        final profile = ValueNotifier('profile');
        addTearDown(profile.dispose);
        final controller = await browser(
          tester,
          installations,
          artifacts: artifacts,
          profile: profile,
          onInstalled: () => committed.future,
        );
        controller.check(archive, true);
        controller.check(older, true);
        await tester.pumpAndSettle();
        await tap(tester, 'Install all');
        installations.events.add(
          status(installations.starts.single.id, InstallationPhase.complete),
        );
        await tester.pumpAndSettle();
        switch (navigation) {
          case 'stop':
            await tap(tester, 'Stop queue');
          case 'back':
            await tap(tester, 'Back to archives');
          case 'profile':
            profile.value = 'another';
            await tester.pumpAndSettle();
          case 'workspace':
            controller.attach(_Artifacts(), 'another');
            await tester.pumpAndSettle();
          case 'dispose':
            await tester.pumpWidget(const SizedBox.shrink());
        }
        committed.complete();
        await tester.pumpAndSettle();
        expect(installations.starts, hasLength(1));
        if (navigation != 'workspace') expect(controller.checked, {'older'});
      },
    );
  }

  testWidgets(
    'back during an accepted queued operation detaches it without cancelling or launching pending work',
    (tester) async {
      final older = queueArchive('older', 10);
      final installations = _Installations()..preparedFor = queueDraft;
      final detached = <InstallationStatus>[];
      final controller = await browser(
        tester,
        installations,
        artifacts: _Artifacts()..entries = [archive, older],
        onDetached: detached.add,
      );
      controller.check(archive, true);
      controller.check(older, true);
      await tester.pumpAndSettle();
      await tap(tester, 'Install all');
      final id = installations.starts.single.id;
      await tap(tester, 'Back to archives');
      expect(detached.single.id, id);
      installations.events.add(status(id, InstallationPhase.complete));
      await tester.pumpAndSettle();
      expect(installations.starts, hasLength(1));
      expect(controller.checked, {'archive', 'older'});
    },
  );

  testWidgets(
    'an ambiguous manual queue item waits without starting or dropping pending selection',
    (tester) async {
      final older = queueArchive('older', 10);
      final installations = _Installations()
        ..preparedFor = (artifact) =>
            queueDraft(artifact, canInstall: artifact.id != 'archive');
      final controller = await browser(
        tester,
        installations,
        artifacts: _Artifacts()..entries = [archive, older],
      );
      controller.check(archive, true);
      controller.check(older, true);
      await tester.pumpAndSettle();
      await tap(tester, 'Install all');
      expect(installations.starts, isEmpty);
      expect(controller.checked, {'archive', 'older'});
      await tap(tester, 'Back to archives');
      expect(installations.starts, isEmpty);
    },
  );

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
