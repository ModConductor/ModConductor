import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_bethesda/mc_bethesda.dart';
import 'package:mc_client/mc_client.dart';

class _Bethesda implements BethesdaClient {
  _Bethesda([String profile = 'profile'])
    : snapshot = PluginSnapshot(
        'headers',
        'workspace',
        profile,
        DateTime.utc(2026),
        false,
        const [],
        const [],
      );
  final PluginSnapshot snapshot;
  @override
  Future<PluginSnapshot> read(String snapshot) async => this.snapshot;
  @override
  Future<PluginSnapshot> scan(String profile) async => snapshot;
}

class _Orders implements PluginOrderClient {
  _Orders(this.headers);
  final PluginSnapshot headers;
  ProfilePluginOrder get value => ProfilePluginOrder(
    ProfileDataRef(
      workspaceId: headers.workspaceId,
      profileId: headers.profileId,
      contextId: 'context',
      revision: 3,
    ),
    headers,
    const [
      PluginSetting('Patch.esp', true, null, null),
      PluginSetting('Weather.esp', true, null, null),
    ],
    const [],
    const [],
    2,
    0,
    255,
    true,
    false,
    false,
    false,
    '',
  );
  @override
  Future<ProfilePluginOrder> read(
    String workspace,
    String profile,
    String headers,
  ) async => value;
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

class _Loot implements LootClient {
  _Loot(this.order);
  final ProfilePluginOrder order;
  int applies = 0, refreshes = 0, previews = 0;
  bool available = true, metadataAvailable = true;
  LootStateView get empty => LootStateView(
    'skyrim-se-steam',
    available,
    available ? '' : 'LOOT sorting is unavailable.',
    available && metadataAvailable
        ? LootMetadataView('m:p', 'm', 'p', 'm', 'p', DateTime.utc(2026))
        : null,
    null,
  );
  LootStateView get proposed => LootStateView(
    'skyrim-se-steam',
    true,
    '',
    empty.metadata,
    LootProposalView(
      'proposal',
      order.reference,
      order.headers.id,
      DateTime.utc(2026),
      const ['Weather.esp', 'Patch.esp'],
      const ['Patch.esp', 'Weather.esp'],
      const [
        LootMoveView('Patch.esp', 2, 1, 'Group: Patches'),
        LootMoveView('Weather.esp', 1, 2, 'Loads after Patch.esp'),
      ],
      const [
        LootMessageView(
          'Weather.esp',
          'warn',
          'Cleaning information is available',
        ),
      ],
      LootMetadataView(
        'm:p',
        '1234567890',
        'abcdef0123',
        'm',
        'p',
        DateTime.utc(2026),
      ),
      '0.1.0',
      '0.29.6',
      '136f3983',
    ),
  );
  @override
  Future<LootStateView> read() async => empty;
  @override
  Future<LootStateView> preview(
    String workspace,
    String profile,
    String headers,
  ) async {
    previews++;
    return proposed;
  }

  @override
  Future<ProfilePluginOrder> apply(
    String proposal,
    ProfileDataRef expected,
    String headers,
  ) async {
    applies++;
    return order;
  }

