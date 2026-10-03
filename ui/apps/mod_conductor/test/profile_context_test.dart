import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_profile_data/mc_profile_data.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_workspaces/mc_workspaces.dart';
import 'package:mod_conductor/src/app.dart';

const profiles = [
  ProfileInfo('nv', 'A New Vegas'),
  ProfileInfo('fo76', 'B Fallout 76'),
  ProfileInfo('unbound', 'C No game'),
];
const workspace = WorkspaceInfo(
  id: 'workspace',
  name: 'Workspace',
  path: '/workspace',
  revision: 1,
  selectedProfile: ProfileInfo('nv', 'A New Vegas'),
);

GameDefinitionInfo definition(String id, String name, String saves) =>
    GameDefinitionInfo(
      id: id,
      revision: 1,
      name: name,
      storefront: 'Steam',
      declaredSteamAppId: 1,
      saveExtension: saves,
      artworkUrl: 'https://example.invalid/$id.jpg',
      capabilities: [
        GameCapability(
          id: GameCapabilityId.bethesdaGame,
          revision: 1,
          name: 'Bethesda game',
          kind: GameCapabilityKind.gameAdapter,
          contexts: [
            GameCapabilityContext(
              definitionId: id,
              platforms: [GameContextPlatform.windows],
            ),
          ],
          disposition: GameCapabilityDisposition.available,
        ),
      ],
    );

final nv = definition('new-vegas-steam', 'Fallout: New Vegas', '.fos');
final fo76 = definition('fallout76-steam', 'Fallout 76', '');

GameContextState contextFor(String workspace, String profile) {
  final game = switch (profile) {
    'nv' => nv,
    'fo76' => fo76,
    _ => null,
  };
  return GameContextState(
    workspaceId: workspace,
    profileId: profile,
    revision: 1,
    definition: game,
    binding: game == null
        ? null
        : GameBindingInfo(
            id: 'binding-$profile',
            path: '/games/$profile',
            needsCheck: false,
            evidence: GameInstallationEvidence(
              definitionId: game.id,
              definitionRevision: 1,
              platform: GameContextPlatform.windows,
              rootPath: '/games/$profile',
              dataPath: '/games/$profile/Data',
              executable: GameExecutableEvidence(
                path: '/games/$profile/Game.exe',
                sha256: 'hash',
                length: 1,
                fileVersion: '1',
                productVersion: '1',
              ),
              launcherPath: null,
              documents: const UnavailableGameLocation('fixture'),
              saves: const UnavailableGameLocation('fixture'),
              localAppData: const UnavailableGameLocation('fixture'),
              problems: const [],
              checkedAt: DateTime.utc(2026),
              fingerprint: profile,
            ),
          ),
  );
}

class Contexts extends Fake implements GameContextsClient {
  bool unavailable = false;
  @override
  Future<GameContextState> read(String workspace, String profile) async =>
      unavailable && profile == 'fo76'
      ? throw const GameContextException(
          GameContextFailure.workspaceUnavailable,
          'The profile context is unavailable.',
        )
      : contextFor(workspace, profile);
}

class Workspaces extends Fake implements WorkspacesClient {
  @override
  Future<WorkspaceList> recent({String? after}) async =>
      const WorkspaceList([workspace], null);
  @override
  Future<WorkspacePage> open(String path) async =>
      const WorkspacePage(workspace, profiles, null);
  @override
  Future<WorkspacePage> read(String id, {String? after}) async =>
      WorkspacePage(workspace, List.of(profiles), null);
}

class ProfileData extends Fake implements ProfileDataClient {
  @override
  Future<ProfileDataState> read(String workspace, String profile) async =>
      ProfileDataState(
        reference: ProfileDataRef(
          workspaceId: workspace,
          profileId: profile,
          contextId: profile,
          revision: 1,
        ),
        options: const ProfileDataOptions(settings: false, saves: false),
        settingsPath: '',
        savesPath: '',
        settingsFiles: 0,
        saveFiles: 0,
      );
}

void main() {
  testWidgets(
    'profile cards and inspector use their own game context, not the active game',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final contexts = Contexts();
      await tester.pumpWidget(
        ModConductorApp(
          status: const DesktopConnected((
            runtime: (architecture: 'x64', nativeAot: true, sqliteVersion: '3'),
            heartbeats: 1,
          )),
          workspaces: Workspaces(),
          gameContexts: contexts,
          profileData: ProfileData(),
        ),
      );
      await tester.pumpAndSettle();
      final browser = tester.widget<WorkspaceBrowser>(
        find.byType(WorkspaceBrowser),
      );
      await browser.controller.open('/workspace');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-profiles-tab')));
      await tester.pumpAndSettle();
      McPortraitCard card(String id) => tester.widget<McPortraitCard>(
        find.byKey(ValueKey('profile-card-$id')),
      );
      expect(card('nv').category, nv.name);
      expect(card('nv').image, Uri.parse(nv.artworkUrl));
      expect(card('fo76').category, fo76.name);
      expect(card('fo76').image, Uri.parse(fo76.artworkUrl));
      expect(card('unbound').category, isNull);
      expect(card('unbound').image, isNull);

      Future<ProfileSettingsInspector> inspect(String id) async {
        await tester.tap(
          find.descendant(
            of: find.byKey(ValueKey('profile-card-$id')),
            matching: find.widgetWithText(McAction, 'Settings and saves'),
          ),
        );
        await tester.pumpAndSettle();
        return tester.widget<ProfileSettingsInspector>(
          find.byType(ProfileSettingsInspector),
        );
      }

      final sibling = await inspect('fo76');
      expect(sibling.profile.id, 'fo76');
      expect(sibling.savesAvailable, isFalse);
      expect(sibling.gameImage, Uri.parse(fo76.artworkUrl));
      expect(sibling.available, isTrue);
      expect(browser.controller.workspace!.selectedProfile!.id, 'nv');
      sibling.onClose();
      await tester.pumpAndSettle();

      final selected = await inspect('nv');
      expect(selected.savesAvailable, isTrue);
      expect(selected.gameImage, Uri.parse(nv.artworkUrl));
      selected.onClose();
      await tester.pumpAndSettle();

      final unbound = await inspect('unbound');
      expect(unbound.savesAvailable, isFalse);
      expect(unbound.gameImage, isNull);
      expect(unbound.available, isFalse);
      unbound.onClose();
      await tester.pumpAndSettle();

      contexts.unavailable = true;
      await browser.controller.refresh();
      await tester.pumpAndSettle();
      expect(card('fo76').category, isNull);
      expect(card('fo76').image, isNull);
      final unavailable = await inspect('fo76');
      expect(unavailable.savesAvailable, isFalse);
      expect(unavailable.gameImage, isNull);
      expect(unavailable.available, isFalse);
    },
  );
}
