import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

class ProfilesClient extends Fake implements WorkspacesClient {
  int selections = 0;
  int revision = 0;
  ProfileInfo current = const ProfileInfo('outside', 'Current outside page');
  final first = const ProfileInfo('a', 'A profile');
  final second = const ProfileInfo('b', 'B profile');
  WorkspaceInfo get workspace => WorkspaceInfo(
    id: 'workspace',
    name: 'Workspace',
    path: '/workspace',
    revision: revision,
    selectedProfile: current,
  );
  @override
  Future<WorkspaceList> recent({String? after}) async =>
      const WorkspaceList([], null);
  @override
  Future<WorkspacePage> open(String path) async =>
      WorkspacePage(workspace, [first], 'a');
  @override
  Future<WorkspacePage> read(String id, {String? after}) async => WorkspacePage(
    workspace,
    after == null ? [first] : [second],
    after == null ? 'a' : null,
  );
  @override
  Future<ProfileChange> selectProfile(
    String workspaceId,
    int expected,
    String id,
  ) async {
    expect(expected, revision);
    selections++;
    revision++;
    current = id == first.id ? first : second;
    return ProfileChange(workspace, null, null);
  }
}

void main() {
  testWidgets(
    'row navigation does not change the current profile and a menu dialog returns to its selected row',
    (tester) async {
      final client = ProfilesClient();
      final controller = WorkspaceController()..attach(client);
      addTearDown(controller.dispose);
      await controller.open('/workspace');
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.dark),
          home: Scaffold(body: WorkspaceBrowser(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey((profileId: 'a'))));
      await tester.pump();
      await controller.moreProfiles();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      final collection = tester.widget<McCollection<ProfileRowId, ProfileInfo>>(
        find.byType(McCollection<ProfileRowId, ProfileInfo>),
      );
      expect(collection.model.selectedId, (profileId: 'b'));
      expect(client.selections, 0);
      expect(controller.workspace!.selectedProfile!.id, 'outside');
      await tester.tap(find.byKey(const ValueKey('use-profile')));
      await tester.pumpAndSettle();
      expect(client.selections, 1);
      expect(controller.workspace!.selectedProfile!.id, 'b');
      await tester.tap(find.byKey(const ValueKey('profile-menu-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(collection.focusNode!.hasFocus, isTrue);
      expect(collection.model.focusedId, (profileId: 'b'));
      await controller.refresh();
      await tester.pumpAndSettle();
      expect(collection.model.focusedId, (profileId: 'b'));
      expect(collection.model.selectedId, (profileId: 'b'));
      expect(controller.workspace!.selectedProfile!.id, 'b');
      expect(tester.takeException(), isNull);
    },
  );
}
