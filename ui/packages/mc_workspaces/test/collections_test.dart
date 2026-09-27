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
  testWidgets('narrow profile cards keep actions reachable', (tester) async {
    tester.view.physicalSize = const Size(380, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ProfilesClient();
    final controller = WorkspaceController()..attach(client);
    addTearDown(controller.dispose);
    await controller.open('/workspace');
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: Scaffold(body: WorkspaceBrowser(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('use-profile-a')));
    await tester.pumpAndSettle();
    expect(controller.workspace!.selectedProfile!.id, 'a');
  });

  testWidgets(
    'card keyboard navigation and menu keep profile selection separate from activation',
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
      Focus.of(tester.element(find.byKey(const ValueKey('profile-card-a'))))
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      final collection = tester.widget<McCardGrid<ProfileRowId, ProfileInfo>>(
        find.byType(McCardGrid<ProfileRowId, ProfileInfo>),
      );
      expect(collection.model.selectedId, (profileId: 'b'));
      expect(client.selections, 0);
      expect(controller.workspace!.selectedProfile!.id, 'outside');
      expect(
        tester
            .widget<McPortraitCard>(
              find.byKey(const ValueKey('profile-card-b')),
            )
            .badge,
        'Selected',
      );
      await tester.tap(find.byKey(const ValueKey('use-profile-b')));
      await tester.pumpAndSettle();
      expect(client.selections, 1);
      expect(controller.workspace!.selectedProfile!.id, 'b');
      expect(
        tester
            .widget<McPortraitCard>(
              find.byKey(const ValueKey('profile-card-b')),
            )
            .badge,
        'Active',
      );
      expect(
        tester
            .widget<McAction>(find.byKey(const ValueKey('use-profile-b')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('profile-menu-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(collection.model.focusedId, (profileId: 'b'));
      await controller.refresh();
      await tester.pumpAndSettle();
      expect(collection.model.focusedId, (profileId: 'b'));
      expect(collection.model.selectedId, (profileId: 'b'));
      expect(controller.workspace!.selectedProfile!.id, 'b');
      final filter = find.descendant(
        of: find.byType(McCardGrid<ProfileRowId, ProfileInfo>),
        matching: find.byType(TextField),
      );
      await tester.enterText(filter, 'B profile');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-card-a')), findsNothing);
      expect(find.byKey(const ValueKey('profile-card-b')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('profile selection waits for the open editor navigation guard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetPhysicalSize);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ProfilesClient();
    final controller = WorkspaceController()..attach(client);
    addTearDown(controller.dispose);
    await controller.open('/workspace');
    var allowNavigation = false, guardCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: Scaffold(
          body: WorkspaceBrowser(
            controller: controller,
            profileInspectorBuilder:
                (context, workspace, profile, close, bindGuard) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    bindGuard((navigate) async {
                      guardCalls++;
                      if (!allowNavigation) return false;
                      await navigate();
                      return true;
                    });
                  });
                  return Text('Inspecting ${profile.name}');
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey((profileId: 'a'))));
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('profile-card-a')),
        matching: find.text('Settings and saves'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Inspecting A profile'), findsOneWidget);
    await controller.moreProfiles();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey((profileId: 'b'))));
    await tester.pumpAndSettle();
    final collection = tester.widget<McCardGrid<ProfileRowId, ProfileInfo>>(
      find.byType(McCardGrid<ProfileRowId, ProfileInfo>),
    );
    expect(guardCalls, 1);
    expect(collection.model.selectedId, (profileId: 'a'));
    expect(find.text('Inspecting A profile'), findsOneWidget);

    allowNavigation = true;
    await tester.tap(find.byKey(const ValueKey((profileId: 'b'))));
    await tester.pumpAndSettle();
    expect(guardCalls, 2);
    expect(collection.model.selectedId, (profileId: 'b'));
    expect(find.text('Inspecting B profile'), findsOneWidget);
  });

  testWidgets('compact profile drawer dismissal uses the editor guard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ProfilesClient();
    final controller = WorkspaceController()..attach(client);
    addTearDown(controller.dispose);
    await controller.open('/workspace');
    var allowNavigation = false, guardCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: Scaffold(
          body: WorkspaceBrowser(
            controller: controller,
            profileInspectorBuilder:
                (context, workspace, profile, close, bindGuard) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    bindGuard((navigate) async {
                      guardCalls++;
                      if (!allowNavigation) return false;
                      await navigate();
                      return true;
                    });
                  });
                  return Text('Editing ${profile.name}');
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey((profileId: 'a'))));
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('profile-card-a')),
        matching: find.text('Settings and saves'),
      ),
    );
    await tester.pumpAndSettle();
    final drawerScaffold = tester.state<ScaffoldState>(
      find.byWidgetPredicate(
        (widget) => widget is Scaffold && widget.endDrawer != null,
      ),
    );
    expect(drawerScaffold.isEndDrawerOpen, isTrue);

    drawerScaffold.closeEndDrawer();
    await tester.pumpAndSettle();
    expect(guardCalls, 1);
    expect(drawerScaffold.isEndDrawerOpen, isTrue);
    expect(find.text('Editing A profile'), findsOneWidget);

    allowNavigation = true;
    drawerScaffold.closeEndDrawer();
    await tester.pumpAndSettle();
    expect(guardCalls, 2);
    expect(drawerScaffold.isEndDrawerOpen, isFalse);
    expect(find.text('Editing A profile'), findsNothing);
    expect(
      FocusManager.instance.primaryFocus?.context?.widget.key,
      const ValueKey((profileId: 'a')),
    );
  });
}
