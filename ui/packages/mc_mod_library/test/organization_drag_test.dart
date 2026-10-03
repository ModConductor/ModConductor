import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller_test.dart';

OrganizedMod row(
  String id,
  int position, {
  String? group,
  bool separator = false,
}) => OrganizedMod(
  ProfileMod(
    ModEntry(
      id: id,
      workspaceId: 'workspace',
      kind: separator ? ModKind.separator : ModKind.regular,
      metadata: ModMetadata(name: id),
      revision: 0,
      status: InventoryStatus.ready,
      actions: const [],
    ),
    separator
        ? OrderedProfileMod(id, position)
        : ManagedProfileMod(id, position, true),
  ),
  group,
  position: position,
  groupSize: separator ? const GroupSize(2, 20) : null,
);

class DragOrganization extends QueryClient {
  List<OrganizedMod> entries = [
    row('one', 0, separator: true),
    row('a', 1, group: 'one'),
    row('b', 2, group: 'one'),
    row('two', 3, separator: true),
    row('c', 4, group: 'two'),
  ];
  List<OrganizedMod>? afterDrop;
  int revision = 0;
  final drops =
      <
        ({
          String profile,
          List<String> ids,
          String target,
          OrganizationPlacement position,
        })
      >[];
  DragOrganization() {
    onQuery = (_, _, _, _) async =>
        queryPage(entries, revision: revision, total: 40);
  }
  @override
  Future<int> place(
    String profile,
    int revision,
    List<String> ids,
    String target,
    OrganizationPlacement placement,
  ) async {
    drops.add((
      profile: profile,
      ids: ids,
      target: target,
      position: placement,
    ));
    entries = afterDrop ?? entries;
    return ++this.revision;
  }
}

Finder item(String id) => find.byKey(ValueKey((modId: id)));
Future<void> drag(
  WidgetTester tester,
  String source,
  Offset target, {
  Offset? entry,
}) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.down(tester.getCenter(item(source)));
  await gesture.moveBy(const Offset(0, 20));
  await tester.pump();
  if (entry != null) {
    await gesture.moveTo(entry);
    await tester.pump();
  }
  await gesture.moveTo(target);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  Future<ModLibraryController> mount(
    WidgetTester tester,
    DragOrganization client,
  ) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ModLibraryController()
      ..attach(
        LibraryClient(),
        SelectionClient(),
        organizationClient: client,
        workspaceId: 'workspace',
        profileId: 'profile',
        editable: true,
      );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.dark),
        home: Scaffold(
          body: ModLibraryBrowser(
            controller: controller,
            workspacePath: '/workspace',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets(
    'dragging an individual row reorders siblings and preserves its enablement',
    (tester) async {
      final client = DragOrganization()
        ..afterDrop = [
          row('one', 0, separator: true),
          row('b', 1, group: 'one'),
          row('a', 2, group: 'one'),
          row('two', 3, separator: true),
          row('c', 4, group: 'two'),
        ];
      final controller = await mount(tester, client);
      final target = tester.getRect(item('b'));
      await drag(tester, 'a', Offset(target.center.dx, target.bottom - 4));
      expect(client.drops.single.ids, ['a']);
      expect(client.drops.single.position, OrganizationPlacement.after);
      expect(controller.mods.visible.map((id) => id.modId), [
        'one',
        'b',
        'a',
        'two',
        'c',
      ]);
      expect(
        (controller.mods[(modId: 'a')]!.selection as ManagedProfileMod).enabled,
        isTrue,
      );
    },
  );

  testWidgets(
    'Ctrl and Shift selection drag into a collapsed separator collection',
    (tester) async {
      final client = DragOrganization()
        ..afterDrop = [
          row('one', 0, separator: true),
          row('two', 1, separator: true),
          row('c', 2, group: 'two'),
          row('a', 3, group: 'two'),
          row('b', 4, group: 'two'),
        ];
      final controller = await mount(tester, client);
      controller.mods.toggle((modId: 'two'));
      await tester.pumpAndSettle();
      await tester.tap(item('a'));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(item('b'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(item('a'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(controller.mods.selectedIds.map((id) => id.modId).toSet(), {
        'a',
        'b',
      });
      final target = tester.getRect(item('two'));
      await drag(
        tester,
        'a',
        target.center,
        entry: Offset(target.center.dx, target.top + 2),
      );
      expect(client.drops.single.ids.toSet(), {'a', 'b'});
      expect(client.drops.single.position, OrganizationPlacement.inside);
      expect(controller.mods[(modId: 'a')]!.groupId, 'two');
      expect(controller.mods[(modId: 'b')]!.groupId, 'two');
      expect(controller.mods.expanded((modId: 'two')), isFalse);
      expect(controller.mods.selectedIds.map((id) => id.modId).toSet(), {
        'a',
        'b',
      });
    },
  );

  testWidgets(
    'collapsed separator drag submits its header rather than a partial member inventory',
    (tester) async {
      final client = DragOrganization()
        ..afterDrop = [
          row('two', 0, separator: true),
          row('c', 1, group: 'two'),
          row('one', 2, separator: true),
          row('a', 3, group: 'one'),
          row('b', 4, group: 'one'),
        ];
      final controller = await mount(tester, client);
      controller.mods.toggle((modId: 'one'));
      await tester.pumpAndSettle();
      final target = tester.getRect(item('two'));
      await drag(tester, 'one', Offset(target.center.dx, target.bottom - 2));
      expect(client.drops.single.ids, ['one']);
      expect(client.drops.single.position, OrganizationPlacement.after);
      expect(controller.mods.visible.map((id) => id.modId), [
        'two',
        'c',
        'one',
      ]);
      expect(controller.mods.expanded((modId: 'one')), isFalse);
    },
  );

  testWidgets('a profile switch during drag rejects an old-scope drop', (
    tester,
  ) async {
    final client = DragOrganization();
    final controller = await mount(tester, client);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.down(tester.getCenter(item('a')));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    controller.attach(
      LibraryClient(),
      SelectionClient(),
      organizationClient: client,
      workspaceId: 'workspace',
      profileId: 'next',
      editable: true,
    );
    await tester.pumpAndSettle();
    await gesture.moveTo(tester.getCenter(item('two')));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(client.drops, isEmpty);
    expect(controller.inventory.changing, isFalse);
  });
}
