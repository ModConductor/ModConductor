import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_profile_data/src/save_files.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

const reference = ProfileDataRef(
  workspaceId: '11111111-1111-1111-1111-111111111111',
  profileId: '22222222-2222-2222-2222-222222222222',
  contextId: '33333333-3333-3333-3333-333333333333',
  revision: 1,
);

ProfileDataState state() => const ProfileDataState(
  reference: reference,
  options: ProfileDataOptions(settings: false, saves: true),
  settingsPath: '/private/settings',
  savesPath: '/private/saves',
  settingsFiles: 0,
  saveFiles: 0,
);

class SaveClient implements ProfileDataClient {
  SaveClient({this.pendingApply = false});
  final bool pendingApply;
  final cancelled = Completer<void>();
  ProfileSaveSource? listedSource;
  ProfileSaveAction? previewedAction;
  List<String>? previewedNames;
  String? inspectedName;

  @override
  Future<ProfileSaveGroupPage> saveGroups(
    String workspaceId,
    String profileId,
    ProfileSaveSource source, {
    String? after,
  }) async {
    listedSource = source;
    return ProfileSaveGroupPage(
      source,
      ProfileSavePath(
        source == ProfileSaveSource.global ? '/global/Saves' : '/private/saves',
        source == ProfileSaveSource.global
            ? r'C:\Users\steamuser\Documents\My Games\Skyrim Special Edition\Saves'
            : null,
      ),
      source == ProfileSaveSource.global
          ? const [
              ProfileSaveGroupEntry(
                id: 'Aela.ess',
                name: 'Aela.ess',
                kind: ProfileSaveEntryKind.save,
                bytes: 4096,
                companion: 'Aela.skse',
                companionBytes: 128,
                actionable: true,
              ),
              ProfileSaveGroupEntry(
                id: 'steam_autocloud.vdf',
                name: 'steam_autocloud.vdf',
                kind: ProfileSaveEntryKind.other,
                bytes: 20,
                companionBytes: 0,
                actionable: false,
              ),
            ]
          : const [],
      null,
    );
  }

  @override
  Future<ProfileSaveInspection> inspectSave(
    String workspaceId,
    String profileId,
    ProfileSaveSource source,
    String name, {
    String? headersId,
  }) async {
    inspectedName = name;
    return const ProfileSaveInspection(
      source: ProfileSaveSource.global,
      path: ProfileSavePath('/global/Saves', r'C:\Saves'),
      entry: ProfileSaveGroupEntry(
        id: 'Aela.ess',
        name: 'Aela.ess',
        kind: ProfileSaveEntryKind.save,
        bytes: 4096,
        companion: 'Aela.skse',
        companionBytes: 128,
        actionable: true,
      ),
      metadata: SkyrimSaveMetadata(
        headerVersion: 12,
        formVersion: 78,
        compression: SkyrimSaveCompression.lz4,
        saveNumber: 42,
        character: 'Aela',
        level: 37,
        location: 'Whiterun',
        gameTime: '12.34.56',
        fullPlugins: ['Skyrim.esm'],
        lightPlugins: [],
      ),
      pluginIssues: [],
    );
  }

  @override
  Future<ProfileSaveActionPreview> previewSaveAction(
    ProfileDataRef expected,
    ProfileSaveAction action,
    List<String> names,
  ) async {
    previewedAction = action;
    previewedNames = names;
    return ProfileSaveActionPreview(
      id: '44444444-4444-4444-4444-444444444444',
      expected: expected,
      action: action,
      source: const ProfileSavePath('/global/Saves', r'C:\Saves'),
      destination: const ProfileSavePath('/private/saves', null),
      files: const [
        ProfileSaveActionFile('Aela.ess', 4096),
        ProfileSaveActionFile('Aela.skse', 128),
      ],
      bytes: 4224,
    );
  }

