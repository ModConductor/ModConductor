import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_bethesda/mc_bethesda.dart';
import 'package:mc_client/mc_client.dart';

const reference = ProfileDataRef(
  workspaceId: 'workspace',
  profileId: 'profile',
  contextId: 'context',
  revision: 3,
);

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
  ProfilePluginOrder get value => ProfilePluginOrder(
    reference,
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
  int applies = 0;
  LootStateView get empty =>
      const LootStateView('skyrim-se-steam', true, '', null, null);
  LootStateView get proposed => LootStateView(
    'skyrim-se-steam',
    true,
    '',
    null,
    LootProposalView(
      'proposal',
      reference,
      'headers',
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
  ) async => proposed;
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
  Future<LootStateView> refreshMetadata() async => empty;
}

void main() {
  testWidgets(
    'a reviewed proposal saves only after the explicit apply action',
    (tester) async {
      final bethesda = _Bethesda(), orders = _Orders(_Bethesda().snapshot);
      final plugins = PluginsController()
        ..attach(bethesda, 'profile', orders: orders);
      await plugins.scan();
      final client = _Loot(orders.value);
      final controller = SortOrderController()
        ..attach(client, plugins, 'profile');
      await tester.pump();
      await controller.preview();

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
      expect(client.applies, 0);
      expect(find.text('Group: Patches'), findsOneWidget);
      await tester.tap(find.text('Apply proposed order'));
      await tester.pumpAndSettle();
      expect(client.applies, 1);
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
}
