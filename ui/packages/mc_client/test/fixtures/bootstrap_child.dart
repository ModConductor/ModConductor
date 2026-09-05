import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mc_client/src/generated/modconductor/v2/engine_probe.pb.dart';

// A pipe relay for native fault injection. Session bytes never enter its output.
Future<void> main(List<String> args) async {
  final engine = await Process.start(args[0], ['--state-directory', args[2]]);
  final mode = args[1];
  engine.stderr.listen((_) {});
  stdin.listen(
    engine.stdin.add,
    onDone: () async {
      if (mode == 'slow-stop') {
        await Future<void>.delayed(const Duration(seconds: 5));
      }
      await engine.stdin.close();
    },
  );
  final line = await engine.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .first;
  final ready = EngineReady.fromBuffer(base64.decode(line));
  if (mode == 'delay') await Future<void>.delayed(const Duration(seconds: 2));
  if (mode == 'delay-long') {
    await Future<void>.delayed(const Duration(seconds: 12));
  }
  if (mode == 'version') ready.protocolMajor = 3;
  if (mode == 'oversized') {
    stdout.writeln('A' * 4097);
  } else {
    stdout.writeln(base64.encode(ready.writeToBuffer()));
  }
  await stdout.flush();
  exitCode = await engine.exitCode;
}
