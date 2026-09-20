import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/enb.pbgrpc.dart' as wire;

enum EnbStatusPhase {
  unavailable,
  blocked,
  available,
  waiting,
  validating,
  acquiring,
  installing,
  ready,
  failed,
  conflict,
}

class EnbStatus {
  const EnbStatus({
    required this.phase,
    required this.status,
    required this.detail,
    required this.runtimeVersion,
    required this.presetVersion,
    required this.canOpenAuthorPage,
    required this.canSelectArchive,
    required this.canCancel,
  });
  final EnbStatusPhase phase;
  final String status, detail, runtimeVersion, presetVersion;
  final bool canOpenAuthorPage, canSelectArchive, canCancel;
  bool get active =>
      phase == EnbStatusPhase.validating ||
      phase == EnbStatusPhase.acquiring ||
      phase == EnbStatusPhase.installing;
}

class EnbClient {
  EnbClient(ClientChannel channel, CallOptions options)
    : _client = wire.EnbOperationsClient(channel, options: options);
  final wire.EnbOperationsClient _client;

  EnbStatus _decode(wire.EnbState value) => EnbStatus(
    phase: switch (value.phase) {
      wire.EnbPhase.ENB_PHASE_BLOCKED => EnbStatusPhase.blocked,
      wire.EnbPhase.ENB_PHASE_AVAILABLE => EnbStatusPhase.available,
      wire.EnbPhase.ENB_PHASE_WAITING_FOR_ARCHIVE => EnbStatusPhase.waiting,
      wire.EnbPhase.ENB_PHASE_VALIDATING => EnbStatusPhase.validating,
      wire.EnbPhase.ENB_PHASE_ACQUIRING => EnbStatusPhase.acquiring,
      wire.EnbPhase.ENB_PHASE_INSTALLING => EnbStatusPhase.installing,
      wire.EnbPhase.ENB_PHASE_READY => EnbStatusPhase.ready,
      wire.EnbPhase.ENB_PHASE_FAILED => EnbStatusPhase.failed,
      wire.EnbPhase.ENB_PHASE_CONFLICT => EnbStatusPhase.conflict,
      _ => EnbStatusPhase.unavailable,
    },
    status: value.status,
    detail: value.detail,
    runtimeVersion: value.runtimeVersion,
    presetVersion: value.presetVersion,
    canOpenAuthorPage: value.canOpenAuthorPage,
    canSelectArchive: value.canSelectArchive,
    canCancel: value.canCancel,
  );

  wire.EnbRequest _request(String workspace, String profile) =>
      wire.EnbRequest(workspaceId: workspace, profileId: profile);

  Future<EnbStatus> read(String workspace, String profile) async =>
      _decode(await _client.readEnb(_request(workspace, profile)));

  Future<EnbStatus> openAuthorPage(String workspace, String profile) async =>
      _decode(await _client.openEnbAuthorPage(_request(workspace, profile)));

  Future<EnbStatus> cancel(String workspace, String profile) async =>
      _decode(await _client.cancelEnbWait(_request(workspace, profile)));

  Future<EnbStatus> selectArchive(
    String workspace,
    String profile,
    String operation,
    String path,
  ) async => _decode(
    await _client.selectEnbArchive(
      wire.EnbArchiveRequest(
        workspaceId: workspace,
        profileId: profile,
        operationId: operation,
        path: path,
      ),
    ),
  );
}