  @override
  Stream<ProfileDataEvent> applySaveAction(
    String id,
    String previewId,
    ProfileDataRef expected,
  ) {
    if (pendingApply) {
      return StreamController<ProfileDataEvent>(
        onCancel: () => cancelled.complete(),
      ).stream;
    }
    return Stream.value(
      ProfileDataResult(
        id: id,
        state: state(),
        complete: true,
        completedFiles: 2,
      ),
    );
  }

  @override
  Future<ProfileDataState> read(String workspaceId, String profileId) async =>
      state();
  @override
  Future<ProfileSavePage> saveFiles(
    String workspaceId,
    String profileId,
    List<String> path, {
    String? after,
  }) => throw UnimplementedError();
  @override
  Stream<ProfileDataEvent> edit(
    String id,
    ProfileDataRef expected,
    ProfileDataOptions options, {
    required InitialProfileSaves initialSaves,
    required DisabledProfileFiles disabledFiles,
  }) => throw UnimplementedError();
  @override
  Stream<ProfileDataEvent> restore(String id, ProfileDataRef expected) =>
      throw UnimplementedError();
  @override
  Stream<ProfileDataEvent> resume(String workspaceId, String id) =>
      throw UnimplementedError();
}

void main() {
  testWidgets(
    'save browser groups companions and confirms an explicit transfer',
    (tester) async {
      final client = SaveClient();
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileSaveFiles(
              client: client,
              workspace: reference.workspaceId,
              profile: const ProfileInfo(
                '22222222-2222-2222-2222-222222222222',
                'Everyday',
              ),
              expected: reference,
              headersId: '55555555-5555-5555-5555-555555555555',
              onChanged: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Global'));
      await tester.pumpAndSettle();
      expect(client.listedSource, ProfileSaveSource.global);
      expect(find.text('steam_autocloud.vdf'), findsOneWidget);

      await tester.tap(find.text('Aela.ess').first);
      await tester.pumpAndSettle();
      expect(client.inspectedName, 'Aela.ess');
      expect(find.textContaining('Aela.skse'), findsOneWidget);
      expect(find.text('Aela · Level 37'), findsOneWidget);

      await tester.tap(find.text('Copy to profile').first);
      await tester.pumpAndSettle();
      expect(find.text('Source'), findsOneWidget);
      expect(find.text('Destination'), findsOneWidget);
      expect(
        find.text(
          'If a selected file changes before this action starts, nothing will be changed.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ready to copy'), findsNothing);
      expect(find.text('Files are checked again before copying'), findsNothing);

      await tester.tap(find.text('Copy to profile').last);
      await tester.pumpAndSettle();
      expect(client.previewedAction, ProfileSaveAction.copyToProfile);
      expect(client.previewedNames, ['Aela.ess']);
    },
  );

  testWidgets('narrow save details keep the selected action available', (
    tester,
  ) async {
    final client = SaveClient();
    await tester.binding.setSurfaceSize(const Size(600, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileSaveFiles(
            client: client,
            workspace: reference.workspaceId,
            profile: const ProfileInfo(
              '22222222-2222-2222-2222-222222222222',
              'Everyday',
            ),
            expected: reference,
            onChanged: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Global'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aela.ess'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Aela.skse'), findsOneWidget);
    expect(find.text('Copy to profile'), findsOneWidget);
  });

  testWidgets(
    'cancelling a transfer cancels its protocol stream and invalidates state',
    (tester) async {
      final client = SaveClient(pendingApply: true);
      var invalidated = false;
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileSaveFiles(
              client: client,
              workspace: reference.workspaceId,
              profile: const ProfileInfo(
                '22222222-2222-2222-2222-222222222222',
                'Everyday',
              ),
              expected: reference,
              onChanged: () => invalidated = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Global'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aela.ess'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy to profile').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy to profile').last);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(
        find
            .byWidgetPredicate(
              (widget) => widget is McAction && widget.label == 'Cancel',
            )
            .hitTestable(),
      );
      await tester.pumpAndSettle();

      expect(client.cancelled.isCompleted, isTrue);
      expect(invalidated, isTrue);
    },
  );
}
