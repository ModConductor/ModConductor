import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_skse/mc_skse.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class SetupClientFixture extends SkyrimSetupClient {
  SetupClientFixture({this.installed = const {}, this.savedSelection});
  final Set<String> installed;
  final SkyrimSetupSelection? savedSelection;
  SkyrimSetupSelection lastSelection = const SkyrimSetupSelection();
  SkyrimSetupSelection? applied;
  int starts = 0;
  int pageOpens = 0;
  bool cancelled = false;

  SkyrimSetupStatus state(
    SkyrimSetupSelection selection, {
    bool consent = false,
  }) {
    final choices = <String, SkyrimSetupAction>{
      'skse': selection.skse,
      'enb': selection.enb,
      'fnis': selection.fnis,
    };
    final changes = <SkyrimSetupChange>[
      for (final entry in choices.entries)
        if (entry.value != SkyrimSetupAction.unchanged)
          SkyrimSetupChange(
            {'skse': 'SKSE', 'enb': 'ENBSeries', 'fnis': 'FNIS'}[entry.key]!,
            switch (entry.value) {
              SkyrimSetupAction.install => 'Install',
              SkyrimSetupAction.remove => 'Remove',
              SkyrimSetupAction.update => 'Update',
              _ => '',
            },
            entry.key == 'enb'
                ? (selection.enbArchivePath ?? 'Installed files')
                : 'Matching game version',
          ),
    ];
    if (installed.isEmpty && changes.any((item) => item.detail == 'Install')) {
      changes.add(
        const SkyrimSetupChange(
          'Initial profile deployment',
          'Create',
          'Profile',
          supporting: true,
        ),
      );
    }
    return SkyrimSetupStatus(
      phase: consent
          ? SkyrimSetupStatusPhase.settingUpSkse
          : cancelled
          ? SkyrimSetupStatusPhase.cancelled
          : SkyrimSetupStatusPhase.needsConsent,
      status: consent
          ? 'Installing'
          : cancelled
          ? 'Setup cancelled'
          : '',
      detail: '',
      planToken:
          'plan-${selection.skse.index}-${selection.enb.index}-${selection.fnis.index}-${selection.enbArchivePath}',
      changes: changes,
      components: [
        for (final (id, name) in [
          ('skse', 'SKSE'),
          ('enb', 'ENBSeries'),
          ('fnis', 'FNIS'),
        ])
          SkyrimSetupComponent(
            id: id,
            name: name,
            status: installed.contains(id) ? 'Installed' : 'Not installed',
            detail: '',
            ready: installed.contains(id),
            active: false,
            blocked: false,
            installed: installed.contains(id),
          ),
      ],
      selection: selection,
      consentRecorded: consent,
      canStart: selection.canReview,
      canContinue: false,
      active: false,
      ready: false,
      canCancel: consent,
    );
  }

  @override
  Future<SkyrimSetupStatus> read(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
  }) async {
    lastSelection = selection;
    return state(savedSelection ?? selection);
  }

  @override
  Future<SkyrimSetupStatus> start(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
    required String planToken,
  }) async {
    starts++;
    cancelled = false;
    applied = selection;
    expect(planToken, state(selection).planToken);
    return state(selection, consent: true);
  }

  @override
  Future<SkyrimSetupStatus> continueSetup(
    String workspace,
    String profile,
  ) async => state(lastSelection, consent: true);
  @override
  Future<SkyrimSetupStatus> cancel(String workspace, String profile) async {
    cancelled = true;
    return state(const SkyrimSetupSelection());
  }

  @override
  Future<void> openProjectPage(String componentId) async {
    pageOpens++;
  }
}

