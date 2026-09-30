import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

const target = WorkspaceInfo(
  id: 'one',
  name: 'Weekend',
  path: '/fixture/one',
  revision: 4,
);

class DeletionClient extends Fake implements WorkspacesClient {
  List<WorkspaceInfo> saved = [target];
  bool moveRequested = false;
  int attempts = 0;
  bool failOnce = false;
  Completer<void>? pending;
  bool failInformationOnce = false;
  int informationAttempts = 0;
  Completer<WorkspaceDeletionInfo>? information;

  @override
  Future<WorkspaceList> recent({String? after}) async =>
      WorkspaceList(List.of(saved), null);
  @override
  Future<WorkspacePage> open(String path) async =>
      const WorkspacePage(target, [], null);
  @override
  Future<WorkspaceDeletionInfo> deletionInfo(String workspace) async {
    ++informationAttempts;
    if (failInformationOnce && informationAttempts == 1) {
      throw const WorkspaceException(
        WorkspaceFault.busy,
        'Workspace information is unavailable. Try again.',
      );
    }
    if (information != null) return information!.future;
    return const WorkspaceDeletionInfo(
      hasPrivateSaves: true,
      saveDestinations: ['/fixture/game/Saves'],
    );
  }

  @override
  Future<void> deleteWorkspace(
    String workspace,
    int revision, {
    bool moveSaves = false,
  }) async {
    ++attempts;
    moveRequested = moveSaves;
    if (failOnce && attempts == 1) {
      throw const WorkspaceException(
        WorkspaceFault.busy,
        'Finish the current game operation and try again.',
      );
    }
    await pending?.future;
    saved = saved.where((item) => item.id != workspace).toList();
  }
}

Future<void> mount(WidgetTester tester, WorkspaceController controller) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: mcTheme(Brightness.dark),
      home: Scaffold(body: WorkspaceBrowser(controller: controller)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> confirm(
  WidgetTester tester, {
  bool waitForInformation = true,
}) async {
  await tester.tap(find.byType(McIconMenu<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete workspace'));
  if (waitForInformation) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  testWidgets(
    'pending save information does not queue deletion before the move choice is available',
    (tester) async {
      final client = DeletionClient()
        ..information = Completer<WorkspaceDeletionInfo>();
      final controller = WorkspaceController()..attach(client);
      addTearDown(controller.dispose);
      await mount(tester, controller);
      await confirm(tester, waitForInformation: false);
      await tester.tap(find.widgetWithText(McAction, 'Delete workspace'));
      await tester.pump();
      client.information!.complete(
        const WorkspaceDeletionInfo(
          hasPrivateSaves: true,
          saveDestinations: ['/fixture/game/Saves'],
        ),
      );
      await tester.pumpAndSettle();
      expect(client.attempts, 0);
      expect(controller.recent.single.id, target.id);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(McAction, 'Delete workspace'));
      await tester.pumpAndSettle();
      expect(client.attempts, 1);
      expect(client.moveRequested, true);
      expect(controller.recent, isEmpty);
    },
  );

  testWidgets(
    'retrying failed save information reveals the choice without submitting deletion',
    (tester) async {
      final client = DeletionClient()..failInformationOnce = true;
      final controller = WorkspaceController()..attach(client);
      addTearDown(controller.dispose);
      await mount(tester, controller);
      await confirm(tester);
      client.information = Completer<WorkspaceDeletionInfo>();
      await tester.tap(find.widgetWithText(McAction, 'Delete workspace'));
      await tester.pump();
      expect(client.informationAttempts, 2);
      client.information!.complete(
        const WorkspaceDeletionInfo(
          hasPrivateSaves: true,
          saveDestinations: ['/fixture/game/Saves'],
        ),
      );
      await tester.pumpAndSettle();
      expect(client.attempts, 0);
      expect(controller.recent.single.id, target.id);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(McAction, 'Delete workspace'));
      await tester.pumpAndSettle();
      expect(client.attempts, 1);
      expect(client.moveRequested, true);
      expect(controller.recent, isEmpty);
    },
  );

  testWidgets(
    'current workspace deletion moves selected saves and returns to the updated browser without another confirmation',
    (tester) async {
      final client = DeletionClient();
      final controller = WorkspaceController()..attach(client);
      addTearDown(controller.dispose);
      await controller.open(target.path);
      await mount(tester, controller);
      await confirm(tester);
      expect(client.attempts, 0);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(McAction, 'Delete workspace'));
      await tester.pumpAndSettle();
      expect(client.moveRequested, true);
      expect(client.attempts, 1);
      expect(controller.showingWorkspace, false);
      expect(controller.recent, isEmpty);
      expect(find.byKey(const ValueKey('workspace-one')), findsNothing);
      expect(find.text('Workspaces'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recent workspace deletion keeps the confirmation retryable after failure and updates immediately after commit',
    (tester) async {
      final client = DeletionClient()..failOnce = true;
      final controller = WorkspaceController()..attach(client);
      addTearDown(controller.dispose);
      await mount(tester, controller);
      await confirm(tester);
      await tester.tap(find.widgetWithText(McAction, 'Delete workspace'));
      await tester.pumpAndSettle();
      expect(client.attempts, 1);
      expect(controller.recent.single.id, target.id);
      expect(
        find.text('Finish the current game operation and try again.'),
        findsWidgets,
      );
      expect(find.widgetWithText(McAction, 'Delete workspace'), findsOneWidget);
      client.pending = Completer<void>();
      await tester.tap(find.widgetWithText(McAction, 'Delete workspace'));
      await tester.pump();
      expect(controller.recent.single.id, target.id);
      client.pending!.complete();
      await tester.pumpAndSettle();
      expect(client.attempts, 2);
      expect(client.moveRequested, false);
      expect(controller.recent, isEmpty);
      expect(find.byKey(const ValueKey('workspace-one')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancelling workspace deletion preserves the workspace and never calls deletion',
    (tester) async {
      final client = DeletionClient();
      final controller = WorkspaceController()..attach(client);
      addTearDown(controller.dispose);
      await mount(tester, controller);
      await confirm(tester);
      await tester.tap(find.widgetWithText(McAction, 'Cancel'));
      await tester.pumpAndSettle();
      expect(client.attempts, 0);
      expect(controller.recent.single.id, target.id);
      expect(find.byKey(const ValueKey('workspace-one')), findsOneWidget);
    },
  );
}
