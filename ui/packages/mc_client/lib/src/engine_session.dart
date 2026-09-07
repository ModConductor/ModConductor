import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/bootstrap.pb.dart' as wire;
import 'operations_client.dart';
import 'workspaces_client.dart';
import 'mod_library_client.dart';
import 'profile_mod_client.dart';
import 'mod_organization_client.dart';
import 'game_context_client.dart';

class EngineSession {
  EngineSession(this._process) : _errors = _process.stderr.listen((_) {});

  final Process _process;
  final StreamSubscription<List<int>> _errors;
  ClientChannel? _channel;
  OperationsClient? _operations;
  OperationsClient get operations => _operations!;
  GameContextsClient? _gameContexts;
  GameContextsClient get gameContexts => _gameContexts!;
  ModOrganizationClient? _modOrganization;
  ModOrganizationClient get modOrganization => _modOrganization!;
  ProfileModsClient? _profileMods;
  ProfileModsClient get profileMods => _profileMods!;
  ModLibraryClient? _modLibrary;
  ModLibraryClient get modLibrary => _modLibrary!;
  WorkspacesClient? _workspaces;
  WorkspacesClient get workspaces => _workspaces!;
  Future<void>? _closing;

  Future<int> get exited => _process.exitCode;

  Future<void> connect() async {
    final random = Random.secure();
    final capability = List.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    _process.stdin.writeln(capability);
    await _process.stdin.flush();
    final ready = await _readReady(_process.stdout)
        .timeout(const Duration(seconds: 10));
    if (ready.protocolMajor != 1) {
      throw const EngineProtocolMismatch();
    }
    if (ready.port < 1 || ready.port > 65535 || ready.certificatePem.isEmpty) {
      throw const FormatException('Invalid engine descriptor.');
    }
    final channel = ClientChannel(
      '127.0.0.1',
      port: ready.port,
      options: ChannelOptions(
        credentials: ChannelCredentials.secure(
          certificates: ready.certificatePem,
          authority: 'localhost',
        ),
        connectTimeout: const Duration(seconds: 2),
      ),
    );
    _channel = channel;
    final options = CallOptions(
      timeout: const Duration(seconds: 5),
      metadata: {'mc-session': capability},
    );
    _operations = OperationsClient(channel, options);
    _workspaces = GrpcWorkspacesClient(channel, options);
    _modLibrary = ModLibraryClient(channel, options);
    _profileMods = ProfileModsClient(channel, options);
    _modOrganization = ModOrganizationClient(channel, options);
    _gameContexts = GrpcGameContextsClient(channel, options);
  }

  Future<ConnectionReport> check() => operations.check();

  Future<void> close() =>
      _closing ??= _close().whenComplete(() => _closing = null);

  Future<void> _close() async {
    await _channel?.terminate();
    try {
      await _process.stdin.close();
    } on IOException {
      // An exited child can close its pipe before the owner does.
    }
    await _process.exitCode.timeout(const Duration(seconds: 3));
    await _errors.cancel();
  }
}

class EngineProtocolMismatch implements Exception {
  const EngineProtocolMismatch();
}

Future<wire.EngineReady> _readReady(Stream<List<int>> output) async {
  final bytes = <int>[];
  await for (final chunk in output) {
    for (final byte in chunk) {
      if (byte == 10) {
        return wire.EngineReady.fromBuffer(
          base64.decode(ascii.decode(bytes).trim()),
        );
      }
      if (bytes.length == 4096) {
        throw const FormatException('Engine descriptor is too long.');
      }
      bytes.add(byte);
    }
  }
  throw const FormatException('The engine stopped before it was ready.');
}
