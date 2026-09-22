import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/src/deletion_controller.dart';

import 'controller_test.dart';

class _MaintenanceClient extends Fake implements MaintenanceClient {
  _MaintenanceClient(this.preview);

  final DeletionPreview preview;
  int deletions = 0;
  bool fail = false;

  @override
  Future<DeletionPreview> prepareDeletion(ModEntry target) async => preview;

  @override
  Future<void> deleteMod(DeletionPreview value) async {
    deletions++;
    expect(identical(value, preview), isTrue);
    if (fail) throw const ArtifactProblem('Deletion failed.');
  }
}

void main() {
  test(
    'direct deletion reports local failure and retries the current preview',
    () async {
      const preview = DeletionPreview(
        workspaceId: 'workspace',
        modId: 'mod',
        revision: 4,
        name: 'Mod',
        versions: 1,
        backups: [],
        profiles: [],
        deployments: [],
        files: [],
        external: [],
      );
      final client = _MaintenanceClient(preview)..fail = true;
      var changes = 0;
      final controller = DeletionController(() async => changes++);
      addTearDown(controller.dispose);
      controller.attach(client, 'workspace');

      await controller.open(mod('mod', revision: 4));
      await controller.run();

      expect(controller.complete, isFalse);
      expect(controller.problem, 'Deletion failed.');
      expect(changes, 0);

      client.fail = false;
      await controller.run();

      expect(client.deletions, 2);
      expect(controller.complete, isTrue);
      expect(controller.problem, isNull);
      expect(changes, 1);
    },
  );
}
