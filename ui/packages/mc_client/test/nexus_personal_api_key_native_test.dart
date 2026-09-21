import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final fixture = Platform.environment['MC_NATIVE_FIXTURE'];
  final selectedRoot = Platform.environment['MC_NEXUS_OUTPUT'];

  test('authenticated local RPC submits a personal API key once without durable or diagnostic exposure', () async {
    if (fixture == null || selectedRoot == null) {
      fail('Select the native Nexus fixture and an owned output directory.');
    }

    final area = await Directory(selectedRoot).create(recursive: true);
    final state = await Directory('${area.path}/state').create();
    final provider = File('${area.path}/provider-origin');
    final child = await NativeChild.startWithArguments(fixture, [
      '--nexus-engine',
      state.path,
      provider.path,
    ]);
    const candidate = 'synthetic-personal-key';

    try {
      Object? rejected;
      try {
        await child.nexus(authenticate: false).submitPersonalApiKey(candidate);
      } catch (error) {
        rejected = error;
      }
      expect(rejected, isA<NexusProblem>());
      expect('$rejected', isNot(contains(candidate)));

      await child.credentials().setMode(CredentialMode.sessionOnly);
      final account = await child.nexus().submitPersonalApiKey(candidate);
      expect(account.name, 'Rowan');
      expect(account.premium, isTrue);
      expect(account.profileImage?.host, 'static.nexusmods.com');
      expect(account.problem, isNull);
      expect((await child.nexus().status()).name, 'Rowan');
    } finally {
      await child.close();
    }

    final durable = StringBuffer();
    await for (final entry in state.list(recursive: true)) {
      if (entry is File) {
        durable.write(
          utf8.decode(await entry.readAsBytes(), allowMalformed: true),
        );
      }
    }
    expect(durable.toString(), isNot(contains('synthetic-personal-key')));
  });
}
