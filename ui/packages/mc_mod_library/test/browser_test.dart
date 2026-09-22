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

class MovingClient extends SelectionClient {
  late Future<ProfileModsDelta> Function(
    int revision,
    List<String> ids,
    ProfileModMove direction,
  )
  onMove;

  @override
  Future<ProfileModsDelta> move(
    String profile,
    int revision,
    Iterable<String> ids,
    ProfileModMove direction,
  ) => onMove(revision, ids.toList(), direction);
}

void main() {
  testWidgets(
    'active receipt state is local and clears after the operation ends',
    (tester) async {
      const operation = LibraryOperation(
        id: '11111111111111111111111111111111',
        workspaceId: 'workspace',
        kind: LibraryOperationKind.publication,
        actions: [LibraryOperationAction.wait, LibraryOperationAction.cancel],
      );
      final client = LibraryClient()
        ..onQuery = (_, _) async => inventoryPage([mod('one')], null);
      final selection = MovingClient()
        ..onMove = (_, _, _) async => throw const LibraryException(
          LibraryFault.busy,
          'A library change is still in progress.',
          activeOperation: operation,
        );
      final controller = ModLibraryController();
      addTearDown(controller.dispose);
      controller.attach(
        client,
        selection,
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
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      controller.mods.select((modId: 'one'));
      await controller.inventory.move(ProfileModMove.up);
      await tester.pump();
      expect(find.byType(McActionFeedback), findsOneWidget);
      expect(controller.inventory.activeOperation, same(operation));
      expect(controller.inventory.problem, isNull);

      selection.onMove = (_, _, _) async =>
          const ProfileModsDelta(1, [ManagedProfileMod('one', 0, false)], 0);
      client.onQuery = (_, _) async => queryPage([
        OrganizedMod(
          ProfileMod(mod('one'), const ManagedProfileMod('one', 0, false)),
          null,
        ),
      ], revision: 1);
      await controller.inventory.move(ProfileModMove.up);
      await tester.pump();
      expect(find.byType(McActionFeedback), findsNothing);
      expect(controller.inventory.activeOperation, isNull);
    },
  );

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
}
