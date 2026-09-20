import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/skyrim_setup.pbgrpc.dart' as wire;

enum SkyrimSetupStatusPhase {
  unavailable,
  needsConsent,
  preparingDeployment,
  settingUpSkse,
  waitingForSkse,
  waitingForEnbArchive,
  settingUpEnb,
  settingUpFnis,
  fnisStale,
  fnisRunning,
  ready,
  recoveryRequired,
  failed,
}

class SkyrimSetupChange {
  const SkyrimSetupChange(this.title, this.detail);
  final String title, detail;
}

class SkyrimSetupComponent {
  const SkyrimSetupComponent({
    required this.name,
    required this.status,
    required this.detail,
    required this.ready,
    required this.active,
    required this.blocked,
  });
  final String name, status, detail;
  final bool ready, active, blocked;
}

class SkyrimSetupStatus {
  const SkyrimSetupStatus({
    required this.phase,
    required this.status,
    required this.detail,
    required this.planToken,
    required this.changes,
    required this.components,
    required this.includeFnis,
    required this.consentRecorded,
    required this.canStart,
    required this.canContinue,
    required this.canSelectEnbArchive,
    required this.active,
    required this.ready,
  });

  final SkyrimSetupStatusPhase phase;
  final String status, detail, planToken;
  final List<SkyrimSetupChange> changes;
  final List<SkyrimSetupComponent> components;
  final bool includeFnis,
      consentRecorded,
      canStart,
      canContinue,
      canSelectEnbArchive,
      active,
      ready;
}

abstract class SkyrimSetupClient {
  SkyrimSetupClient();

  factory SkyrimSetupClient.grpc(ClientChannel channel, CallOptions options) =
      _GrpcSkyrimSetupClient;

  Future<SkyrimSetupStatus> read(
    String workspace,
    String profile, {
    required bool includeFnis,
  });

  Future<SkyrimSetupStatus> start(
    String workspace,
    String profile, {
    required bool includeFnis,
    required String planToken,
  });

  Future<SkyrimSetupStatus> continueSetup(String workspace, String profile);

  Future<SkyrimSetupStatus> selectEnbArchive(
    String workspace,
    String profile,
    String operationId,
    String path,
  );
}

class _GrpcSkyrimSetupClient extends SkyrimSetupClient {
  _GrpcSkyrimSetupClient(ClientChannel channel, CallOptions options)
    : _client = wire.SkyrimSetupOperationsClient(channel, options: options);

  final wire.SkyrimSetupOperationsClient _client;

  SkyrimSetupStatus _decode(wire.SkyrimSetupState value) => SkyrimSetupStatus(
    phase: switch (value.phase) {
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_NEEDS_CONSENT =>
        SkyrimSetupStatusPhase.needsConsent,
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_PREPARING_DEPLOYMENT =>
        SkyrimSetupStatusPhase.preparingDeployment,
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_SETTING_UP_SKSE =>
        SkyrimSetupStatusPhase.settingUpSkse,
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_WAITING_FOR_SKSE =>
        SkyrimSetupStatusPhase.waitingForSkse,
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_WAITING_FOR_ENB_ARCHIVE =>
        SkyrimSetupStatusPhase.waitingForEnbArchive,
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_SETTING_UP_ENB =>
        SkyrimSetupStatusPhase.settingUpEnb,
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_SETTING_UP_FNIS =>
        SkyrimSetupStatusPhase.settingUpFnis,
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_FNIS_STALE =>
        SkyrimSetupStatusPhase.fnisStale,
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_FNIS_RUNNING =>
        SkyrimSetupStatusPhase.fnisRunning,
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_READY =>
        SkyrimSetupStatusPhase.ready,
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_RECOVERY_REQUIRED =>
        SkyrimSetupStatusPhase.recoveryRequired,
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_FAILED =>
        SkyrimSetupStatusPhase.failed,
      _ => SkyrimSetupStatusPhase.unavailable,
    },
    status: value.status,
    detail: value.detail,
    planToken: value.planToken,
    changes: List.unmodifiable(
      value.changes.map((item) => SkyrimSetupChange(item.title, item.detail)),
    ),
    components: List.unmodifiable(
      value.components.map(
        (item) => SkyrimSetupComponent(
          name: item.name,
          status: item.status,
          detail: item.detail,
          ready: item.ready,
          active: item.active,
          blocked: item.blocked,
        ),
      ),
    ),
    includeFnis: value.includeFnis,
    consentRecorded: value.consentRecorded,
    canStart: value.canStart,
    canContinue: value.canContinue,
    canSelectEnbArchive: value.canSelectEnbArchive,
    active: value.active,
    ready: value.ready,
  );

  @override
  Future<SkyrimSetupStatus> read(
    String workspace,
    String profile, {
    required bool includeFnis,
  }) async => _decode(
    await _client.readSkyrimSetup(
      wire.ReadSkyrimSetupRequest(
        workspaceId: workspace,
        profileId: profile,
        includeFnis: includeFnis,
      ),
    ),
  );

  @override
  Future<SkyrimSetupStatus> start(
    String workspace,
    String profile, {
    required bool includeFnis,
    required String planToken,
  }) async => _decode(
    await _client.startSkyrimSetup(
      wire.StartSkyrimSetupRequest(
        workspaceId: workspace,
        profileId: profile,
        includeFnis: includeFnis,
        planToken: planToken,
        changePlanConfirmed: true,
      ),
    ),
  );

  @override
  Future<SkyrimSetupStatus> continueSetup(
    String workspace,
    String profile,
  ) async => _decode(
    await _client.continueSkyrimSetup(
      wire.SkyrimSetupRequest(workspaceId: workspace, profileId: profile),
    ),
  );

  @override
  Future<SkyrimSetupStatus> selectEnbArchive(
    String workspace,
    String profile,
    String operationId,
    String path,
  ) async => _decode(
    await _client.selectSkyrimSetupEnbArchive(
      wire.SkyrimSetupArchiveRequest(
        workspaceId: workspace,
        profileId: profile,
        operationId: operationId,
        path: path,
      ),
    ),
  );
}
