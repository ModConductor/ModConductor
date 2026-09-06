import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_workspaces/mc_workspaces.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native folder selection and persisted workspace profile journey',
    (tester) async {
      const executable = String.fromEnvironment('MC_ENGINE_PATH');
      const fixturePath = String.fromEnvironment('MC_UI_FIXTURE');
      if (executable.isEmpty || fixturePath.isEmpty) {
        throw StateError(
          'Pass MC_ENGINE_PATH and an owned MC_UI_FIXTURE directory.',
        );
      }
      final fixture = Directory(fixturePath);
      final workspace = await Directory(
        '$fixturePath${Platform.pathSeparator}workspace',
      ).create();
      final state = await Directory(
        '$fixturePath${Platform.pathSeparator}state',
      ).create();
      final sentinel = File('${workspace.path}/foreign.txt');
      await sentinel.writeAsString('Preserve this file.');
      EngineOwner makeOwner() => EngineOwner(
        executable,
        launch: (path) =>
            Process.start(path, ['--state-directory', state.path]),
      );
      var owner = makeOwner();
      final boundary = GlobalKey();
      Future<void> mount() async {
        await owner.connect();
        expect(owner.state, isA<EngineConnected>());
        expect(
          (owner.state as EngineConnected).report.runtime.nativeAot,
          isTrue,
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              workspaces: owner.workspaces,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      WorkspaceController getController() => tester
          .widget<WorkspaceBrowser>(find.byType(WorkspaceBrowser))
          .controller;
      Future<void> until(bool Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (!condition() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(condition(), isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> tapKey(String key) async {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$fixturePath/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<void> folder(
        String phase, {
        bool cancel = false,
        String? path,
      }) async {
        await File('$fixturePath/picker-$phase.json').writeAsString(
          jsonEncode({'path': path ?? workspace.path, 'cancel': cancel}),
        );
        await tester.tap(find.byKey(const ValueKey('choose-folder')));
        await until(() => File('$fixturePath/picker-$phase.done').existsSync());
        await tester.pump(const Duration(milliseconds: 400));
      }

      Future<void> name(String value) async {
        await tester.enterText(find.byKey(const ValueKey('name')), value);
        await tapKey('submit');
        await until(
          () =>
              getController().activity == null &&
              find.byType(McFormDialog).evaluate().isEmpty,
        );
      }

      Future<void> menu(String id, String action) async {
        await tapKey('profile-menu-$id');
        await tester.tap(find.text(action).last);
        await tester.pumpAndSettle();
      }

      try {
        await mount();
        await capture('entry-light');
        await tapKey('create-workspace');
        await folder('cancel', cancel: true);
        expect(find.byType(McFormDialog), findsOneWidget);
        expect(find.text(workspace.path), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'Create workspace',
        );
        await tapKey('create-workspace');
        await tester.enterText(find.byKey(const ValueKey('name')), 'Weekend');
        await folder('create');
        await capture('selected-folder-light');
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SelectableText && widget.data == workspace.path,
          ),
          findsOneWidget,
        );
        await tapKey('submit');
        await until(() => getController().canEdit);
        await capture('empty-light');
        await tapKey('create-profile');
        await name('Everyday');
        final first = getController().page!.profiles.single;
        await menu(first.id, 'Rename');
        await name('Everyday play');
        await menu(first.id, 'Clone');
        await name('Experiments');
        final copy = getController().page!.profiles.singleWhere(
          (p) => p.id != first.id,
        );
        await tapKey('profile-${copy.id}');
        await until(
          () =>
              getController().workspace!.selectedProfile!.id == copy.id &&
              getController().activity == null,
        );
        await menu(first.id, 'Delete');
        await capture('delete-light');
        await tapKey('submit');
        await until(
          () =>
              getController().page!.profiles.length == 1 &&
              getController().activity == null,
        );
        final saved = getController().workspace!;
        expect(saved.revision, 5);
        await capture('profiles-light');
        await tapKey('quick-theme');
        await tester.pumpAndSettle();
        await capture('profiles-dark');
        await tapKey('nav-preferences');
        await tapKey('preferences-scale');
        await tester.tap(find.text('150%').last);
        await tester.pumpAndSettle();
        await tapKey('apply-preferences');
        await tapKey('nav-workspaces');
        await tester.binding.setSurfaceSize(const Size(720, 900));
        await capture('profiles-dark-narrow150');
        await tapKey('quick-theme');
        await capture('profiles-light-narrow150');
        await tapKey('create-profile');
        await tapKey('submit');
        expect(find.byType(McFormDialog), findsOneWidget);
        expect(getController().page!.profiles.length, 1);
        await capture('invalid-name-light-narrow150');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await tester.binding.setSurfaceSize(null);
        await tapKey('quick-theme');
        await tapKey('close-workspace');
        await until(() => getController().recent.isNotEmpty);
        await capture('saved-dark');
        expect(await sentinel.readAsString(), 'Preserve this file.');
        await tester.pumpWidget(const SizedBox.shrink());
        expect(await owner.close(), isTrue);
        owner = makeOwner();
        await mount();
        await tapKey('open-workspace');
        await folder('reopen');
        await tapKey('submit');
        await until(
          () =>
              getController().workspace != null &&
              getController().activity == null,
        );
        expect(getController().workspace!.id, saved.id);
        expect(getController().workspace!.revision, saved.revision);
        expect(getController().workspace!.selectedProfile!.id, copy.id);
        expect(getController().page!.profiles.single.name, 'Experiments');
        await capture('reopened-light');
        await tapKey('close-workspace');
        final refusedRoot = await Directory(
          '$fixturePath${Platform.pathSeparator}refused-root',
        ).create();
        final foreignMarker = File('${refusedRoot.path}/.mod-conductor-root');
        await foreignMarker.writeAsString('Not owned by Mod Conductor.');
        await tapKey('create-workspace');
        await tester.enterText(find.byKey(const ValueKey('name')), 'Travel');
        await folder('foreign', path: refusedRoot.path);
        await tapKey('submit');
        await until(
          () => getController().needsCheck && getController().activity == null,
        );
        expect(getController().canEdit, isFalse);
        expect(
          getController().workspace!.pendingRoot!.reason,
          WorkspaceRootIssueReason.ownershipUnproved,
        );
        await tapKey('nav-preferences');
        await tapKey('preferences-scale');
        await tester.tap(find.text('150%').last);
        await tester.pumpAndSettle();
        await tapKey('apply-preferences');
        await tapKey('nav-workspaces');
        await tester.binding.setSurfaceSize(const Size(720, 900));
        await capture('recovery-light-narrow150');
        await tapKey('check-workspace');
        await until(() => getController().activity == null);
        expect(getController().needsCheck, isTrue);
        await tapKey('quick-theme');
        await capture('recovery-dark-narrow150');
        final unresolvedId = getController().workspace!.id;
        await tapKey('close-workspace');
        await until(
          () => getController().recent.any((item) => item.id == unresolvedId),
        );
        await tapKey('workspace-$unresolvedId');
        await until(
          () => getController().needsCheck && getController().activity == null,
        );
        expect(
          await foreignMarker.readAsString(),
          'Not owned by Mod Conductor.',
        );
        await tester.binding.setSurfaceSize(null);
        await refusedRoot.delete(recursive: true);
        await File('$fixturePath/result.json').writeAsString(
          jsonEncode({
            'nativeAot': true,
            'workspace': saved.id,
            'revision': saved.revision,
            'selectedProfile': copy.id,
            'pickerCancel': true,
            'unresolvedCreationPreserved': true,
            'narrowTextScale': 1.5,
            'restart': true,
            'foreignPreserved':
                await sentinel.readAsString() == 'Preserve this file.',
          }),
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        expect(await owner.close(), isTrue);
        await workspace.delete(recursive: true);
        await state.delete(recursive: true);
        expect(fixture.existsSync(), isTrue);
      }
    },
  );
}
