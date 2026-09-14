import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_bethesda/mc_bethesda.dart';
import 'package:mc_client/mc_client.dart';

class _Bethesda implements BethesdaClient {
  final snapshot = PluginSnapshot(
    'headers',
    'workspace',
    'profile',
    DateTime.utc(2026),
    false,
    const [],
    const [],
  );
  @override
  Future<PluginSnapshot> read(String snapshot) async => this.snapshot;
  @override
  Future<PluginSnapshot> scan(String profile) async => snapshot;
}

class _Orders implements PluginOrderClient {
  _Orders(this.headers);
  final PluginSnapshot headers;
  @override
  Future<ProfilePluginOrder> read(
    String workspace,
    String profile,
    String headers,
  ) async => ProfilePluginOrder(
    const ProfileDataRef(
      workspaceId: 'workspace',
      profileId: 'profile',
      contextId: 'context',
      revision: 1,
    ),
    this.headers,
    const [],
    const [],
    const [],
    0,
    0,
    254,
    true,
    false,
    false,
    false,
    '',
  );
  @override
  Future<ProfilePluginOrder> change(
    ProfileDataRef expected,
    String headers,
    List<String> names,
    PluginOrderAction action,
  ) => throw UnimplementedError();
  @override
  Future<ProfilePluginOrder> useGameOrder(
    ProfileDataRef expected,
    String headers,
  ) => throw UnimplementedError();
}

class _Archives implements ArchivePolicyClient {
  var applications = 0;
  var scans = 0;
  ArchivePolicyView get view => ArchivePolicyView(
    reference: const ProfileDataRef(
      workspaceId: 'workspace',
      profileId: 'profile',
      contextId: 'context',
      revision: 1,
    ),
    snapshotId: 'snapshot',
    observedAt: DateTime.utc(2026),
    stale: false,
    entries: const [
      ArchivePolicyEntry(
        name: 'Skyrim - Textures0.bsa',
        position: 1,
        state: ArchiveState.active,
        required: true,
        explicit: true,
        iniKey: 'SResourceArchiveList',
        iniPosition: 0,
        associatedPlugin: '',
        reasons: ['Required in Skyrim.ini'],
        source: PluginSource(
          'Game folder',
          '',
          'Data/Skyrim - Textures0.bsa',
          '',
          '',
          true,
        ),
        format: 'BSA v105',
        problem: '',
      ),
    ],
    problems: const [],
    blockingProblems: const [],
    saved: true,
    applied: false,
    pending: false,
    pendingProblem: '',
    invalidation: 'Not available for this game',
  );
  @override
  Future<ArchivePolicyView> scan(
    String workspace,
    String profile,
    String headers,
  ) async {
    scans++;
    return view;
  }

  @override
  Future<ArchivePolicyView> read(
    String workspace,
    String profile,
    String snapshot,
  ) async => view;
  @override
  Future<void> apply(
    String id,
    ProfileDataRef expected,
    String snapshot,
  ) async {
    applications++;
  }

  @override
  Future<void> restore(String id, ProfileDataRef expected) async {}
}

void main() {
  testWidgets(
    'engine-shaped first archive stays order 1 through the pane and inspector',
    (tester) async {
      final bethesda = _Bethesda();
      final plugins = PluginsController()
        ..attach(bethesda, 'profile', orders: _Orders(bethesda.snapshot));
      await plugins.scan();
      final client = _Archives();
      final controller = ArchivePolicyController()
        ..attach(client, plugins, 'workspace', 'profile');
      await controller.scan();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 720,
              height: 700,
              child: ArchivePolicyPane(
                controller: controller,
                narrow: false,
                onInspect: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Archive changes are ready'), findsOneWidget);
      expect(find.text('Apply archive changes'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.textContaining('Archive invalidation'), findsNothing);
      await tester.tap(find.text('Apply archive changes'));
      await tester.pumpAndSettle();
      expect(client.applications, 1);
      expect(client.scans, 2);

      controller.rows.select('Skyrim - Textures0.bsa');
      await tester.pumpWidget(
        MaterialApp(
          home: ArchivePolicyInspector(controller: controller, onClose: () {}),
        ),
      );
      expect(find.text('Archive invalidation'), findsOneWidget);
      expect(find.text('Not available for this game.'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.textContaining('dummy', findRichText: true), findsNothing);
      controller.dispose();
      plugins.dispose();
    },
  );
}
