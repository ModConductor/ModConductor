import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_unreal/mc_unreal.dart';

class _Client implements UnrealClient {
  UnrealLoaderState current = const UnrealLoaderState(
    workspace: 'w',
    profile: 'p',
    contextRevision: 1,
    selectionRevision: 1,
    id: 'declared-loader',
    name: 'Another loader',
    version: 'fixture',
    iconUrl: '',
    iconHeaders: {},
    enabled: false,
    archiveRequired: true,
    settingsFiles: [],
    logAvailable: false,
  );
  int acquisitions = 0, reads = 0;
  final changes = <bool>[];
  String? archive;
  bool cancelled = false;
  StreamController<UnrealProgress>? stream;
  @override
  Future<LoaderReply<UnrealLoaderState>> read(
    String workspace,
    String profile,
  ) async {
    reads++;
    return LoaderValue(current);
  }

  @override
  Stream<UnrealProgress> acquire(UnrealLoaderState state, String? archive) {
    acquisitions++;
    this.archive = archive;
    stream = StreamController<UnrealProgress>(
      onCancel: () {
        cancelled = true;
      },
    );
    return stream!.stream;
  }

  @override
  Future<LoaderReply<UnrealLoaderState>> change(
    UnrealLoaderState state,
    bool enabled,
  ) async {
    changes.add(enabled);
    current = _loader(
      id: current.id,
      contextRevision: current.contextRevision,
      selectionRevision: current.selectionRevision + 1,
      mod: current.mod,
      enabled: enabled,
      archiveRequired: current.archiveRequired,
    );
    return LoaderValue(current);
  }

  @override
  Future<LoaderReply<LoaderText>> settings(
    UnrealLoaderState state,
    String name,
  ) async => const LoaderProblem('not available');
  @override
  Future<LoaderReply<LoaderText>> save(
    UnrealLoaderState state,
    String name,
    LoaderText original,
    String content,
  ) async => const LoaderProblem('not available');
  @override
  Future<LoaderReply<LoaderText>> log(UnrealLoaderState state) async =>
      const LoaderProblem('not available');
  @override
  Future<String?> openPage(UnrealLoaderState state) async => null;
}

UnrealLoaderState _loader({
  String id = 'declared-loader',
  int contextRevision = 1,
  int selectionRevision = 1,
  String? mod,
  bool enabled = false,
  bool archiveRequired = true,
}) => UnrealLoaderState(
  workspace: 'w',
  profile: 'p',
  contextRevision: contextRevision,
  selectionRevision: selectionRevision,
  id: id,
  name: 'Another loader',
  version: 'fixture',
  iconUrl: '',
  iconHeaders: {},
  mod: mod,
  enabled: enabled,
  archiveRequired: archiveRequired,
  settingsFiles: [],
  logAvailable: false,
);

void main() {
  testWidgets(
    'a declared loader follows profile events and keeps archive selection next to its toggle',
    (tester) async {
      final client = _Client();
      final changes = ChangeNotifier();
      addTearDown(changes.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnrealLoaderSection(
              client: client,
              workspace: 'w',
              profile: 'p',
              changes: changes,
              onChanged: () {},
              chooseArchive: () async => null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, false);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(client.acquisitions, 0);
      final before = client.reads;
      client.current = const UnrealLoaderState(
        workspace: 'w',
        profile: 'p',
        contextRevision: 1,
        selectionRevision: 2,
        id: 'declared-loader',
        name: 'Changed declared loader',
        version: 'fixture',
        iconUrl: '',
        iconHeaders: {},
        enabled: true,
        archiveRequired: true,
        mod: 'external-selection',
        settingsFiles: [],
        logAvailable: false,
      );
      changes.notifyListeners();
      await tester.pumpAndSettle();
      expect(client.reads, before + 1);
      expect(tester.widget<Switch>(find.byType(Switch)).value, true);
      expect(find.text('Changed declared loader'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(client.changes, [false]);
      expect(tester.widget<Switch>(find.byType(Switch)).value, false);
      expect(client.acquisitions, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final contextChanged in [false, true]) {
    test(
      contextChanged
          ? 'a new context drops the archive selected for the previous installation'
          : 'a new loader drops the archive selected for the previous declaration',
      () async {
        final client = _Client()
          ..current = _loader(mod: 'selected-loader', enabled: true);
        final controller = UnrealLoaderController(client, 'w', 'p', () {});
        addTearDown(controller.dispose);
        await controller.read();
        await controller.chooseArchive(
          () async => '/owned/previous-loader.zip',
        );
        client.current = _loader(
          id: contextChanged ? 'declared-loader' : 'other-loader',
          contextRevision: contextChanged ? 2 : 1,
          archiveRequired: false,
        );
        await controller.read();
        final enabling = controller.toggle();
        await Future<void>.delayed(Duration.zero);
        expect(client.acquisitions, 1);
        expect(client.archive, isNull);
        await client.stream!.close();
        await enabling;
      },
    );
  }

  test('an archive chooser from the old context cannot start the new loader acquisition', () async {
    final client = _Client();
    final controller = UnrealLoaderController(client, 'w', 'p', () {});
    addTearDown(controller.dispose);
    await controller.read();
    await controller.toggle();
    final selection = Completer<String?>();
    final choosing = controller.chooseArchive(() => selection.future);
    client.current = _loader(contextRevision: 2);
    await controller.read();
    selection.complete('/owned/previous-loader.zip');
    await choosing;
    expect(client.acquisitions, 0);
    expect(controller.archive, isNull);
    expect(controller.needsArchive, false);
  });

  test('an applicable archive survives unrelated profile updates and reaches its loader acquisition', () async {
    final client = _Client();
    final controller = UnrealLoaderController(client, 'w', 'p', () {});
    addTearDown(controller.dispose);
    await controller.read();
    await controller.chooseArchive(() async => '/owned/current-loader.zip');
    client.current = _loader(selectionRevision: 2);
    await controller.read();
    final enabling = controller.toggle();
    await Future<void>.delayed(Duration.zero);
    expect(client.acquisitions, 1);
    expect(client.archive, '/owned/current-loader.zip');
    await client.stream!.close();
    await enabling;
  });

  test('archive selection starts acquisition only after the pending toggle and reconciles queued changes', () async {
    final client = _Client();
    var changes = 0;
    final controller = UnrealLoaderController(client, 'w', 'p', () {
      changes++;
    });
    await controller.read();
    await controller.toggle();
    expect(client.acquisitions, 0);
    expect(controller.needsArchive, true);
    final choosing = controller.chooseArchive(
      () async => '/owned/another-loader.zip',
    );
    await Future<void>.delayed(Duration.zero);
    expect(client.archive, '/owned/another-loader.zip');
    await controller.read();
    expect(client.reads, 1);
    client.stream!.add(
      UnrealProgress('complete', 1, 1, 'loader-mod', null, client.current),
    );
    await client.stream!.close();
    await choosing;
    await Future<void>.delayed(Duration.zero);
    expect(changes, 1);
    expect(client.reads, 2);
    expect(controller.needsArchive, false);
    controller.dispose();
  });

  test('profile teardown cancels only its active acquisition and completes pending UI work', () async {
    final client = _Client();
    final controller = UnrealLoaderController(client, 'w', 'p', () {});
    await controller.read();
    await controller.toggle();
    final choosing = controller.chooseArchive(() async => '/owned/loader.zip');
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    await choosing;
    expect(client.cancelled, true);
    expect(client.acquisitions, 1);
  });
}
