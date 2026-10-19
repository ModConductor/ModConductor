import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final executable = Platform.environment['MC_NATIVE_FIXTURE'];

  test(
    'archive arrival chronology crosses client pages and restart without losing newer additions',
    () async {
      final area = await Directory.systemTemp.createTemp('mc-artifact-order-');
      final state = await Directory('${area.path}/state').create();
      final root = await Directory('${area.path}/workspace').create();
      final original = await File('${area.path}/original.zip')
          .writeAsString('fixture');
      final children = <NativeChild>[];
      Future<NativeChild> start() async {
        final child = await NativeChild.startWithArguments(executable!, [
          '--nexus-engine',
          state.path,
          '${area.path}/provider',
        ]);
        children.add(child);
        return child;
      }

      try {
        var child = await start();
        final workspace = newOperationId();
        await child.workspaces().create(workspace, 'Chronology', root.path);
        var client = child.artifacts();
        final added = <Artifact>[];
        for (var i = 0; i < 66; i++) {
          added.add(
            await client.add(
              workspace,
              newOperationId(),
              original.path,
              ArtifactStorage.reference,
            ),
          );
        }
        final first = await client.list(workspace);
        expect(
          first.entries.map((artifact) => artifact.id),
          added.reversed.take(64).map((artifact) => artifact.id),
        );
        expect(
          first.entries.map((artifact) => artifact.arrivalOrder),
          orderedEquals(
            added.reversed.take(64).map((artifact) => artifact.arrivalOrder),
          ),
        );
        expect(
          first.entries.first.arrivalOrder,
          greaterThan(added.first.arrivalOrder),
        );
        final latest = await client.add(
          workspace,
          newOperationId(),
          original.path,
          ArtifactStorage.reference,
        );
        final rest = await client.list(workspace, after: first.next);
        expect(
          rest.entries.map((artifact) => artifact.id),
          added.take(2).toList().reversed.map((artifact) => artifact.id),
        );
        expect(rest.next, isNull);
        await child.close();
        child = await start();
        client = child.artifacts();
        final refreshed = await client.list(workspace, refresh: true);
        expect(refreshed.entries.map((artifact) => artifact.id), [
          latest.id,
          ...added.reversed.take(63).map((artifact) => artifact.id),
        ]);
        expect(refreshed.entries.first.arrivalOrder, latest.arrivalOrder);
      } finally {
        for (final child in children) {
          await child.close();
        }
        await area.delete(recursive: true);
      }
    },
    skip: executable == null
        ? 'Set MC_NATIVE_FIXTURE to the published native fixture.'
        : false,
  );
}
