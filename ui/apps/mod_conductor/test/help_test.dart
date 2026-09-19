import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

DiagnosticFinding finding({String id = 'conflict'}) => DiagnosticFinding(
  id: id,
  code: 'priority-tie',
  severity: DiagnosticSeverity.error,
  workspaceName: 'My workspace',
  profileName: 'Main',
  gameName: 'Skyrim Special Edition',
  title: 'Two copies have the same priority',
  summary: 'Mod Conductor cannot select one file copy',
  detail: null,
  area: 'Main mod files',
  evidence: const [
    DiagnosticEvidence('Target', 'meshes/marker.nif'),
    DiagnosticEvidence('First mod', '1.0 · priority 10'),
  ],
  nextAction: 'Preview a change that hides one file copy.',
  fixability: DiagnosticFixability.previewAvailable,
  fixDetail: 'Mod Conductor can fix this',
  correlations: const [
    DiagnosticCorrelation('mod-files', 'file-check-1', null),
  ],
);

class FakeDiagnostics implements DiagnosticsClient {
  FakeDiagnostics({this.checkResult});
  DiagnosticSnapshot? checkResult;
  Object? previewFailure;
  int previews = 0, applies = 0;

  @override
  Future<DiagnosticSnapshot> check({
    required String workspaceId,
    required String profileId,
    String? fileSnapshotId,
    String? pluginSnapshotId,
    String? deploymentId,
    int? deploymentRevision,
  }) async =>
      checkResult ??
      DiagnosticSnapshot(
        'check-1',
        workspaceId,
        profileId,
        DateTime.utc(2026, 9, 14),
        [finding()],
      );

  @override
  Future<DiagnosticPreview> preview(String snapshotId, String problemId) async {
    previews++;
    if (previewFailure case final failure?) throw failure;
    return DiagnosticPreview(
      'preview-1',
      snapshotId,
      problemId,
      DateTime.utc(2026, 9, 14, 0, 5),
      const [
        DiagnosticRemediationItem('Target file', 'meshes/marker.nif'),
        DiagnosticRemediationItem('Saved copy', 'First mod · 1.0'),
        DiagnosticRemediationItem('Profile setting', 'Hide this copy for Main'),
      ],
      const [
        DiagnosticRemediationIdentifier('Mod ID', 'mod-id'),
        DiagnosticRemediationIdentifier('Version ID', 'version-id'),
        DiagnosticRemediationIdentifier('Profile ID', 'profile-id'),
      ],
      'Mod Conductor will hide one file copy.',
    );
  }

  @override
  Future<DiagnosticApplyResult> apply(String previewId) async {
    applies++;
    return DiagnosticApplyResult(
      previewId,
      true,
      'Mod Conductor updated the mod files',
      'Second mod now supplies this file in the saved mod files.',
    );
  }

  @override
  Future<DiagnosticSupportReport> export(String snapshotId) =>
      throw UnimplementedError();
}

Future<DiagnosticsController> mount(
  WidgetTester tester,
  FakeDiagnostics client, {
  Size size = const Size(1280, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final controller = DiagnosticsController();
  addTearDown(controller.dispose);
  controller.attach(client, 'workspace-1', 'profile-1');
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: HelpBrowser(controller: controller)),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets(
    'wide Help reuses one sidebar, list, inspector and explicit preview',
    (tester) async {
      final client = FakeDiagnostics();
      await mount(tester, client);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Diagnostics'), findsWidgets);
      expect(find.text('FAQ'), findsOneWidget);
      expect(find.text('Guides'), findsOneWidget);
      expect(find.text('Two copies have the same priority'), findsWidgets);

      final previewAction = find.byKey(
        const ValueKey('preview-diagnostic-change'),
      );
      final opener = tester.widget<McAction>(previewAction).focusNode!;
      opener.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Hide this file copy?'), findsOneWidget);
      expect(find.text('meshes/marker.nif'), findsWidgets);
      expect(find.text('First mod · 1.0'), findsOneWidget);
      expect(find.text('Hide this copy for Main'), findsOneWidget);
      expect(find.text('mod-id'), findsNothing);
      await tester.tap(find.text('Technical details').last);
      await tester.pumpAndSettle();
      expect(find.text('mod-id'), findsOneWidget);
      expect(client.applies, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(opener.hasFocus, true);
      expect(client.applies, 0);

      await tester.tap(find.byKey(const ValueKey('preview-diagnostic-change')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(McAction, 'Hide this copy'));
      await tester.pumpAndSettle();
      expect(client.previews, 2);
      expect(client.applies, 1);
      expect(find.text('Mod Conductor updated the mod files'), findsOneWidget);
      expect(
        find.text('Second mod now supplies this file in the saved mod files.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'narrow Help uses tabs and reports stale refusal without applying',
    (tester) async {
      final client = FakeDiagnostics()
        ..previewFailure = const DiagnosticsException(DiagnosticFault.stale);
      await mount(tester, client, size: const Size(680, 800));

      expect(
        find.byWidgetPredicate((widget) => widget is SegmentedButton),
        findsOneWidget,
      );
      expect(find.byType(NavigationRail), findsNothing);
      await tester.tap(find.text('FAQ').first);
      await tester.pumpAndSettle();
      expect(find.text('What happens when I select Play?'), findsOneWidget);
      await tester.tap(find.text('Diagnostics').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.open_in_new));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('preview-diagnostic-change')));
      await tester.pumpAndSettle();
      expect(
        find.text('The selected information changed. Run Diagnostics again.'),
        findsOneWidget,
      );
      expect(client.applies, 0);
    },
  );

  test('new attachment supersedes an older in-flight check', () async {
    final first = Completer<DiagnosticSnapshot>();
    final second = Completer<DiagnosticSnapshot>();
    final client = _SequencedDiagnostics([first, second]);
    final controller = DiagnosticsController();
    addTearDown(controller.dispose);

    controller.attach(client, 'workspace-1', 'profile-1');
    controller.attach(client, 'workspace-2', 'profile-2');
    second.complete(
      DiagnosticSnapshot(
        'new',
        'workspace-2',
        'profile-2',
        DateTime.utc(2026, 9, 14),
        [finding(id: 'new')],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    first.complete(
      DiagnosticSnapshot(
        'old',
        'workspace-1',
        'profile-1',
        DateTime.utc(2026, 9, 14),
        [finding(id: 'old')],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.snapshot?.id, 'new');
  });
}

class _SequencedDiagnostics extends FakeDiagnostics {
  _SequencedDiagnostics(this.values);
  final List<Completer<DiagnosticSnapshot>> values;
  int next = 0;

  @override
  Future<DiagnosticSnapshot> check({
    required String workspaceId,
    required String profileId,
    String? fileSnapshotId,
    String? pluginSnapshotId,
    String? deploymentId,
    int? deploymentRevision,
  }) => values[next++].future;
}
