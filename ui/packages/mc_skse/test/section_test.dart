import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_skse/mc_skse.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class SetupClientFixture extends SkyrimSetupClient {
  SetupClientFixture({
    this.installed = const {},
    this.savedSelection,
    this.failFirstStart = false,
    this.completeWithFnisWarning = false,
    this.updateVersion,
  });
  final Set<String> installed;
  final SkyrimSetupSelection? savedSelection;
  final bool failFirstStart;
  final bool completeWithFnisWarning;
  String? updateVersion;
  SkyrimSetupSelection lastSelection = const SkyrimSetupSelection();
  SkyrimSetupSelection? applied;
  int starts = 0;
  int continues = 0;
  int reads = 0;
  int pageOpens = 0;
  final updates = <String, StreamController<SkyrimSetupStatus>>{};
  bool cancelled = false;
  bool completed = false;
  bool recoveryRequired = false;
  bool running = false, failed = false;
  final warningStatus = 'FNIS output is available, but FNIS exited with code 7';

  SkyrimSetupStatus state(
    SkyrimSetupSelection selection, {
    bool running = false,
    bool failed = false,
  }) {
    return SkyrimSetupStatus(
      phase: recoveryRequired
          ? SkyrimSetupStatusPhase.recoveryRequired
          : failed
          ? SkyrimSetupStatusPhase.failed
          : running
          ? SkyrimSetupStatusPhase.settingUpSkse
          : cancelled
          ? SkyrimSetupStatusPhase.cancelled
          : SkyrimSetupStatusPhase.available,
      status: recoveryRequired
          ? 'Cancellation needs completion'
          : failed
          ? 'Setup failed'
          : running
          ? 'Installing'
          : cancelled
          ? 'Setup cancelled'
          : '',
      detail: '',
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
            updateVersion: id == 'skse' ? updateVersion : null,
          ),
      ],
      selection: selection,
      canStart: selection.canApply,
      canContinue: failed || recoveryRequired,
      active: false,
      ready: false,
      canCancel: running || failed,
    );
  }

  SkyrimSetupStatus fnisWarningState(
    SkyrimSetupSelection selection, {
    required bool ready,
    required bool canContinue,
  }) => SkyrimSetupStatus(
    phase: ready
        ? SkyrimSetupStatusPhase.ready
        : SkyrimSetupStatusPhase.available,
    status: warningStatus,
    detail: 'Check the FNIS messages before you use these files.',
    components: state(selection).components,
    selection: selection,
    canStart: false,
    canContinue: canContinue,
    active: false,
    ready: ready,
    canCancel: false,
  );

  @override
  Future<SkyrimSetupStatus> read(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
  }) async {
    reads++;
    lastSelection = selection;
    if (completeWithFnisWarning && completed) {
      return fnisWarningState(selection, ready: false, canContinue: false);
    }
    return state(savedSelection ?? selection, running: running, failed: failed);
  }

  @override
  Stream<SkyrimSetupStatus> watch(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
  }) async* {
    yield await read(workspace, profile, selection: selection);
    yield* updates
        .putIfAbsent(
          '$workspace:$profile',
          () => StreamController<SkyrimSetupStatus>.broadcast(),
        )
        .stream;
  }

  void emit(String workspace, String profile, SkyrimSetupStatus status) =>
      updates['$workspace:$profile']?.add(status);

  @override
  Future<SkyrimSetupStatus> start(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
  }) async {
    starts++;
    cancelled = false;
    applied = selection;
    if (completeWithFnisWarning) {
      completed = true;
      return fnisWarningState(selection, ready: true, canContinue: true);
    }
    failed = failFirstStart && starts == 1;
    running = !failed;
    return state(selection, running: running, failed: failed);
  }

  @override
  Future<SkyrimSetupStatus> continueSetup(
    String workspace,
    String profile,
  ) async {
    continues++;
    recoveryRequired = false;
    if (completeWithFnisWarning) {
      completed = true;
      return fnisWarningState(lastSelection, ready: true, canContinue: false);
    }
    return state(lastSelection, running: true);
  }

  @override
  Future<SkyrimSetupStatus> cancel(String workspace, String profile) async {
    cancelled = true;
    running = false;
    failed = false;
    return state(const SkyrimSetupSelection());
  }

  @override
  Future<void> openProjectPage(String componentId) async {
    pageOpens++;
  }
}

