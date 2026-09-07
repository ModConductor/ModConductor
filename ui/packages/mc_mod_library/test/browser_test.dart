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
    return mod(id);
  }
}

void main() {
  testWidgets(
    'native folder choice submits through the feature client and updates the inventory',
    (tester) async {
      final client = FolderClient()
        ..onInventory = (_, _) async => const InventoryPage([], null);
      final controller = ModLibraryController();
      addTearDown(controller.dispose);
      controller.attach(
        client,
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
