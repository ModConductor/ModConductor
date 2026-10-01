import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_thunderstore/mc_thunderstore.dart';

import 'support.dart';

void main() {
  const second = ThunderstorePreview(bep, '', null, false, []);
  const third = ThunderstorePreview(
    ThunderstorePackageRef('valheim', 'Fixture', 'C'),
    '',
    null,
    false,
    [],
  );
  test('a fresh sort replaces provider ranking and keeps selection', () async {
    var requests = 0;
    final client = Client()
      ..searchReply = (_) async => ThunderstoreValue(
        ThunderstorePage(
          ++requests == 1 ? [row, second] : [second, row],
          2,
          null,
        ),
      );
    final controller = ThunderstoreController(client, 'workspace');
    addTearDown(controller.dispose);
    await controller.search();
    await controller.inspect(jotunn);
    expect(controller.model.visible, [jotunn.key, bep.key]);
    controller.changeOrdering('newest');
    await Future<void>.delayed(Duration.zero);
    expect(controller.model.visible, [bep.key, jotunn.key]);
    expect(controller.model.selectedId, jotunn.key);
  });
  test('additional pages append provider order without duplicates', () async {
    const updated = ThunderstorePreview(bep, 'Updated', null, false, []);
    var requests = 0;
    final client = Client()
      ..searchReply = (_) async => ThunderstoreValue(
        ++requests == 1
            ? const ThunderstorePage([row, second], 3, 2)
            : const ThunderstorePage([updated, third, third], 3, null),
      );
    final controller = ThunderstoreController(client, 'workspace');
    addTearDown(controller.dispose);
    await controller.search();
    await controller.search(more: true);
    expect(controller.model.visible, [jotunn.key, bep.key, third.package.key]);
    expect(controller.model[bep.key]!.description, updated.description);
    expect(controller.next, isNull);
    expect(client.searches.map((request) => request.$3), [1, 2]);
  });
  test('late searches cannot replace a newer query', () async {
    final first = Completer<ThunderstoreReply<ThunderstorePage>>();
    final client = Client()
      ..searchReply = (query) => query == 'old'
          ? first.future
          : Future.value(const ThunderstoreValue(page));
    final controller = ThunderstoreController(client, 'workspace')
      ..query = 'old';
    addTearDown(controller.dispose);
    final pending = controller.search();
    controller.query = 'new';
    await controller.search();
    first.complete(const ThunderstoreValue(ThunderstorePage([], 0, null)));
    await pending;
    expect(controller.model.length, 1);
    expect(client.searches.map((row) => row.$1), ['old', 'new']);
  });
  test(
    'an unavailable exact version cannot acquire previously displayed version',
    () async {
      final client = Client();
      final controller = ThunderstoreController(client, 'workspace');
      addTearDown(controller.dispose);
      await controller.inspect(jotunn);
      client.packageReply = (_) async =>
          const ThunderstoreRefusal(ThunderstoreProblem('Removed version'));
      await controller.inspect(jotunn, version: '2.30.1');
      controller.add();
      expect(controller.canAdd, isFalse);
      expect(client.acquired, isEmpty);
      expect(controller.details, isNull);
    },
  );
  test(
    'unavailable dependency prevents acquisition before starting transfer',
    () async {
      final client = Client()
        ..packageReply = (_) async => ThunderstoreValue(info(available: false));
      final controller = ThunderstoreController(client, 'workspace');
      addTearDown(controller.dispose);
      await controller.inspect(jotunn);
      controller.add();
      expect(client.acquired, isEmpty);
    },
  );
  test(
    'completed stream refreshes library state once without polling',
    () async {
      final client = Client();
      final controller = ThunderstoreController(client, 'workspace');
      addTearDown(controller.dispose);
      await controller.inspect(jotunn, version: '2.30.1');
      controller.add();
      expect(client.acquired.single.version, '2.30.1');
      client.installed = true;
      client.stream!.add(
        const ThunderstoreProgress(
          reference: selected,
          stage: 'complete',
          bytes: 0,
          completed: 2,
          packages: 2,
        ),
      );
      await client.stream!.close();
      await Future<void>.delayed(Duration.zero);
      expect(controller.running, isFalse);
      expect(client.reads, ['2.30.1', '2.30.1']);
      expect(controller.details!.installed.single.reference.version, '2.30.2');
    },
  );
}
