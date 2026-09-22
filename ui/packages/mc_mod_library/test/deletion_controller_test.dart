import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/src/deletion_controller.dart';

import 'controller_test.dart';

class _MaintenanceClient extends Fake implements MaintenanceClient {
  int deletions = 0;
  bool fail = false;
  Completer<void>? pending;
  ModEntry? deleted;

  @override
  Future<void> deleteMod(ModEntry target) async {
    deletions++;
    deleted = target;
    await pending?.future;
    if (fail) throw const ArtifactProblem('Deletion failed.');
  }
}

void main() {
  test(
    'direct deletion reports a specific failure and retries the same mod',
    () async {
      final client = _MaintenanceClient()..fail = true;
      final target = mod('mod', revision: 4);
      var changes = 0;
      final controller = DeletionController(() async => changes++);
      addTearDown(controller.dispose);
      controller.attach(client, 'workspace');

      await controller.open(target);

      expect(controller.complete, isFalse);
      expect(controller.problem, 'Deletion failed.');
      expect(controller.target, same(target));
      expect(changes, 0);

      client.fail = false;
      await controller.run();

      expect(client.deletions, 2);
      expect(client.deleted, same(target));
      expect(controller.complete, isTrue);
      expect(controller.problem, isNull);
      expect(changes, 1);
    },
  );

  test('deletion stays foreground and cannot go back while pending', () async {
    final client = _MaintenanceClient()..pending = Completer<void>();
    final target = mod('mod', revision: 4);
    final controller = DeletionController(() async {});
    addTearDown(controller.dispose);
    controller.attach(client, 'workspace');

    final deletion = controller.open(target);
    await settle();

    expect(controller.viewing, isTrue);
    expect(controller.busy, isTrue);
    expect(controller.target, same(target));
    controller.back();
    expect(controller.viewing, isTrue);
    expect(controller.busy, isTrue);

    client.pending!.complete();
    await deletion;
    expect(controller.complete, isTrue);

    controller.back();
    expect(controller.viewing, isFalse);
    expect(controller.target, isNull);
  });

  test('a failed direct deletion can return to the mod', () async {
    final client = _MaintenanceClient()
      ..fail = true
      ..pending = Completer<void>();
    final controller = DeletionController(() async {});
    addTearDown(controller.dispose);
    controller.attach(client, 'workspace');

    final deletion = controller.open(mod('mod', revision: 4));
    await settle();
    controller.back();
    expect(controller.viewing, isTrue);

    client.pending!.complete();
    await deletion;
    expect(controller.problem, 'Deletion failed.');

    controller.back();
    expect(controller.viewing, isFalse);
    expect(controller.target, isNull);
  });
}
