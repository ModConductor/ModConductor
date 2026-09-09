import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_executables/mc_executables.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'native executable Save Run and Stop waiting preserve arguments and captured history',
    (tester) async {
      tester.testTextInput.register();
      const engine = String.fromEnvironment('MC_ENGINE_PATH'),
          fixture = String.fromEnvironment('MC_NATIVE_FIXTURE'),
          output = String.fromEnvironment('MC_EXECUTABLES_EVIDENCE');
      const narrow = bool.fromEnvironment('MC_EXECUTABLES_NARROW'),
          windowGate = bool.fromEnvironment('MC_EXECUTABLES_WINDOW_GATE');
      if (engine.isEmpty || fixture.isEmpty || output.isEmpty) {
        throw StateError(
          'Select native tools and an owned evidence directory.',
        );
      }
      final area = await Directory.systemTemp.createTemp('mc-executables-ui-'),
          root = await Directory('${area.path}/workspace').create(),
          child = await Directory('${area.path}/child').create();
      await Directory(output).create(recursive: true);
      final owner = EngineOwner(
        engine,
        launch: (path) =>
            Process.start(path, ['--state-directory', '${area.path}/state']),
      );
      final boundary = GlobalKey();
      ExecutablesController controller() => tester
          .widget<ExecutablesBrowser>(
            find.byType(ExecutablesBrowser, skipOffstage: false),
          )
          .controller;
      Finder action(String label) =>
          find.byWidgetPredicate((w) => w is McAction && w.label == label);
      Finder icon(String label) =>
          find.byWidgetPredicate((w) => w is McIconAction && w.label == label);
      Finder field(String label) => find.widgetWithText(TextFormField, label);
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$output/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }

      Future<void> until(bool Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (!condition() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (!condition()) await capture('failure');
        expect(condition(), isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> enter(String label, String text) async {
        await tester.ensureVisible(field(label));
        await tester.enterText(field(label), text);
        await tester.pumpAndSettle();
      }

      Future<void> option(String label) async {
        await tap(
          find.byWidgetPredicate(
            (w) => w is McIconMenu<String> && w.label == 'Executable options',
          ),
        );
        await tap(find.text(label).last);
      }

      Future<void> theme(String label) async {
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await tap(find.byKey(const ValueKey('preferences-theme')));
        await tap(find.text(label).last);
        await tap(find.byKey(const ValueKey('apply-preferences')));
        await tap(find.byKey(const ValueKey('nav-workspaces')));
      }

      try {
        await owner.connect();
        final id = newOperationId(), profile = newOperationId();
        await owner.workspaces!.create(id, 'Tool check workspace', root.path);
        await owner.workspaces!.createProfile(
          id,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              workspaces: owner.workspaces,
              executables: owner.executables,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await File('$output/ready.json')
            .writeAsString(jsonEncode({'pid': pid, 'area': area.path}));
        if (windowGate) {
          final deadline = DateTime.now().add(const Duration(seconds: 40));
          while (!await File('$output/window-ready').exists() &&
              DateTime.now().isBefore(deadline)) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(await File('$output/window-ready').exists(), isTrue);
        }
        await tap(find.byKey(ValueKey('workspace-$id')));
        await tap(find.text('Tools'));
        await until(() => controller().connected && !controller().reading);
        if (narrow) {
          await tap(find.byKey(const ValueKey('nav-preferences')));
          await tap(find.byKey(const ValueKey('preferences-scale')));
          await tap(find.text('150%').last);
          await tap(find.byKey(const ValueKey('apply-preferences')));
          await tap(find.byKey(const ValueKey('nav-workspaces')));
        }
        await capture('empty-light');
        await tap(icon('Add executable'));
        await enter('Name', 'Draft only');
        await tap(action('Cancel'));
        expect(controller().presets.length, 0);
        await tap(icon('Add executable'));
        await enter('Name', 'Argument audit');
        await enter('Executable', fixture);
        await enter('Working directory', child.path);
        await tap(find.text('Arguments'));
        final args = [
          '--executable-child',
          child.path,
          'roundtrip',
          '',
          'two words',
          '"quoted"',
          'trailing\\',
        ];
        for (var i = 0; i < args.length; i++) {
          await tap(action('Add argument'));
          await enter('Argument ${i + 1}', args[i]);
        }
        await capture('arguments-light');
        await tap(find.byKey(const ValueKey('submit')));
        await until(
          () =>
              find.byType(ExecutableEditor).evaluate().isEmpty &&
              !controller().changing,
        );
        expect(controller().selected!.arguments, args);
        await tap(action('Run'));
        await until(
          () => controller().selectedRun?.phase == ExecutableRunPhase.finished,
        );
        final observed = jsonDecode(
          await File('${child.path}/roundtrip.json').readAsString(),
        ) as Map<String, dynamic>;
        expect(observed['arguments'], args.sublist(3));
        expect(observed['stdin'], -1);
        await capture('finished-light');
        await tap(action('Details'));
        await tap(action('Run details'));
        await capture('run-details-light');
        await tap(action('Close'));
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        final close = icon('Close inspector');
        if (close.evaluate().isNotEmpty) await tap(close);
        await theme('Dark');
        await capture('finished-dark');
        await option('Edit');
        await enter('Executable', '${child.path}/missing-tool');
        await tap(find.byKey(const ValueKey('submit')));
        await until(() => find.byType(ExecutableEditor).evaluate().isEmpty);
        await tap(action('Run'));
        await until(
          () => controller().selectedRun?.phase == ExecutableRunPhase.failed,
        );
        await capture('failed-dark');
        await option('Edit');
        await enter('Executable', fixture);
        await tap(find.text('Arguments'));
        await enter('Argument 3', 'waiter');
        await tap(find.byKey(const ValueKey('submit')));
        await until(() => find.byType(ExecutableEditor).evaluate().isEmpty);
        await tap(action('Run'));
        await until(
          () =>
              controller().selectedRun?.phase == ExecutableRunPhase.running &&
              File('${child.path}/waiter.started').existsSync(),
        );
        await capture('running-dark');
        await tap(action('Stop waiting'));
        await until(
          () => controller().selectedRun?.phase == ExecutableRunPhase.detached,
        );
        expect(await File('${child.path}/waiter.finished').exists(), isFalse);
        await capture('detached-dark');
        await File('${child.path}/finish').writeAsString('complete');
        await until(() => File('${child.path}/waiter.finished').existsSync());
        expect(
          await File('${child.path}/waiter.finished').readAsString(),
          '-1',
        );
        final oldRun = controller().selectedRun!;
        await option('Remove');
        await tap(action('Remove'));
        await until(() => controller().presets.length == 0);
        await option('Recent runs');
        await until(() => controller().history.length >= 3);
        expect(
          controller().history.any((r) => r.request.id == oldRun.request.id),
          isTrue,
        );
        await capture('history-dark');
        await tap(action('Close'));
        final after = await owner.workspaces!.read(id);
        expect(after.workspace.selectedProfile!.id, profile);
        await File('$output/result.json').writeAsString(
          jsonEncode({
            'draftCancelPreserved': true,
            'argumentsPreserved': true,
            'nativeChildExecuted': true,
            'nullStdin': true,
            'failedLaunchVisible': true,
            'stopWaitingKeptChildAlive': true,
            'historyAfterPresetRemoval': true,
            'configuredProfileUnchanged': true,
            'narrow': narrow,
            'captureWidth': boundary.currentContext!.size!.width,
            'captureHeight': boundary.currentContext!.size!.height,
            'scale': narrow ? 1.5 : 1.0,
          }),
        );
      } finally {
        await File('${child.path}/finish').writeAsString('complete');
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await owner.close();
        await area.delete(recursive: true);
      }
    },
  );
}
