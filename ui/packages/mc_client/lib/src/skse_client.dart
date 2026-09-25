import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/skse.pbgrpc.dart' as wire;

enum SkseStatusPhase {
  unavailable,
  available,
  waiting,
  downloading,
  installing,
  ready,
  failed,
  updateAvailable,
  incompatible,
  sourceUnavailable,
}

class SkseStatus {
  const SkseStatus(
    this.phase,
    this.gameVersion,
    this.componentVersion,
    this.status,
    this.detail,
  );
  final SkseStatusPhase phase;
  final String gameVersion, componentVersion, status, detail;
  bool get active =>
      phase == SkseStatusPhase.downloading ||
      phase == SkseStatusPhase.installing;
}

class SkseClient {
  SkseClient(ClientChannel channel, CallOptions options)
    : _client = wire.SkseOperationsClient(channel, options: options);
  final wire.SkseOperationsClient _client;

  SkseStatus _decode(wire.SkseState value) => SkseStatus(
    switch (value.phase) {
      wire.SksePhase.SKSE_PHASE_AVAILABLE => SkseStatusPhase.available,
      wire.SksePhase.SKSE_PHASE_WAITING_FOR_NEXUS => SkseStatusPhase.waiting,
      wire.SksePhase.SKSE_PHASE_DOWNLOADING => SkseStatusPhase.downloading,
      wire.SksePhase.SKSE_PHASE_INSTALLING => SkseStatusPhase.installing,
      wire.SksePhase.SKSE_PHASE_READY => SkseStatusPhase.ready,
      wire.SksePhase.SKSE_PHASE_FAILED => SkseStatusPhase.failed,
      wire.SksePhase.SKSE_PHASE_UPDATE_AVAILABLE =>
        SkseStatusPhase.updateAvailable,
      wire.SksePhase.SKSE_PHASE_INCOMPATIBLE => SkseStatusPhase.incompatible,
      wire.SksePhase.SKSE_PHASE_SOURCE_UNAVAILABLE =>
        SkseStatusPhase.sourceUnavailable,
      _ => SkseStatusPhase.unavailable,
    },
    value.gameVersion,
    value.componentVersion,
    value.status,
    value.detail,
  );

  Future<SkseStatus> read(String workspace, String profile) async => _decode(
    await _client.readSkse(
      wire.SkseRequest(workspaceId: workspace, profileId: profile),
    ),
  );
  Future<SkseStatus> start(String workspace, String profile) async => _decode(
    await _client.startSkse(
      wire.SkseRequest(workspaceId: workspace, profileId: profile),
    ),
  );

  Future<SkseStatus> checkUpdate(String workspace, String profile) async =>
      _decode(
        await _client.checkSkseUpdate(
          wire.SkseRequest(workspaceId: workspace, profileId: profile),
        ),
      );
}
