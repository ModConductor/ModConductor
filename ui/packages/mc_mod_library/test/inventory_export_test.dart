import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller_test.dart';

class ExportClient extends Fake implements InventoryExportClient {
  InventoryExportCapture? capture;
  bool existing = false;
  Object? prepareError, writeError;
  StreamController<InventoryExportEvent>? pendingWrite;
  int inspections = 0, discards = 0;

  @override
  Future<PreparedInventoryExport> prepare(InventoryExportCapture value) async {
    capture = value;
    if (prepareError case final error?) throw error;
    return PreparedInventoryExport('export', 2, value.fields);
  }

  @override
  Future<InventoryExportDestination> inspect(
    String exportId,
    String destinationPath,
  ) async {
    inspections++;
    return InventoryExportDestination('destination', 'mods.csv', existing);
  }

  @override
  Stream<InventoryExportEvent> write(
    String exportId,
    String destinationId, {
    required bool replaceExisting,
  }) {
    if (writeError case final error?) return Stream.error(error);
    return pendingWrite?.stream ??
        Stream.value(const InventoryExportCompleted('mods.csv', 2, 120));
  }

  @override
  Future<bool> discard(String exportId) async {
    discards++;
    return true;
  }
}

ModLibraryController browserController() {
  final library = LibraryClient()
    ..onQuery = (_, _) async => inventoryPage([mod('one'), mod('two')], null);
  final controller = ModLibraryController();
  controller.attach(
    library,
    SelectionClient(),
    organizationClient: organization(library),
    workspaceId: 'workspace',
    profileId: 'profile',
    workspaceRevision: 4,
    editable: true,
  );
  return controller;
}

Future<void> pumpBrowser(
  WidgetTester tester,
  ModLibraryController controller,
  ExportClient exports, {
  Future<bool> Function(String)? openFolder,
}) => tester.pumpWidget(
  MaterialApp(
    theme: mcTheme(Brightness.light),
    home: Scaffold(
      body: ModLibraryBrowser(
        controller: controller,
        workspacePath: '/workspace',
        inventoryExports: exports,
        chooseExportLocation: () async => '/tmp/mods.csv',
        openExportFolder: openFolder,
        profileName: 'Profile',
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'export retains hidden selections and requires consent before replacement',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = browserController();
      addTearDown(controller.dispose);
      final exports = ExportClient()
        ..existing = true
        ..pendingWrite = StreamController();
      addTearDown(() => exports.pendingWrite?.close());
      await pumpBrowser(tester, controller, exports);
      await tester.pumpAndSettle();
      controller.mods.select((modId: 'one'));
      controller.mods.select((modId: 'two'), toggle: true);
      controller.mods.apply(visibleIds: const {(modId: 'one')});
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('export-csv')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey(('export-scope', InventoryExportScope.currentQuery)),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(('export-field', InventoryExportField.categories)),
        ),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('choose-export-location')),
      );
      await tester.tap(find.byKey(const ValueKey('choose-export-location')));
      await tester.pumpAndSettle();
      expect(exports.capture!.selectedModIds, ['one', 'two']);
      expect(exports.inspections, 1);
      final submit = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const ValueKey('export-submit')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(submit.onPressed, isNull);

      await tester.tap(
        find.byKey(const ValueKey('replace-export-destination')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('export-submit')));
      await tester.pump();
      expect(find.byKey(const ValueKey('export-progress')), findsOneWidget);

      final cancel = tester.widget<OutlinedButton>(
        find.descendant(
          of: find.byKey(const ValueKey('export-cancel')),
          matching: find.byType(OutlinedButton),
        ),
      );
      cancel.onPressed!();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('export-progress')), findsNothing);
      expect(controller.mods.selectedIds, {(modId: 'one'), (modId: 'two')});
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Installed mods');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('success returns focus and opens only the destination folder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = browserController();
    addTearDown(controller.dispose);
    final exports = ExportClient();
    String? opened;
    await pumpBrowser(
      tester,
      controller,
      exports,
      openFolder: (path) async {
        opened = path;
        return true;
      },
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-csv')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('choose-export-location')),
    );
    await tester.tap(find.byKey(const ValueKey('choose-export-location')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-submit')));
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Installed mods');
    await tester.tap(find.byKey(const ValueKey('open-export-folder')));
    await tester.pump();
    expect(opened, '/tmp/mods.csv');
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale preparation and write failure remain distinct', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final capture = InventoryExportCapture(
      workspaceId: 'workspace',
      workspaceRevision: 1,
      profileId: 'profile',
      scope: InventoryExportScope.selected,
      selectedModIds: const ['one'],
      query: const ModQuery(),
      queryIdentity: 'query',
      catalogueRevision: 1,
      selectionRevision: 1,
      fields: const [],
    );
    final stale = ExportClient()
      ..prepareError = const InventoryExportException(
        InventoryExportFault.stale,
        'stale',
      );
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: InventoryExportDialog(
          client: stale,
          capture: capture,
          chooseLocation: () async => '/tmp/mods.csv',
          profileName: 'Profile',
          selectedCount: 1,
          hiddenSelectedCount: 0,
          enabledCount: 1,
          matchingCount: 1,
          totalCount: 1,
        ),
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('choose-export-location')),
    );
    await tester.tap(find.byKey(const ValueKey('choose-export-location')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('export-problem-action')), findsOneWidget);

    final failed = ExportClient()
      ..writeError = const InventoryExportException(
        InventoryExportFault.writeFailed,
        'failed',
      );
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: InventoryExportDialog(
          key: UniqueKey(),
          client: failed,
          capture: capture,
          chooseLocation: () async => '/tmp/mods.csv',
          profileName: 'Profile',
          selectedCount: 1,
          hiddenSelectedCount: 0,
          enabledCount: 1,
          matchingCount: 1,
          totalCount: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('choose-export-location')),
    );
    await tester.tap(find.byKey(const ValueKey('choose-export-location')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('export-problem-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
