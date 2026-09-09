import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_executables/mc_executables.dart';
import 'package:mc_profile_data/mc_profile_data.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'profile options apply on Play, preserve mutable files and restore globals',
    (tester) async {
      const engine = String.fromEnvironment('MC_ENGINE_PATH'),
          fixture = String.fromEnvironment('MC_NATIVE_FIXTURE'),
          output = String.fromEnvironment('MC_PROFILE_OUTPUT');
      const narrow = bool.fromEnvironment('MC_PROFILE_NARROW');
      if (!Platform.isLinux ||
          engine.isEmpty ||
          fixture.isEmpty ||
          output.isEmpty) {
        throw StateError('Select Linux native tools and owned evidence.');
      }
      await Directory(output).create(recursive: true);
      final reportError = FlutterError.onError;
      FlutterError.onError = (details) {
        File('$output/flutter-errors.txt').writeAsStringSync(
          '${details.exceptionAsString()}\n${details.stack}\n',
          mode: FileMode.append,
        );
        reportError?.call(details);
      };
      final area = await Directory(output).createTemp('fixture-');
      final root = await Directory('${area.path}/workspace').create();
      final inputs = '${area.path}/installation';
      final seeded = await Process.run(fixture, ['--proton-files', inputs]);
      expect(seeded.exitCode, 0, reason: '${seeded.stderr}');
      final steam = '$inputs/Steam', library = '$inputs/Second library';
      final game = '$library/steamapps/common/Skyrim Special Edition';
      final runtime = '$steam/compatibilitytools.d/Custom Ω Proton';
      await File('$runtime/proton').writeAsString('#!/bin/sh\nexit 0\n');
      expect(
        (await Process.run('chmod', ['u+x', '$runtime/proton'])).exitCode,
        0,
      );
      await File('$runtime/toolmanifest.vdf')
          .writeAsString('manifest { version 2 commandline "/proton %verb%" }');
      final owner = EngineOwner(
        engine,
        launch: (path) =>
            Process.start(path, ['--state-directory', '${area.path}/state']),
      );
      final boundary = GlobalKey();
      Finder action(String label) => find.byWidgetPredicate(
        (widget) => widget is McAction && widget.label == label,
      );
      ProfileDataController data() => tester
          .widget<ProfileSettingsInspector>(
            find.byType(ProfileSettingsInspector).last,
          )
          .controller;
      GamePlayController play() => tester
          .widget<GamePlayActions>(find.byType(GamePlayActions))
          .controller;
      Future<void> frames() async {
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }

      Future<void> until(bool Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (!condition() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(condition(), isTrue);
        await frames();
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await frames();
        await tester.tap(finder);
        await frames();
      }

      Future<void> capture(String name) async {
        await frames();
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$output/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }

      Finder inspectorScroll() => find
          .descendant(
            of: find.byType(McInspector),
            matching: find.byType(Scrollable),
          )
          .first;
      Future<void> inspectorAction(String label) async {
        final finder = action(label);
        await tester.scrollUntilVisible(
          finder,
          160,
          scrollable: inspectorScroll(),
          maxScrolls: 12,
        );
        await tap(finder);
      }

      Future<void> closeInspector() async {
        final close = find.byWidgetPredicate(
          (w) => w is McIconAction && w.label == 'Close inspector',
        );
        await tester.scrollUntilVisible(
          close,
          -160,
          scrollable: inspectorScroll(),
          maxScrolls: 12,
        );
        await tap(close);
      }

      Future<void> openInspector() async {
        await tap(action('Settings and saves'));
        await until(
          () =>
              find.byType(ProfileSettingsInspector).evaluate().isNotEmpty &&
              data().state != null &&
              !data().busy,
        );
        if (data().needsRead) {
          await inspectorAction('Read again');
          await until(() => !data().busy);
        }
        final close = find.byWidgetPredicate(
          (w) => w is McIconAction && w.label == 'Close inspector',
        );
        await tester.scrollUntilVisible(
          close,
          -160,
          scrollable: inspectorScroll(),
          maxScrolls: 12,
        );
        await frames();
      }

      try {
        await owner.connect();
        final id = newOperationId(), first = newOperationId();
        await owner.workspaces!.create(id, 'Profile game files', root.path);
        await owner.workspaces!.createProfile(
          id,
          0,
          ProfileInfo(first, 'Everyday'),
        );
        final checked = await owner.gameContexts!.save(
          id,
          0,
          game,
          proton: ProtonSelection(
            appId: 489830,
            association: SteamProtonAssociation(steam, library),
            compatData: '$library/steamapps/compatdata/489830',
            runtimeDirectory: runtime,
            toolId: 'fixture_tool',
          ),
        );
        final documents =
            (checked.binding!.evidence.documents as LocatedGameFolder).path;
        final prefs = File('$documents/SkyrimPrefs.ini');
        await prefs.writeAsString('[Display]\niSize W=1280\n');
        final original = await prefs.readAsBytes();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              workspaces: owner.workspaces,
              gameContexts: owner.gameContexts,
              deployments: owner.deployments,
              executables: owner.executables,
              gameLaunching: owner.gameLaunching,
              profileData: owner.profileData,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(find.byKey(ValueKey('workspace-$id')));
        await until(() => play().connected && !play().reading);
        if (narrow) {
          await tap(find.byKey(const ValueKey('nav-preferences')));
          await tap(find.byKey(const ValueKey('preferences-scale')));
          await tap(find.text('150%').last);
          await tap(find.byKey(const ValueKey('apply-preferences')));
          await tap(find.byKey(const ValueKey('nav-workspaces')));
        }
        await capture('profiles-light');
        await tap(find.byKey(ValueKey((profileId: first))));
        await openInspector();
        await capture('initial-light');
        await tap(action('Edit settings'));
        await tap(find.widgetWithText(CheckboxListTile, 'Local game settings'));
        await tap(find.widgetWithText(CheckboxListTile, 'Local saves'));
        await capture('initial-options-light');
        await tap(action('Cancel'));
        expect(
          (await owner.profileData!.read(id, first)).options.saves,
          isFalse,
        );
        await tap(action('Edit settings'));
        await tap(find.widgetWithText(CheckboxListTile, 'Local game settings'));
        await tap(find.widgetWithText(CheckboxListTile, 'Local saves'));
        await tap(action('Save'));
        await until(() => !data().busy && data().state!.options.saves);
        expect(await prefs.readAsBytes(), original);
        expect(await File('$documents/Skyrim.ini').exists(), isFalse);
        await capture('enabled-light');
        await inspectorAction('View save files');
        await capture('empty-saves-light');
        await tap(action('Close').last);
        await closeInspector();
        await tap(action('Play'));
        await until(() => play().run?.phase == ExecutableRunPhase.finished);
        expect(play().run!.game!.files, isNotNull);
        expect(play().run!.game!.profileData?.complete, isTrue);
        await tap(action('Close').last);
        await openInspector();
        expect(data().state!.inUseProfileId, first);
        final privateSaves = data().state!.savesPath;
        await File('$privateSaves/Disposable.ess')
            .writeAsString('owned fixture save');
        await File('$documents/new-prefs.tmp')
            .writeAsString('[Display]\niSize W=900\n');
        await File('$documents/new-prefs.tmp').rename(prefs.path);
        await capture('in-use-light');
        await inspectorAction('Restore global settings and saves');
        await capture('restore-light');
        await tap(action('Cancel'));
        expect(
          (await owner.profileData!.read(id, first)).inUseProfileId,
          first,
        );
        await inspectorAction('Restore global settings and saves');
        await tap(action('Restore'));
        await until(() => !data().busy && data().state!.inUseProfileId == null);
        expect(await prefs.readAsBytes(), original);
        expect(await File('$documents/Skyrim.ini').exists(), isFalse);
        expect(
          await File('${data().state!.settingsPath}/SkyrimPrefs.ini')
              .readAsString(),
          contains('900'),
        );
        await inspectorAction('View save files');
        await until(() => find.text('Disposable.ess').evaluate().isNotEmpty);
        await capture('private-saves-light');
        await tap(action('Close').last);
        await tap(action('Edit settings'));
        await tap(find.widgetWithText(CheckboxListTile, 'Local saves'));
        await tap(action('Save'));
        await capture('disable-keep-light');
        await tap(action('Cancel'));
        expect(data().state!.options.saves, isTrue);
        await tap(action('Edit settings'));
        await tap(find.widgetWithText(CheckboxListTile, 'Local saves'));
        await tap(action('Save'));
        await tap(action('Turn off'));
        await until(() => !data().busy && !data().state!.options.saves);
        expect(
          await File('$privateSaves/Disposable.ess').readAsString(),
          'owned fixture save',
        );
        await closeInspector();
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await tap(find.byKey(const ValueKey('preferences-theme')));
        await tap(find.text('Dark').last);
        await tap(find.byKey(const ValueKey('apply-preferences')));
        await tap(find.byKey(const ValueKey('nav-workspaces')));
        await openInspector();
        await capture('restored-dark');
        await closeInspector();
        expect(await prefs.readAsBytes(), original);
        await File('$output/result.json').writeAsString(
          jsonEncode({
            'initialCancelPreservedOptions': true,
            'enableDidNotApply': true,
            'playCapturedBothReceipts': true,
            'restoreCancelPreservedActiveProfile': true,
            'restoreCapturedAtomicSettingsReplacement': true,
            'saveFilesAreInspectable': true,
            'disableCancelPreservedOptions': true,
            'disableKeepPreservedSaves': true,
            'globalSettingsAndAbsenceRestored': true,
            'inspectorCloseReachable': true,
            'viewport': tester.view.physicalSize.toString(),
            'textScale': narrow ? 1.5 : 1.0,
          }),
        );
      } catch (error, stack) {
        File('$output/failure-stack.txt')
            .writeAsStringSync('${error.runtimeType}\n$stack');
        rethrow;
      } finally {
        await tester.pumpWidget(const SizedBox());
        await owner.close();
        await Process.run('chmod', ['-R', 'u+w', root.path]);
        await area.delete(recursive: true);
        FlutterError.onError = reportError;
      }
    },
  );
}
