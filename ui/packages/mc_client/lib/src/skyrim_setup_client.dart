import 'package:grpc/grpc.dart';
import 'package:fixnum/fixnum.dart';

import 'generated/modconductor/v1/skyrim_setup.pbgrpc.dart' as wire;

enum SkyrimSetupStatusPhase {
  unavailable,
  available,
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
  cancelled,
}

enum SkyrimSetupAction { unchanged, install, remove, update }

class SkseReleaseChoice {
  const SkseReleaseChoice({
    required this.fileId,
    required this.componentVersion,
    required this.gameVersion,
    required this.gameSha256,
    required this.allowIncompatible,
  });

  final int fileId;
  final String componentVersion, gameVersion, gameSha256;
  final bool allowIncompatible;
}

class SkseReleaseReview {
  const SkseReleaseReview({
    required this.compatible,
    required this.gameVersion,
    required this.gameSha256,
    required this.fileId,
    required this.componentVersion,
    required this.supportedRuntime,
    required this.problem,
  });

  final bool compatible;
  final String gameVersion, gameSha256, componentVersion;
  final String? supportedRuntime, problem;
  final int fileId;

  SkseReleaseChoice get choice => SkseReleaseChoice(
    fileId: fileId,
    componentVersion: componentVersion,
    gameVersion: gameVersion,
    gameSha256: gameSha256,
    allowIncompatible: !compatible,
  );
}

class SkyrimSetupSelection {
  const SkyrimSetupSelection({
    this.skse = SkyrimSetupAction.unchanged,
    this.enb = SkyrimSetupAction.unchanged,
    this.fnis = SkyrimSetupAction.unchanged,
    this.enbArchivePath,
  });

  final SkyrimSetupAction skse, enb, fnis;
  final String? enbArchivePath;

  bool get hasChange =>
      skse != SkyrimSetupAction.unchanged ||
      enb != SkyrimSetupAction.unchanged ||
      fnis != SkyrimSetupAction.unchanged;

  bool get needsEnbArchive =>
      enb == SkyrimSetupAction.install || enb == SkyrimSetupAction.update;

  bool get canApply =>
      hasChange && (!needsEnbArchive || enbArchivePath?.isNotEmpty == true);

  SkyrimSetupSelection withAction(String id, SkyrimSetupAction action) =>
      SkyrimSetupSelection(
        skse: id == 'skse' ? action : skse,
        enb: id == 'enb' ? action : enb,
        fnis: id == 'fnis' ? action : fnis,
        enbArchivePath: enbArchivePath,
      );

  SkyrimSetupSelection withEnbArchive(String? path) => SkyrimSetupSelection(
    skse: skse,
    enb: enb,
    fnis: fnis,
    enbArchivePath: path,
  );
}

class SkyrimSetupComponent {
  const SkyrimSetupComponent({
    required this.id,
    required this.name,
    required this.status,
    required this.detail,
    required this.ready,
    required this.active,
    required this.blocked,
    required this.installed,
    this.updateVersion,
  });
  final String id, name, status, detail;
  final String? updateVersion;
  final bool ready, active, blocked, installed;
}

class SkyrimSetupStatus {
  const SkyrimSetupStatus({
    required this.phase,
    required this.status,
    required this.detail,
    required this.components,
    required this.selection,
    required this.canStart,
    required this.canContinue,
    required this.active,
    required this.ready,
    required this.canCancel,
  });

  final SkyrimSetupStatusPhase phase;
  final String status, detail;
  final List<SkyrimSetupComponent> components;
  final SkyrimSetupSelection selection;
  final bool canStart, canContinue, active, ready, canCancel;
}

abstract class SkyrimSetupClient {
  SkyrimSetupClient();

  factory SkyrimSetupClient.grpc(ClientChannel channel, CallOptions options) =
      _GrpcSkyrimSetupClient;

  Future<SkyrimSetupStatus> read(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
  });

  Stream<SkyrimSetupStatus> watch(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
  });

  Future<SkyrimSetupStatus> start(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
    SkseReleaseChoice? skseChoice,
  });

  Future<SkseReleaseReview> reviewSkseRelease(String workspace, String profile);

  Future<SkyrimSetupStatus> continueSetup(String workspace, String profile);

  Future<SkyrimSetupStatus> cancel(String workspace, String profile);

  Future<void> openProjectPage(String componentId);
}

class _GrpcSkyrimSetupClient extends SkyrimSetupClient {
  _GrpcSkyrimSetupClient(ClientChannel channel, CallOptions options)
    : _client = wire.SkyrimSetupOperationsClient(channel, options: options);