class ReconnectSetupFixture extends SetupClientFixture {
  ReconnectSetupFixture({Set<String>? installed, String? updateVersion})
    : super(installed: installed ?? <String>{}, updateVersion: updateVersion);

  Completer<void>? snapshotGate;

  @override
  Stream<SkyrimSetupStatus> watch(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
  }) {
    final controller = StreamController<SkyrimSetupStatus>.broadcast();
    updates['$workspace:$profile'] = controller;
    scheduleMicrotask(() async {
      await snapshotGate?.future;
      controller.add(await read(workspace, profile, selection: selection));
    });
    return controller.stream;
  }
}

Widget app(
  SetupClientFixture client, {
  ArchiveChooser? choose,
  double height = 720,
  String profileId = 'profile',
}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      height: height,
      child: SkyrimSetupSection(
        client: client,
        chooseArchive:
            choose ??
            () async => const ArchiveFile('/downloads/enbseries.zip', 42),
        workspaceId: 'workspace',
        profileId: profileId,
      ),
    ),
  ),
);

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets(
    'setup watch reconnects with current state after stream failure',
    (tester) async {
      final client = ReconnectSetupFixture();
      await tester.pumpWidget(app(client));
      await settle(tester);
      final reads = client.reads;
      client.updates['workspace:profile']!.addError(
        StateError('connection lost'),
      );
      await tester.pump();
      client.installed.add('fnis');
      await tester.pump(const Duration(milliseconds: 1100));
      await settle(tester);
      expect(client.reads, reads + 1);
      expect(find.text('Installed'), findsWidgets);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(client.reads, reads + 1);
      await client.updates['workspace:profile']!.close();
      client.installed.add('skse');
      await tester.pump(const Duration(milliseconds: 1100));
      await settle(tester);
      expect(client.reads, reads + 2);
    },
  );

  testWidgets('a failed watch withholds stale update until a fresh snapshot', (
    tester,
  ) async {
    final client = ReconnectSetupFixture(
      installed: {'skse'},
      updateVersion: '2.3.0',
    );
    await tester.pumpWidget(app(client));
    await settle(tester);
    final skse = find.byKey(const ValueKey('setup-skse'));
    await tester.tap(find.descendant(of: skse, matching: find.text('Update')));
    await settle(tester);
    expect(client.lastSelection.skse, SkyrimSetupAction.update);

    client.snapshotGate = Completer<void>();
    client.updates['workspace:profile']!.addError(
      StateError('connection lost'),
    );
    await tester.pump();
    expect(
      find.descendant(of: skse, matching: find.text('Update')),
      findsNothing,
    );
    expect(
      find.descendant(of: skse, matching: find.text('2.3.0')),
      findsNothing,
    );
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('apply-skyrim-setup')))
          .onPressed,
      isNull,
    );
    await tester.pump(const Duration(milliseconds: 1100));
    expect(
      find.descendant(of: skse, matching: find.text('Update')),
      findsNothing,
    );
    expect(client.starts, 0);

    client.snapshotGate!.complete();
    await settle(tester);
    expect(
      find.descendant(of: skse, matching: find.text('Update')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: skse, matching: find.text('2.3.0')),
      findsOneWidget,
    );
    expect(client.starts, 0);
  });

  testWidgets(
    'setup events update the open controls without reads or Continue',
    (tester) async {
      final client = SetupClientFixture();
      await tester.pumpWidget(app(client));
      await settle(tester);
      final reads = client.reads;

      client.emit(
        'workspace',
        'profile',
        client.state(const SkyrimSetupSelection(), running: true),
      );
      await settle(tester);
      expect(find.text('Cancel setup'), findsOneWidget);

      client.emit(
        'workspace',
        'profile',
        client.state(const SkyrimSetupSelection(), failed: true),
      );
      await settle(tester);
      expect(find.text('Try again'), findsOneWidget);
      expect(client.reads, reads);
      expect(client.continues, 0);
    },
  );

  testWidgets('a previous profile event cannot replace the current setup', (
    tester,
  ) async {
    final client = SetupClientFixture(
      installed: {'skse'},
      updateVersion: '2.3.0',
    );
    await tester.pumpWidget(app(client));
    await settle(tester);

    client.updateVersion = null;
    await tester.pumpWidget(app(client, profileId: 'other'));
    await settle(tester);
    client.updateVersion = '2.3.0';
    client.emit(
      'workspace',
      'profile',
      client.state(const SkyrimSetupSelection(), running: true),
    );
    await settle(tester);
    expect(find.text('Cancel setup'), findsNothing);
    expect(find.text('Update'), findsNothing);
  });

  testWidgets('FNIS exit warning remains after setup completes and refreshes', (
    tester,
  ) async {
    final client = SetupClientFixture(completeWithFnisWarning: true);
    await tester.pumpWidget(app(client));
    await settle(tester);
    await tester.tap(find.byType(Switch).last);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('apply-skyrim-setup')));
    await settle(tester);
    await tester.pump();
    await settle(tester);

    expect(client.starts, 1);
    expect(client.continues, 0);
    expect(find.text(client.warningStatus), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(client.continues, 0);

    await tester.tap(find.byKey(const ValueKey('refresh-skyrim-setup')));
    await settle(tester);
    expect(find.text(client.warningStatus), findsOneWidget);
  });

  testWidgets('clean setup has no selected action or apply', (tester) async {
    final client = SetupClientFixture();
    await tester.pumpWidget(app(client));
    await settle(tester);
    expect(find.byType(McComponentChoiceRow), findsNWidgets(3));
    expect(client.lastSelection.hasChange, isFalse);
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('apply-skyrim-setup')))
          .onPressed,
      isNull,
    );
    expect(client.starts, 0);
  });

  testWidgets('installed components without targets offer no update', (
    tester,
  ) async {
    final client = SetupClientFixture(installed: {'skse', 'enb', 'fnis'});
    await tester.pumpWidget(app(client));
    await settle(tester);
    expect(find.text('Update'), findsNothing);
    expect(client.lastSelection.hasChange, isFalse);
    expect(client.starts, 0);
  });

  testWidgets('saved setup choices need Apply', (tester) async {
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
          .widget<McAction>(find.byKey(const ValueKey('apply-skyrim-setup')))
          .onPressed,
      isNotNull,
    );
    expect(client.starts, 0);

    await tester.tap(find.byKey(const ValueKey('refresh-skyrim-setup')));
    await settle(tester);
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
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

  testWidgets('Apply installs only the selected SKSE component', (
    tester,
  ) async {
    final client = SetupClientFixture();
    await tester.pumpWidget(app(client));
    await settle(tester);
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    expect(client.lastSelection.skse, SkyrimSetupAction.install);
    expect(client.lastSelection.enb, SkyrimSetupAction.unchanged);
    await tester.tap(find.byKey(const ValueKey('apply-skyrim-setup')));
    await settle(tester);
    expect(client.starts, 1);
    expect(client.applied!.skse, SkyrimSetupAction.install);
    expect(client.applied!.enb, SkyrimSetupAction.unchanged);
    expect(client.applied!.fnis, SkyrimSetupAction.unchanged);
  });

  testWidgets('cancelled setup can be applied without scrolling', (
    tester,
  ) async {
    final client = SetupClientFixture()..cancelled = true;
    await tester.pumpWidget(app(client, height: 310));
    await settle(tester);

    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('apply-skyrim-setup')));
    await settle(tester);

    expect(client.starts, 1);
    expect(client.applied!.skse, SkyrimSetupAction.install);
  });

  testWidgets('ENB archive is required before Apply', (tester) async {
    final client = SetupClientFixture();
    await tester.pumpWidget(app(client));
    await settle(tester);
    await tester.tap(find.byType(Switch).at(1));
    await settle(tester);
    expect(find.text('Choose an ENBSeries archive.'), findsOneWidget);
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('apply-skyrim-setup')))
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
          .widget<McAction>(find.byKey(const ValueKey('apply-skyrim-setup')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a failed setup keeps choices editable for another Apply', (
    tester,
  ) async {
    final client = SetupClientFixture(failFirstStart: true);
    await tester.pumpWidget(app(client));
    await settle(tester);
    await tester.tap(find.byType(Switch).last);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('apply-skyrim-setup')));
    await settle(tester);
    expect(client.starts, 1);
    expect(tester.widget<Switch>(find.byType(Switch).last).value, isTrue);

    await tester.tap(find.byType(Switch).last);
    await settle(tester);
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('apply-skyrim-setup')));
    await settle(tester);
    expect(client.starts, 2);
    expect(client.applied!.skse, SkyrimSetupAction.install);
    expect(client.applied!.fnis, SkyrimSetupAction.unchanged);
  });

  testWidgets('Try again starts the failed setup explicitly', (tester) async {
    final client = SetupClientFixture(failFirstStart: true);
    await tester.pumpWidget(app(client));
    await settle(tester);
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('apply-skyrim-setup')));
    await settle(tester);
    expect(client.starts, 1);

    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(client.starts, 2);
    expect(client.continues, 0);
    expect(client.applied!.skse, SkyrimSetupAction.install);
  });

  testWidgets('Continue recovery resumes persisted cancellation', (
    tester,
  ) async {
    final client = SetupClientFixture()..recoveryRequired = true;
    await tester.pumpWidget(app(client));
    await settle(tester);
    expect(find.text('Continue recovery'), findsOneWidget);

    await tester.tap(find.text('Continue recovery'));
    await settle(tester);
    expect(client.continues, 1);
    expect(client.starts, 0);
  });

  testWidgets('installed toggle removes and update is separate', (
    tester,
  ) async {
    final client = SetupClientFixture(
      installed: {'skse', 'enb'},
      updateVersion: '2.3.0',
    );
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

  testWidgets('confirmed SKSE update appears and clears in the open setup', (
    tester,
  ) async {
    final client = SetupClientFixture(installed: {'skse'});
    await tester.pumpWidget(app(client));
    await settle(tester);
    final skse = find.byKey(const ValueKey('setup-skse'));
    expect(
      find.descendant(of: skse, matching: find.text('Update')),
      findsNothing,
    );

    client.updateVersion = '2.3.0';
    client.emit(
      'workspace',
      'profile',
      client.state(const SkyrimSetupSelection()),
    );
    await settle(tester);
    expect(
      find.descendant(of: skse, matching: find.text('Update')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: skse, matching: find.text('2.3.0')),
      findsOneWidget,
    );

    await tester.tap(find.descendant(of: skse, matching: find.text('Update')));
    await settle(tester);
    expect(client.lastSelection.skse, SkyrimSetupAction.update);

    client.updateVersion = null;
    client.emit(
      'workspace',
      'profile',
      client.state(const SkyrimSetupSelection(skse: SkyrimSetupAction.update)),
    );
    await settle(tester);
    expect(
      find.descendant(of: skse, matching: find.text('Update')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('apply-skyrim-setup')), findsOneWidget);
    expect(client.lastSelection.skse, SkyrimSetupAction.update);
    await tester.tap(find.byIcon(Icons.refresh).first);
    await settle(tester);
    expect(client.lastSelection.skse, SkyrimSetupAction.unchanged);
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
          .widget<McAction>(find.byKey(const ValueKey('apply-skyrim-setup')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byType(Switch).last);
    await settle(tester);
    expect(client.lastSelection.fnis, SkyrimSetupAction.install);
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
    final client = SetupClientFixture(
      installed: {'skse'},
      updateVersion: '2.3.0',
    );
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