Widget app(SetupClientFixture client, {ArchiveChooser? choose}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      height: 720,
      child: SkyrimSetupSection(
        client: client,
        chooseArchive:
            choose ??
            () async => const ArchiveFile('/downloads/enbseries.zip', 42),
        workspaceId: 'workspace',
        profileId: 'profile',
      ),
    ),
  ),
);

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('clean setup has no selected action or apply', (tester) async {
    final client = SetupClientFixture();
    await tester.pumpWidget(app(client));
    await settle(tester);
    expect(find.byType(McComponentChoiceRow), findsNWidgets(3));
    expect(client.lastSelection.hasChange, isFalse);
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('review-skyrim-setup')))
          .onPressed,
      isNull,
    );
    expect(client.starts, 0);
  });

  testWidgets('saved setup choices can be reviewed and need Apply', (
    tester,
  ) async {
    final client = SetupClientFixture(
      savedSelection: const SkyrimSetupSelection(
        skse: SkyrimSetupAction.install,
      ),
    );
    await tester.pumpWidget(app(client));
    await settle(tester);
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('review-skyrim-setup')))
          .onPressed,
      isNotNull,
    );
    expect(client.starts, 0);

    await tester.tap(find.byKey(const ValueKey('refresh-skyrim-setup')));
    await settle(tester);
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    await tester.tap(find.byKey(const ValueKey('review-skyrim-setup')));
    await settle(tester);
    expect(find.byType(McChangeSummary), findsOneWidget);
    expect(client.starts, 0);
    await tester.tap(find.byKey(const ValueKey('apply-skyrim-setup')));
    await settle(tester);
    expect(client.starts, 1);
    expect(client.applied!.skse, SkyrimSetupAction.install);
  });

  testWidgets('refresh keeps an edited setup choice', (tester) async {
    final client = SetupClientFixture(
      savedSelection: const SkyrimSetupSelection(
        skse: SkyrimSetupAction.install,
      ),
    );
    await tester.pumpWidget(app(client));
    await settle(tester);
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('refresh-skyrim-setup')));
    await settle(tester);
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    expect(client.starts, 0);
  });

  testWidgets('SKSE alone reviews and applies only SKSE', (tester) async {
    final client = SetupClientFixture();
    await tester.pumpWidget(app(client));
    await settle(tester);
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    expect(client.lastSelection.skse, SkyrimSetupAction.install);
    expect(client.lastSelection.enb, SkyrimSetupAction.unchanged);
    await tester.tap(find.byKey(const ValueKey('review-skyrim-setup')));
    await settle(tester);
    expect(find.byType(McChangeSummary), findsOneWidget);
    expect(
      tester
          .widget<McChangeSummary>(find.byType(McChangeSummary))
          .changes
          .length,
      1,
    );
    expect(find.text('ENBSeries'), findsOneWidget); // Setup row only.
    expect(find.text('Also required'), findsOneWidget);
    expect(client.starts, 0);
    await tester.tap(find.byKey(const ValueKey('apply-skyrim-setup')));
    await settle(tester);
    expect(client.starts, 1);
    expect(client.applied!.skse, SkyrimSetupAction.install);
    expect(client.applied!.enb, SkyrimSetupAction.unchanged);
    expect(client.applied!.fnis, SkyrimSetupAction.unchanged);
  });

  testWidgets('ENB archive is required before review', (tester) async {
    final client = SetupClientFixture();
    await tester.pumpWidget(app(client));
    await settle(tester);
    await tester.tap(find.byType(Switch).at(1));
    await settle(tester);
    expect(find.text('Choose an ENBSeries archive.'), findsOneWidget);
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('review-skyrim-setup')))
          .onPressed,
      isNull,
    );
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is McIconAction &&
            widget.label == 'Choose ENBSeries archive',
      ),
    );
    await settle(tester);
    expect(client.lastSelection.enbArchivePath, '/downloads/enbseries.zip');
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('review-skyrim-setup')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('installed toggle removes and update is separate', (
    tester,
  ) async {
    final client = SetupClientFixture(installed: {'skse', 'enb'});
    await tester.pumpWidget(app(client));
    await settle(tester);
    expect(
      tester.widgetList<Switch>(find.byType(Switch)).map((item) => item.value),
      [true, true, false],
    );
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    expect(client.lastSelection.skse, SkyrimSetupAction.remove);
    expect(client.lastSelection.enb, SkyrimSetupAction.unchanged);
    await tester.tap(find.text('Update').first);
    await settle(tester);
    expect(
      client.lastSelection.skse,
      SkyrimSetupAction.remove,
    ); // Disabled while off.
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    await tester.tap(find.text('Update').first);
    await settle(tester);
    expect(client.lastSelection.skse, SkyrimSetupAction.update);
  });

  testWidgets('back from review does not apply', (tester) async {
    final client = SetupClientFixture();
    await tester.pumpWidget(app(client));
    await settle(tester);
    await tester.tap(find.byType(Switch).last);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('review-skyrim-setup')));
    await settle(tester);
    await tester.tap(find.text('Back'));
    await settle(tester);
    expect(client.starts, 0);
  });

  testWidgets('cancelled setup keeps installed state and needs a new Apply', (
    tester,
  ) async {
    final client = SetupClientFixture(installed: {'skse'});
    await tester.pumpWidget(app(client));
    await settle(tester);
    await tester.tap(find.byType(Switch).at(1));
    await settle(tester);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is McIconAction &&
            widget.label == 'Choose ENBSeries archive',
      ),
    );
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('review-skyrim-setup')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('apply-skyrim-setup')));
    await settle(tester);
    expect(client.starts, 1);

    await tester.tap(find.text('Cancel setup'));
    await settle(tester);
    expect(find.text('Clear choices'), findsNothing);
    expect(client.starts, 1);
    expect(
      tester.widgetList<Switch>(find.byType(Switch)).map((item) => item.value),
      [true, false, false],
    );
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('review-skyrim-setup')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byType(Switch).last);
    await settle(tester);
    expect(client.lastSelection.fnis, SkyrimSetupAction.install);
    await tester.tap(find.byKey(const ValueKey('review-skyrim-setup')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('apply-skyrim-setup')));
    await settle(tester);
    expect(client.starts, 2);
    expect(client.applied!.fnis, SkyrimSetupAction.install);
    expect(client.applied!.enb, SkyrimSetupAction.unchanged);
  });

  testWidgets('component controls fit a narrow window', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final client = SetupClientFixture(installed: {'skse', 'enb', 'fnis'});
    await tester.pumpWidget(app(client));
    await settle(tester);
    expect(find.byType(McComponentChoiceRow), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('new and installed control rows keep their controls aligned', (
    tester,
  ) async {
    final client = SetupClientFixture(installed: {'skse'});
    await tester.pumpWidget(app(client));
    await settle(tester);
    await tester.tap(find.byType(Switch).at(1));
    await settle(tester);

    final skse = find.byKey(const ValueKey('setup-skse'));
    final enb = find.byKey(const ValueKey('setup-enb'));
    final skseSwitch = find.descendant(of: skse, matching: find.byType(Switch));
    final enbSwitch = find.descendant(of: enb, matching: find.byType(Switch));
    final sksePage = find.descendant(
      of: skse,
      matching: find.byType(McIconAction),
    );
    final enbActions = find.descendant(
      of: enb,
      matching: find.byType(McIconAction),
    );
    final update = find.descendant(of: skse, matching: find.text('Update'));

    expect(
      tester.getRect(skseSwitch).center.dy,
      tester.getRect(sksePage).center.dy,
    );
    expect(
      tester.getRect(enbSwitch).center.dy,
      tester.getRect(enbActions.at(0)).center.dy,
    );
    expect(
      tester.getRect(enbSwitch).center.dy,
      tester.getRect(enbActions.at(1)).center.dy,
    );
    expect(
      tester.getRect(skseSwitch).center.dy,
      tester.getRect(update).center.dy,
    );
    expect(
      tester.getRect(enbActions.at(0)).right,
      tester.getRect(enbActions.at(1)).left,
    );
    expect(find.text('Choose an ENBSeries archive.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