  final wire.SkyrimSetupOperationsClient _client;

  @override
  Stream<SkyrimSetupStatus> watch(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
  }) => _client
      .watchSkyrimSetup(
        wire.ReadSkyrimSetupRequest(
          workspaceId: workspace,
          profileId: profile,
          selection: _wireSelection(selection),
        ),
      )
      .map(_decode);

  @override
  Future<void> openProjectPage(String componentId) async {
    await _client.openSkyrimSetupPage(
      wire.SkyrimSetupPageRequest(componentId: componentId),
    );
  }

  SkyrimSetupSelection _selection(wire.SkyrimSetupSelection value) =>
      SkyrimSetupSelection(
        skse: SkyrimSetupAction.values[value.skse.value],
        enb: SkyrimSetupAction.values[value.enb.value],
        fnis: SkyrimSetupAction.values[value.fnis.value],
        enbArchivePath: value.enbArchivePath.isEmpty
            ? null
            : value.enbArchivePath,
      );

  wire.SkyrimSetupSelection _wireSelection(SkyrimSetupSelection value) =>
      wire.SkyrimSetupSelection(
        skse: wire.SkyrimSetupAction.valueOf(value.skse.index)!,
        enb: wire.SkyrimSetupAction.valueOf(value.enb.index)!,
        fnis: wire.SkyrimSetupAction.valueOf(value.fnis.index)!,
        enbArchivePath: value.enbArchivePath ?? '',
      );

  SkyrimSetupStatus _decode(wire.SkyrimSetupState value) => SkyrimSetupStatus(
    phase: switch (value.phase) {
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_AVAILABLE =>
        SkyrimSetupStatusPhase.available,
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
      wire.SkyrimSetupPhase.SKYRIM_SETUP_PHASE_CANCELLED =>
        SkyrimSetupStatusPhase.cancelled,
      _ => SkyrimSetupStatusPhase.unavailable,
    },
    status: value.status,
    detail: value.detail,
    components: List.unmodifiable(
      value.components.map(
        (item) => SkyrimSetupComponent(
          id: item.id,
          name: item.name,
          status: item.status,
          detail: item.detail,
          ready: item.ready,
          active: item.active,
          blocked: item.blocked,
          installed: item.installed,
          updateVersion: item.updateVersion.isEmpty ? null : item.updateVersion,
        ),
      ),
    ),
    selection: _selection(value.selection),
    canStart: value.canStart,
    canContinue: value.canContinue,
    active: value.active,
    ready: value.ready,
    canCancel: value.canCancel,
  );

  @override
  Future<SkyrimSetupStatus> read(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
  }) async => _decode(
    await _client.readSkyrimSetup(
      wire.ReadSkyrimSetupRequest(
        workspaceId: workspace,
        profileId: profile,
        selection: _wireSelection(selection),
      ),
    ),
  );

  @override
  Future<SkyrimSetupStatus> start(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
    SkseReleaseChoice? skseChoice,
  }) async => _decode(
    await _client.startSkyrimSetup(
      wire.StartSkyrimSetupRequest(
        workspaceId: workspace,
        profileId: profile,
        selection: _wireSelection(selection),
        skseChoice: skseChoice == null
            ? null
            : wire.SkseReleaseChoice(
                fileId: Int64(skseChoice.fileId),
                componentVersion: skseChoice.componentVersion,
                gameVersion: skseChoice.gameVersion,
                gameSha256: skseChoice.gameSha256,
                allowIncompatible: skseChoice.allowIncompatible,
              ),
      ),
    ),
  );

  @override
  Future<SkseReleaseReview> reviewSkseRelease(
    String workspace,
    String profile,
  ) async {
    final value = await _client.reviewSkseRelease(
      wire.SkyrimSetupRequest(workspaceId: workspace, profileId: profile),
    );
    return SkseReleaseReview(
      compatible: value.compatible,
      gameVersion: value.gameVersion,
      gameSha256: value.gameSha256,
      fileId: value.fileId.toInt(),
      componentVersion: value.componentVersion,
      supportedRuntime: value.supportedRuntime.isEmpty
          ? null
          : value.supportedRuntime,
      problem: value.problem.isEmpty ? null : value.problem,
    );
  }

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
  Future<SkyrimSetupStatus> cancel(String workspace, String profile) async =>
      _decode(
        await _client.cancelSkyrimSetup(
          wire.SkyrimSetupRequest(workspaceId: workspace, profileId: profile),
        ),
      );
}
