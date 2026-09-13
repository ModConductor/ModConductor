import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/credentials.pbgrpc.dart' as wire;

enum CredentialMode { secure, sessionOnly }

enum SavedCredentials { present, absent, unknown }

enum CredentialProblem {
  unavailable,
  locked,
  denied,
  timedOut,
  cancelled,
  tooLarge,
  failed,
}

class CredentialStatus {
  const CredentialStatus({
    required this.mode,
    required this.saved,
    required this.hasSession,
    required this.problem,
    required this.removalProblem,
    required this.diagnosticReport,
  });
  final CredentialMode mode;
  final SavedCredentials saved;
  final bool hasSession;
  final CredentialProblem? problem, removalProblem;
  final String diagnosticReport;
}

class CredentialConnectionProblem implements Exception {
  const CredentialConnectionProblem();
  @override
  String toString() =>
      'Sign-in storage could not be checked. Check the engine connection and try again.';
}

abstract interface class CredentialsClient {
  Future<CredentialStatus> status();
  Future<CredentialStatus> setMode(CredentialMode mode);
  Future<CredentialStatus> remove();
}

class GrpcCredentialsClient implements CredentialsClient {
  GrpcCredentialsClient(ClientChannel channel, CallOptions options)
    : _client = wire.CredentialStorageClient(channel, options: options);
  final wire.CredentialStorageClient _client;
  CredentialProblem? _problem(wire.CredentialStorageProblem value) =>
      switch (value) {
        wire.CredentialStorageProblem.CREDENTIAL_STORAGE_PROBLEM_NONE => null,
        wire.CredentialStorageProblem.CREDENTIAL_STORAGE_PROBLEM_UNAVAILABLE =>
          CredentialProblem.unavailable,
        wire.CredentialStorageProblem.CREDENTIAL_STORAGE_PROBLEM_LOCKED =>
          CredentialProblem.locked,
        wire.CredentialStorageProblem.CREDENTIAL_STORAGE_PROBLEM_DENIED =>
          CredentialProblem.denied,
        wire.CredentialStorageProblem.CREDENTIAL_STORAGE_PROBLEM_TIMED_OUT =>
          CredentialProblem.timedOut,
        wire.CredentialStorageProblem.CREDENTIAL_STORAGE_PROBLEM_CANCELLED =>
          CredentialProblem.cancelled,
        wire.CredentialStorageProblem.CREDENTIAL_STORAGE_PROBLEM_TOO_LARGE =>
          CredentialProblem.tooLarge,
        _ => CredentialProblem.failed,
      };
  Future<CredentialStatus> _call(
    Future<wire.CredentialStorageStatus> operation,
  ) async {
    try {
      final value = await operation;
      return CredentialStatus(
        mode: switch (value.mode) {
          wire.CredentialStorageMode.CREDENTIAL_STORAGE_MODE_SECURE =>
            CredentialMode.secure,
          wire.CredentialStorageMode.CREDENTIAL_STORAGE_MODE_SESSION_ONLY =>
            CredentialMode.sessionOnly,
          _ => throw const CredentialConnectionProblem(),
        },
        saved: switch (value.saved) {
          wire.CredentialPresence.CREDENTIAL_PRESENCE_PRESENT =>
            SavedCredentials.present,
          wire.CredentialPresence.CREDENTIAL_PRESENCE_ABSENT =>
            SavedCredentials.absent,
          _ => SavedCredentials.unknown,
        },
        hasSession: value.hasSession,
        problem: _problem(value.problem),
        removalProblem: _problem(value.removalProblem),
        diagnosticReport: value.diagnosticReport,
      );
    } catch (_) {
      // Transport exception text can contain request details; this consumer has no raw-error path.
      throw const CredentialConnectionProblem();
    }
  }

  @override
  Future<CredentialStatus> status() =>
      _call(_client.readCredentialStatus(wire.CredentialStatusRequest()));
  @override
  Future<CredentialStatus> setMode(CredentialMode mode) => _call(
    _client.setCredentialStorageMode(
      wire.CredentialModeRequest(
        mode: switch (mode) {
          CredentialMode.secure =>
            wire.CredentialStorageMode.CREDENTIAL_STORAGE_MODE_SECURE,
          CredentialMode.sessionOnly =>
            wire.CredentialStorageMode.CREDENTIAL_STORAGE_MODE_SESSION_ONLY,
        },
      ),
    ),
  );
  @override
  Future<CredentialStatus> remove() =>
      _call(_client.removeSavedCredentials(wire.CredentialStatusRequest()));
}
