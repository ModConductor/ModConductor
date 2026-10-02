import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_bepinex/mc_bepinex.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

const package = ThunderstoreVersionRef(
  ThunderstorePackageRef('valheim', 'denikson', 'BepInExPack_Valheim'),
  '5.4.2333',
);

class LoaderFixture implements BepInExClient {
  ThunderstoreVersionRef? reference = package;
  String? mod;
  bool enabled = false;
  int changes = 0;
  String content = 'Enabled = true\n';
  BepInExState get state => BepInExState(
    workspace: 'workspace',
    profile: 'profile',
    contextRevision: 1,
    selectionRevision: changes,
    package: reference,
    enabled: enabled,
    mod: mod,
    settingsAvailable: mod != null,
    logAvailable: mod != null,
  );
  LoaderText get text => LoaderText(
    TextDocument(
      content: content,
      encoding: TextDocumentEncoding.utf8,
      newline: TextDocumentNewline.lf,
      finalTerminator: true,
      lines: 2,
    ),
    const [1, 2, 3],
  );
  @override
  Future<LoaderReply<BepInExState>> read(
    String workspace,
    String profile,
  ) async => LoaderValue(state);
  @override
  Future<LoaderReply<BepInExState>> change(
    BepInExState state,
    bool value,
  ) async {
    enabled = value;
    changes++;
    return LoaderValue(this.state);
  }

  @override
  Future<LoaderReply<LoaderText>> settings(
    String workspace,
    String profile,
  ) async => LoaderValue(text);
  @override
  Future<LoaderReply<LoaderText>> saveSettings(
    String workspace,
    String profile,
    LoaderText original,
    String content,
  ) async {
    this.content = content;
    return LoaderValue(text);
  }

  @override
  Future<LoaderReply<LoaderText>> log(String workspace, String profile) async =>
      LoaderValue(text);
}

class PackageFixture implements ThunderstoreClient {
  PackageFixture(this.loader);
  final LoaderFixture loader;
  int acquisitions = 0;
  @override
  ThunderstoreAcquisition acquire(
    String workspace,
    ThunderstoreVersionRef reference,
  ) {
    acquisitions++;
    Stream<ThunderstoreProgress> values() async* {
      loader.mod = 'mod';
      yield ThunderstoreProgress(
        reference: reference,
        stage: 'added',
        bytes: 42,
        completed: 1,
        packages: 1,
        modId: 'mod',
      );
      yield ThunderstoreProgress(
        reference: reference,
        stage: 'complete',
        bytes: 42,
        completed: 1,
        packages: 1,
      );
    }

    return ThunderstoreAcquisition(values(), () async {});
  }

  @override
  Future<ThunderstoreProblem?> openPage(
    ThunderstorePackageRef reference,
  ) async => null;
  @override
  Future<ThunderstoreReply<ThunderstorePackageInfo>> package(
    String workspace,
    ThunderstorePackageRef package, {
    String? version,
  }) async => const ThunderstoreRefusal(
    ThunderstoreProblem('Not part of this action.'),
  );
  @override
  Future<ThunderstoreReply<ThunderstorePage>> search(
    String workspace,
    String community,
    String query,
    String ordering,
    int page,
  ) async => const ThunderstoreRefusal(
    ThunderstoreProblem('Not part of this action.'),
  );
}

Future<void> show(
  WidgetTester tester,
  LoaderFixture loader,
  PackageFixture packages,
  ChangeNotifier updates,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: mcTheme(Brightness.light),
      home: Scaffold(
        body: BepInExSection(
          client: loader,
          packages: packages,
          workspace: 'workspace',
          profile: 'profile',
          changes: updates,
          onChanged: updates.notifyListeners,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('installed archive toggles without marketplace acquisition', (
    tester,
  ) async {
    final loader = LoaderFixture()
      ..reference = null
      ..mod = 'archive';
    final packages = PackageFixture(loader);
    final updates = ChangeNotifier();
    await show(tester, loader, packages, updates);
    expect(
      tester
          .widget<McComponentChoiceRow>(find.byType(McComponentChoiceRow))
          .onOpenPage,
      isNull,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(loader.enabled, isTrue);
    expect(packages.acquisitions, 0);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(loader.enabled, isFalse);
    expect(loader.mod, 'archive');
    await tester.pumpWidget(const SizedBox.shrink());
    updates.dispose();
  });
  testWidgets(
    'direct toggle acquires then enables, and disables without reacquisition',
    (tester) async {
      final loader = LoaderFixture();
      final packages = PackageFixture(loader);
      final updates = ChangeNotifier();
      await show(tester, loader, packages, updates);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(packages.acquisitions, 1);
      expect(loader.enabled, isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(loader.enabled, isFalse);
      expect(packages.acquisitions, 1);
      expect(loader.mod, 'mod');
      await tester.pumpWidget(const SizedBox.shrink());
      updates.dispose();
    },
  );
  testWidgets('existing profile changes update the row without polling', (
    tester,
  ) async {
    final loader = LoaderFixture()..mod = 'mod';
    final packages = PackageFixture(loader);
    final updates = ChangeNotifier();
    await show(tester, loader, packages, updates);
    loader.enabled = true;
    updates.notifyListeners();
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(packages.acquisitions, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    updates.dispose();
  });
  testWidgets(
    'secondary settings editor guards an unsaved draft and saves through the client',
    (tester) async {
      final loader = LoaderFixture()
        ..mod = 'mod'
        ..enabled = true;
      final updates = ChangeNotifier();
      await show(tester, loader, PackageFixture(loader), updates);
      await tester.tap(find.text('Tools'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit loader settings'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Enabled = false\n');
      await tester.pump();
      final toolbox = tester.state<TextEditorToolboxState>(
        find.byType(TextEditorToolbox),
      );
      unawaited(toolbox.requestClose());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(loader.content, 'Enabled = true\n');
      await tester.ensureVisible(find.text('Save settings').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save settings').last);
      await tester.pumpAndSettle();
      expect(loader.content, 'Enabled = false\n');
      expect(find.byType(TextEditorToolbox), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      updates.dispose();
    },
  );
}
