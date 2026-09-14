import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_profile_data/mc_profile_data.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

const workspace = WorkspaceInfo(
  id: 'workspace',
  name: 'Workspace',
  path: '/workspace',
  revision: 1,
);
const firstProfile = ProfileInfo('first', 'First profile');
const secondProfile = ProfileInfo('second', 'Second profile');

ProfileDataState profileState(String profile) => ProfileDataState(
  reference: ProfileDataRef(
    workspaceId: 'workspace',
    profileId: profile,
    contextId: 'context',
    revision: 1,
  ),
  options: const ProfileDataOptions(settings: true, saves: false),
  settingsPath: '/private/$profile',
  savesPath: '',
  settingsFiles: 1,
  saveFiles: 0,
  settingsInitialized: true,
);

class ConfigurationClient extends Fake implements ProfileDataClient {
  ConfigurationClient(this.label);
  final String label;
  final readProfiles = <String>[];

  @override
  Future<ProfileDataState> read(String workspaceId, String profileId) async {
    readProfiles.add(profileId);
    return profileState(profileId);
  }

  @override
  Future<List<ProfileConfigurationFile>> configurationFiles(
    ProfileDataRef expected,
  ) async => const [ProfileConfigurationFile('Skyrim.ini', true, 9)];

  @override
  Future<ProfileConfigurationDocument> readConfiguration(
    ProfileDataRef expected,
    String name,
  ) async => ProfileConfigurationDocument(
    previewId: '$label-preview',
    expected: expected,
    name: name,
    exists: true,
    length: 9,
    document: const TextDocument(
      content: 'original\n',
      encoding: TextDocumentEncoding.utf8,
      newline: TextDocumentNewline.lf,
      finalTerminator: true,
      lines: 2,
    ),
  );
}

Widget host(
  ProfileDataController controller,
  ConfigurationClient client,
  ProfileInfo profile,
) => MaterialApp(
  theme: mcTheme(Brightness.light),
  home: Scaffold(
    body: ProfileSettingsInspector(
      key: const ValueKey('profile-settings'),
      controller: controller,
      client: client,
      workspace: workspace,
      profile: profile,
      profiles: const [firstProfile, secondProfile],
      available: true,
      onClose: () {},
      onResumeProfileChange: (_) async {},
      onNavigationGuardChanged: (_) {},
    ),
  ),
);

void main() {
  testWidgets(
    'profile client changes keep the old draft until their guard resolves',
    (tester) async {
      final controller = ProfileDataController();
      final first = ConfigurationClient('first');
      final second = ConfigurationClient('second');
      final third = ConfigurationClient('third');
      addTearDown(controller.dispose);

      await tester.pumpWidget(host(controller, first, firstProfile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit profile files'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skyrim.ini'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('text-editor')),
        'keep this draft\n',
      );

      await tester.pumpWidget(host(controller, second, secondProfile));
      await tester.pumpAndSettle();
      expect(find.text('Save changes?'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('keep this draft\n'), findsOneWidget);
      expect(find.text('First profile'), findsOneWidget);
      expect(second.readProfiles, isEmpty);
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.pumpWidget(host(controller, third, secondProfile));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Discard').last);
      await tester.pumpAndSettle();
      expect(third.readProfiles, ['second']);
      expect(find.byKey(const ValueKey('text-editor')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
