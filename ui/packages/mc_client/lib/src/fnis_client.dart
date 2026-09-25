import 'package:grpc/grpc.dart';

import 'completed_events.dart';
import 'generated/modconductor/v1/fnis.pbgrpc.dart' as wire;

enum FnisStatusPhase {
  unavailable,
  available,
  waiting,
  downloading,
  installing,
  ready,
  failed,
  updateAvailable,
  recoveryRequired,
  sourceUnavailable,
}

enum FnisOutputStatusPhase {
  unavailable,
  missing,
  stale,
  current,
  running,
  failed,
  cancelled,
  abandoned,
}

class FnisStatus {
  const FnisStatus({
    required this.phase,
    required this.version,
    required this.status,
    required this.detail,
    required this.canInstall,
    required this.canCancel,
    required this.canUpdate,
    required this.canRemove,
    required this.canRecover,
    this.outputPhase = FnisOutputStatusPhase.unavailable,
    this.outputStatus = '',
    this.outputDetail = '',
    this.canRun = false,
    this.canCancelRun = false,
    this.runId,
    this.exitCode,
    this.standardOutput = '',
    this.standardError = '',
    this.runLog = '',
  });
  final FnisStatusPhase phase;
  final String version, status, detail;
  final bool canInstall, canCancel, canUpdate, canRemove, canRecover;
  final FnisOutputStatusPhase outputPhase;
  final String outputStatus,
      outputDetail,
      standardOutput,
      standardError,
      runLog;
  final bool canRun, canCancelRun;
  final String? runId;
  final int? exitCode;
  bool get active =>
      phase == FnisStatusPhase.downloading ||
      phase == FnisStatusPhase.installing ||
      outputPhase == FnisOutputStatusPhase.running;
}

class FnisClient {
  FnisClient(ClientChannel channel, CallOptions options)
    : _client = wire.FnisOperationsClient(channel, options: options);
  final wire.FnisOperationsClient _client;

  FnisStatus _decode(wire.FnisState value) => FnisStatus(
    phase: switch (value.phase) {
      wire.FnisPhase.FNIS_PHASE_AVAILABLE => FnisStatusPhase.available,
      wire.FnisPhase.FNIS_PHASE_WAITING_FOR_NEXUS => FnisStatusPhase.waiting,
      wire.FnisPhase.FNIS_PHASE_DOWNLOADING => FnisStatusPhase.downloading,
      wire.FnisPhase.FNIS_PHASE_INSTALLING => FnisStatusPhase.installing,
      wire.FnisPhase.FNIS_PHASE_READY => FnisStatusPhase.ready,
      wire.FnisPhase.FNIS_PHASE_FAILED => FnisStatusPhase.failed,
      wire.FnisPhase.FNIS_PHASE_UPDATE_AVAILABLE =>
        FnisStatusPhase.updateAvailable,
      wire.FnisPhase.FNIS_PHASE_RECOVERY_REQUIRED =>
        FnisStatusPhase.recoveryRequired,
      wire.FnisPhase.FNIS_PHASE_SOURCE_UNAVAILABLE =>
        FnisStatusPhase.sourceUnavailable,
      _ => FnisStatusPhase.unavailable,
    },
    version: value.version,
    status: value.status,
    detail: value.detail,
    canInstall: value.canInstall,
    canCancel: value.canCancel,
    canUpdate: value.canUpdate,
    canRemove: value.canRemove,
    canRecover: value.canRecover,
    outputPhase: switch (value.outputPhase) {
      wire.FnisOutputPhase.FNIS_OUTPUT_PHASE_MISSING =>
        FnisOutputStatusPhase.missing,
      wire.FnisOutputPhase.FNIS_OUTPUT_PHASE_STALE =>
        FnisOutputStatusPhase.stale,
      wire.FnisOutputPhase.FNIS_OUTPUT_PHASE_CURRENT =>
        FnisOutputStatusPhase.current,
      wire.FnisOutputPhase.FNIS_OUTPUT_PHASE_RUNNING =>
        FnisOutputStatusPhase.running,
      wire.FnisOutputPhase.FNIS_OUTPUT_PHASE_FAILED =>
        FnisOutputStatusPhase.failed,
      wire.FnisOutputPhase.FNIS_OUTPUT_PHASE_CANCELLED =>
        FnisOutputStatusPhase.cancelled,
      wire.FnisOutputPhase.FNIS_OUTPUT_PHASE_ABANDONED =>
        FnisOutputStatusPhase.abandoned,
      _ => FnisOutputStatusPhase.unavailable,
    },
    outputStatus: value.outputStatus,
    outputDetail: value.outputDetail,
    canRun: value.canRun,
    canCancelRun: value.canCancelRun,
    runId: value.hasRunId() ? value.runId : null,
    exitCode: value.hasExitCode() ? value.exitCode : null,
    standardOutput: value.standardOutput,
    standardError: value.standardError,
    runLog: value.runLog,
  );

  wire.FnisRequest _request(String workspace, String profile) =>
      wire.FnisRequest(workspaceId: workspace, profileId: profile);

  Future<FnisStatus> read(String workspace, String profile) async =>
      _decode(await _client.readFnis(_request(workspace, profile)));
  Future<FnisStatus> install(String workspace, String profile) async =>
      _decode(await _client.installFnis(_request(workspace, profile)));
  Future<FnisStatus> cancel(String workspace, String profile) async =>
      _decode(await _client.cancelFnis(_request(workspace, profile)));
  Future<FnisStatus> update(String workspace, String profile) async =>
      _decode(await _client.updateFnis(_request(workspace, profile)));
  Future<FnisStatus> remove(String workspace, String profile) async =>
      _decode(await _client.removeFnis(_request(workspace, profile)));
  Future<FnisStatus> recover(String workspace, String profile) async =>
      _decode(await _client.recoverFnis(_request(workspace, profile)));
  Future<FnisStatus> run(String workspace, String profile, String id) async =>
      _decode(
        await _client.runFnis(
          wire.FnisRunRequest(
            id: id,
            workspaceId: workspace,
            profileId: profile,
          ),
        ),
      );
  Stream<FnisStatus> observeRun(String workspace, String profile, String id) =>
      completedEvents(
        _client.observeFnisRun(
          wire.FnisRunRequest(
            id: id,
            workspaceId: workspace,
            profileId: profile,
          ),
        ),
        (event) =>
            event.outputPhase != wire.FnisOutputPhase.FNIS_OUTPUT_PHASE_RUNNING,
        _decode,
      );
  Future<FnisStatus> cancelRun(String workspace, String profile) async =>
      _decode(await _client.cancelFnisRun(_request(workspace, profile)));
}
