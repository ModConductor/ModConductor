import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller_test.dart';

class FolderClient extends LibraryClient {
  int registrations = 0;
  @override
  Future<ModEntry> register(
    String workspaceId,
    String id,
    ModMetadata metadata,
    ModRegistration registration,
  ) async {
    registrations++;
    expect(workspaceId, 'workspace');
    expect((registration as NativeDirectoryMod).path, '/workspace/source');
    final entry = mod(id);
    onQuery = (_, _) async => inventoryPage([entry], null);
    return entry;
  }
}

class PendingDeletionClient extends Fake implements MaintenanceClient {
  final pending = Completer<void>();
  ModEntry? target;

  @override
  Future<void> deleteMod(ModEntry value) async {
    target = value;
    await pending.future;
  }
}

void main() {
  testWidgets(
    'native folder choice submits through the feature client and updates the inventory',
    (tester) async {
      final client = FolderClient()
        ..onQuery = (_, _) async => inventoryPage([], null);
      final controller = ModLibraryController();
      addTearDown(controller.dispose);
      controller.attach(
        client,
        SelectionClient(),
        organizationClient: organization(client),
        workspaceId: 'workspace',
        profileId: 'profile',
        editable: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Scaffold(
            body: ModLibraryBrowser(
              controller: controller,
              workspacePath: '/workspace',
              chooseDirectory: (_) async => '/workspace/source',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-mod')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('name')), 'Mod');
      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(client.registrations, 1);
      expect(controller.mods.length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('delete confirms the selected mod and stays pending in front', (
    tester,
  ) async {
    final entry = mod('mod', revision: 4);
    final library = FolderClient()
      ..onQuery = (_, _) async => inventoryPage([entry], null);
    final maintenance = PendingDeletionClient();
    final controller = ModLibraryController();
    addTearDown(controller.dispose);
    controller.attach(
      library,
      SelectionClient(),
      organizationClient: organization(library),
      workspaceId: 'workspace',
      profileId: 'profile',
      editable: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: Scaffold(
          body: ModLibraryBrowser(
            controller: controller,
            workspacePath: '/workspace',
            maintenance: maintenance,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey((modId: 'mod'))));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is McIconAction && widget.label == 'Delete mod',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete Mod mod?'), findsOneWidget);
    await tester.tap(find.widgetWithText(McAction, 'Delete'));
    await tester.pump();

    expect(maintenance.target, same(entry));
    expect(find.byKey(const ValueKey('mod-deletion-status')), findsOneWidget);
    expect(find.text('Deleting Mod mod'), findsOneWidget);
    expect(find.text('Back to mod'), findsNothing);
    expect(find.text('Open Mods'), findsNothing);

    maintenance.pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Mod mod deleted'), findsOneWidget);
    expect(find.text('Open Mods'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
