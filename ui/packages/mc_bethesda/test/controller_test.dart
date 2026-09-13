import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_bethesda/mc_bethesda.dart';
import 'package:mc_client/mc_client.dart';

class PendingScan implements BethesdaClient {
  Completer<PluginSnapshot> pending = Completer<PluginSnapshot>();
  @override
  Future<PluginSnapshot> scan(String profile) => pending.future;
  @override
  Future<PluginSnapshot> read(String snapshot) => pending.future;
}

void main() {
  test('an input change survives a late scan response until an explicit fresh scan', () async {
    final client = PendingScan(), controller = PluginsController();
    controller.attach(client, 'profile');
    final first = controller.scan();
    controller.invalidate();
    client.pending.complete(
      PluginSnapshot(
        'first',
        'workspace',
        'profile',
        DateTime.utc(2026),
        false,
        const [],
        const [],
      ),
    );
    await first;
    expect(controller.stale, isTrue);
    client.pending = Completer<PluginSnapshot>();
    final second = controller.scan();
    client.pending.complete(
      PluginSnapshot(
        'second',
        'workspace',
        'profile',
        DateTime.utc(2026),
        false,
        const [],
        const [],
      ),
    );
    await second;
    expect(controller.stale, isFalse);
    controller.dispose();
  });
}
