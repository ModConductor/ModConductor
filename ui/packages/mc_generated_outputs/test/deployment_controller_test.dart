import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_generated_outputs/src/deployment_controller.dart';

class Deployments implements DeploymentsClient {
  final events = StreamController<DeploymentEvent>();
  final reads = <String>[];
  final removals = <(String, String)>[];
  @override
  Future<DeploymentState> read(String profileId) async {
    reads.add(profileId);
    return DeploymentState(
      'workspace',
      1,
      SavedDeployment(
        'generation',
        DateTime.utc(2026),
        DeploymentProfile(profileId, profileId, 1, 1),
        true,
        true,
        'fingerprint',
        true,
      ),
      null,
      'sources',
    );
  }

  @override
  Stream<DeploymentEvent> deactivate(String profileId, String generationId) {
    removals.add((profileId, generationId));
    return events.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'deactivation publishes the final state through events without preparation',
    () async {
      final api = Deployments();
      final controller = DeploymentController();
      addTearDown(controller.dispose);
      controller.attach(api, 'profile', 'Profile', available: true);
      await Future<void>.delayed(Duration.zero);
      var changes = 0;
      controller.onChanged = () => changes++;
      final done = controller.deactivate();
      expect(controller.busy, isTrue);
      expect(controller.preparing, isFalse);
      api.events.add(
        const DeploymentDeactivated(
          DeploymentState('workspace', 2, null, null, 'sources'),
        ),
      );
      await api.events.close();
      await done;
      expect(api.removals, [('profile', 'generation')]);
      expect(controller.state?.active, isNull);
      expect(controller.receipt, isNull);
      expect(controller.busy, isFalse);
      expect(controller.needsRead, isFalse);
      expect(changes, 1);
      expect(api.reads, ['profile']);
    },
  );

  test(
    'an old deactivation reply cannot overwrite a newly selected profile',
    () async {
      final api = Deployments();
      final controller = DeploymentController();
      addTearDown(controller.dispose);
      controller.attach(api, 'first', 'First', available: true);
      await Future<void>.delayed(Duration.zero);
      final done = controller.deactivate();
      controller.attach(api, 'second', 'Second', available: true);
      api.events.add(
        const DeploymentDeactivated(
          DeploymentState('workspace', 2, null, null, 'sources'),
        ),
      );
      await api.events.close();
      await done;
      await Future<void>.delayed(Duration.zero);
      expect(controller.profileId, 'second');
      expect(controller.state?.active?.profile?.id, 'second');
      expect(controller.busy, isFalse);
    },
  );
}