  @override
  Future<LootStateView> dismiss(String proposal) async => empty;
  @override
  Future<LootStateView> refreshMetadata() async {
    refreshes++;
    metadataAvailable = true;
    return empty;
  }
}

class _PendingLoot extends _Loot {
  _PendingLoot(super.order);
  Completer<LootStateView>? pendingPreview, pendingRead;
  Completer<ProfilePluginOrder>? pendingApply;
  Completer<LootStateView>? pendingMetadata;
  final applyProfiles = <String>[];
  @override
  Future<LootStateView> refreshMetadata() =>
      pendingMetadata?.future ?? super.refreshMetadata();
  @override
  Future<LootStateView> read() => pendingRead?.future ?? super.read();
  @override
  Future<LootStateView> preview(
    String workspace,
    String profile,
    String headers,
  ) => pendingPreview?.future ?? super.preview(workspace, profile, headers);
  @override
  Future<ProfilePluginOrder> apply(
    String proposal,
    ProfileDataRef expected,
    String headers,
  ) {
    applyProfiles.add(expected.profileId);
    return pendingApply?.future ?? super.apply(proposal, expected, headers);
  }
}

void main() {
  testWidgets('optimise obtains missing metadata and saves in one action', (
    tester,
  ) async {
    final source = _Bethesda(), orders = _Orders(_Bethesda().snapshot);
    final plugins = PluginsController()
      ..attach(source, 'profile', orders: orders);
    addTearDown(plugins.dispose);
    await plugins.scan();
    final client = _Loot(orders.value)..metadataAvailable = false;
    final controller = SortOrderController()
      ..attach(client, plugins, 'profile');
    addTearDown(controller.dispose);
    await tester.pump();
    expect(controller.canPreview, isTrue);
    await controller.optimise();
    expect(client.refreshes, 1);
    expect(client.previews, 1);
    expect(client.applies, 1);
    expect(controller.problem, isNull);
  });

  testWidgets(
    'a profile switch during metadata download cannot preview or apply the old scope',
    (tester) async {
      final source = _Bethesda(), orders = _Orders(_Bethesda().snapshot);
      final plugins = PluginsController()
        ..attach(source, 'profile', orders: orders);
      addTearDown(plugins.dispose);
      await plugins.scan();
      final client = _PendingLoot(orders.value)..metadataAvailable = false;
      final controller = SortOrderController()
        ..attach(client, plugins, 'profile');
      addTearDown(controller.dispose);
      await tester.pump();
      client.pendingMetadata = Completer<LootStateView>();
      final running = controller.optimise();
      await tester.pump();
      controller.attach(null, plugins, null);
      client.pendingMetadata!.complete(client.empty);
      await running;
      expect(client.previews, 0);
      expect(client.applies, 0);
      expect(controller.state, isNull);
      expect(controller.reading, isFalse);
    },
  );

  for (final kind in [
    ProfileDataProblemKind.busy,
    ProfileDataProblemKind.stale,
    ProfileDataProblemKind.invalid,
  ]) {
    testWidgets('apply preserves a server $kind refusal and does not retry', (
      tester,
    ) async {
      final source = _Bethesda(), orders = _Orders(_Bethesda().snapshot);
      final plugins = PluginsController()
        ..attach(source, 'profile', orders: orders);
      addTearDown(plugins.dispose);
      await plugins.scan();
      final client = _PendingLoot(orders.value);
      final controller = SortOrderController()
        ..attach(client, plugins, 'profile');
      addTearDown(controller.dispose);
      await tester.pump();
      client.pendingApply = Completer<ProfilePluginOrder>();
      final running = controller.optimise();
      await tester.pump();
      const detail = 'server-owned refusal';
      client.pendingApply!.completeError(ProfileDataProblem(kind, detail));
      await running;
      expect(controller.problem, detail);
      expect(controller.stale, kind == ProfileDataProblemKind.stale);
      expect(client.applyProfiles, ['profile']);
      expect(controller.writing, isFalse);
    });
  }

  for (final applying in [false, true]) {
    for (final helperRead in [false, true]) {
      testWidgets(
        'profile attach releases ${applying ? 'apply' : 'preview'} busy state and rejects old ${helperRead ? 'helper read' : 'completion'}',
        (tester) async {
          final bethesda = _Bethesda(), orders = _Orders(_Bethesda().snapshot);
          final plugins = PluginsController()
            ..attach(bethesda, 'profile', orders: orders);
          addTearDown(plugins.dispose);
          await plugins.scan();
          final oldClient = _PendingLoot(orders.value);
          final controller = SortOrderController()
            ..attach(oldClient, plugins, 'profile');
          addTearDown(controller.dispose);
          await tester.pump();
          if (applying) {
            oldClient.pendingApply = Completer<ProfilePluginOrder>();
          } else {
            oldClient.pendingPreview = Completer<LootStateView>();
          }
          final running = controller.optimise();
          await tester.pump();
          expect(applying ? controller.writing : controller.reading, isTrue);
          if (helperRead) {
            oldClient.pendingRead = Completer<LootStateView>();
            const error = LootFailure(
              LootFailureKind.helper,
              'helper unavailable',
            );
            if (applying) {
              oldClient.pendingApply!.completeError(error);
            } else {
              oldClient.pendingPreview!.completeError(error);
            }
            await tester.pump();
          }
          final nextBethesda = _Bethesda('next-profile');
          final nextOrders = _Orders(nextBethesda.snapshot);
          final nextPlugins = PluginsController()
            ..attach(nextBethesda, 'next-profile', orders: nextOrders);
          addTearDown(nextPlugins.dispose);
          await nextPlugins.scan();
          final nextClient = _Loot(nextOrders.value);
          controller.attach(nextClient, nextPlugins, 'next-profile');
          await tester.pump();
          expect(controller.canPreview, isTrue);
          await controller.optimise();
          final nextResult = controller.lastResult;
          final nextState = controller.state;
          expect(nextClient.previews, 1);
          expect(nextClient.applies, 1);
          expect(nextResult?.expected.profileId, 'next-profile');
          if (helperRead) {
            oldClient.pendingRead!.complete(oldClient.proposed);
          } else if (applying) {
            oldClient.pendingApply!.complete(orders.value);
          } else {
            oldClient.pendingPreview!.complete(oldClient.proposed);
          }
          await running;
          await tester.pump();
          expect(controller.lastResult, same(nextResult));
          expect(controller.state, same(nextState));
          expect(controller.proposal, isNull);
          expect(controller.problem, isNull);
          expect(controller.reading, isFalse);
          expect(controller.writing, isFalse);
          expect(controller.canPreview, isTrue);
          expect(oldClient.applyProfiles, applying ? ['profile'] : isEmpty);
        },
      );
    }
  }

  testWidgets(
    'one optimise action saves plugin order and retains LOOT reasons',
    (tester) async {
      final bethesda = _Bethesda(), orders = _Orders(_Bethesda().snapshot);
      final plugins = PluginsController()
        ..attach(bethesda, 'profile', orders: orders);
      await plugins.scan();
      final client = _Loot(orders.value);
      final controller = SortOrderController()
        ..attach(client, plugins, 'profile');
      await tester.pump();
      await controller.optimise();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 700,
              child: SortOrderPane(
                controller: controller,
                narrow: false,
                onInspect: () {},
              ),
            ),
          ),
        ),
      );
      expect(client.previews, 1);
      expect(client.applies, 1);
      expect(controller.lastResult?.messages.single.plugin, 'Weather.esp');
      expect(controller.proposal, isNull);

      controller.dispose();
      plugins.dispose();
    },
  );

  testWidgets('a changed plugin input disables a retained proposal', (
    tester,
  ) async {
    final bethesda = _Bethesda(), orders = _Orders(_Bethesda().snapshot);
    final plugins = PluginsController()
      ..attach(bethesda, 'profile', orders: orders);
    await plugins.scan();
    final controller = SortOrderController()
      ..attach(_Loot(orders.value), plugins, 'profile');
    await tester.pump();
    await controller.preview();
    plugins.invalidate();
    expect(controller.stale, isTrue);
    expect(controller.canApply, isFalse);
    controller.dispose();
    plugins.dispose();
  });

  testWidgets('a profile change discards the previous proposal', (
    tester,
  ) async {
    final bethesda = _Bethesda(), orders = _Orders(_Bethesda().snapshot);
    final plugins = PluginsController()
      ..attach(bethesda, 'profile', orders: orders);
    await plugins.scan();
    final client = _Loot(orders.value);
    final controller = SortOrderController()
      ..attach(client, plugins, 'profile');
    await tester.pump();
    await controller.preview();
    expect(controller.proposal, isNotNull);

    controller.attach(client, plugins, 'next-profile');
    expect(controller.proposal, isNull);
    await tester.pump();

    controller.dispose();
    plugins.dispose();
  });

  testWidgets(
    'a missing helper disables sort and refresh until retry succeeds',
    (tester) async {
      final bethesda = _Bethesda(), orders = _Orders(_Bethesda().snapshot);
      final plugins = PluginsController()
        ..attach(bethesda, 'profile', orders: orders);
      await plugins.scan();
      final client = _Loot(orders.value)..available = false;
      final controller = SortOrderController()
        ..attach(client, plugins, 'profile');
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 700,
              child: SortOrderPane(
                controller: controller,
                narrow: false,
                onInspect: () {},
              ),
            ),
          ),
        ),
      );
      expect(controller.canPreview, isFalse);
      expect(controller.canRefreshMetadata, isFalse);
      expect(find.text('LOOT sorting is unavailable.'), findsOneWidget);
      expect(find.text('Check again'), findsOneWidget);
      await controller.preview();
      await controller.refreshMetadata();
      expect(client.previews, 0);
      expect(client.refreshes, 0);
      client.available = true;
      await tester.tap(find.text('Check again'));
      await tester.pumpAndSettle();
      expect(controller.canPreview, isTrue);
      expect(controller.canRefreshMetadata, isTrue);
      controller.dispose();
      plugins.dispose();
    },
  );
}
