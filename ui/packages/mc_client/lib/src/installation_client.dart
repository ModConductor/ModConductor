import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'artifact_models.dart';
import 'archive_inspection_models.dart';
import 'installation_models.dart';
import 'generated/modconductor/v1/archive_installation.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/artifacts.pb.dart' as artifacts;
export 'installation_models.dart';

abstract interface class InstallationsClient {
  InstallationPreparation prepare(Artifact artifact);
  Future<InstallationDraft> change(
    InstallationDraft draft,
    InstallationLayoutChange change,
  );
  Future<void> closeDraft(InstallationDraft draft);
  Future<InstallationStatus> start(InstallationDraft draft, String id);
  Future<List<InstallationStatus>> recent(String workspaceId);
  Stream<InstallationStatus> watch(InstallationStatus status);
  Future<InstallationStatus> cancel(InstallationStatus status);
  Future<InstallationStatus> deleteTemporaryFiles(InstallationStatus status);
}

class GrpcInstallationsClient implements InstallationsClient {
  GrpcInstallationsClient(ClientChannel channel, CallOptions options)
    : _client = wire.ArchiveInstallationClient(channel, options: options);
  final wire.ArchiveInstallationClient _client;
  Future<T> _call<T>(Future<T> pending) async {
    try {
      return await pending;
    } on GrpcError catch (error) {
      throw ArtifactProblem(
        error.message ?? 'The installation operation failed.',
      );
    }
  }

  wire.InstallationDraftReference _reference(InstallationDraft d) =>
      wire.InstallationDraftReference(
        workspaceId: d.workspaceId,
        id: d.id,
        revision: Int64(d.revision),
      );
  wire.InstallationReference _job(InstallationStatus s) =>
      wire.InstallationReference(workspaceId: s.workspaceId, id: s.id);
  @override
  InstallationPreparation prepare(Artifact artifact) {
    final call = _client.prepareInstallation(
      artifacts.ArtifactReference(
        workspaceId: artifact.workspaceId,
        id: artifact.id,
        revision: Int64(artifact.revision),
      ),
      options: CallOptions(timeout: const Duration(days: 1)),
    );
    return InstallationPreparation(
      _call(call).then(installationDraft),
      call.cancel,
    );
  }

  @override
  Future<InstallationDraft> change(
    InstallationDraft draft,
    InstallationLayoutChange change,
  ) async {
    final request = wire.InstallationLayoutChange(reference: _reference(draft));
    switch (change) {
      case InstallationRootChange():
        request.root = wire.InstallationRoot(components: change.components);
      case InstallationInclusionChange():
        request.inclusion = wire.InstallationInclusion(
          source: change.source,
          included: change.included,
        );
      case InstallationDestinationChange():
        request.destination = wire.InstallationDestination(
          source: change.source,
          destination: change.destination,
        );
      case InstallationMetadataChange():
        request.metadata = wire.InstallationMetadata(
          name: change.name,
          version: change.version,
        );
    }
    return installationDraft(
      await _call(_client.changeInstallationLayout(request)),
    );
  }

  @override
  Future<void> closeDraft(InstallationDraft draft) =>
      _call(_client.closeInstallationDraft(_reference(draft)));
  @override
  Future<InstallationStatus> start(InstallationDraft draft, String id) async =>
      installationStatus(
        await _call(
          _client.startInstallation(
            wire.StartArchiveInstallation(draft: _reference(draft), id: id),
          ),
        ),
      );
  @override
  Future<List<InstallationStatus>> recent(String workspaceId) async =>
      (await _call(
        _client.recentInstallations(
          wire.InstallationWorkspace(workspaceId: workspaceId),
        ),
      )).entries.map(installationStatus).toList();
  @override
  Stream<InstallationStatus> watch(InstallationStatus status) async* {
    try {
      yield* _client.watchInstallation(_job(status)).map(installationStatus);
    } on GrpcError catch (error) {
      throw ArtifactProblem(
        error.message ?? 'Installation progress is unavailable.',
      );
    }
  }

  @override
  Future<InstallationStatus> cancel(InstallationStatus status) async =>
      installationStatus(await _call(_client.cancelInstallation(_job(status))));
  @override
  Future<InstallationStatus> deleteTemporaryFiles(
    InstallationStatus status,
  ) async => installationStatus(
    await _call(_client.deleteInstallationFiles(_job(status))),
  );
}

InstallationStatus installationStatus(wire.ArchiveInstallationStatus s) =>
    InstallationStatus(
      id: s.id,
      workspaceId: s.workspaceId,
      artifactId: s.artifactId,
      archiveName: s.archiveName,
      name: s.name,
      version: s.version,
      isUpdate: s.isUpdate,
      phase: switch (s.phase) {
        wire.InstallationPhase.INSTALLATION_PHASE_RUNNING =>
          InstallationPhase.running,
        wire.InstallationPhase.INSTALLATION_PHASE_STOPPED =>
          InstallationPhase.stopped,
        wire.InstallationPhase.INSTALLATION_PHASE_COMPLETE =>
          InstallationPhase.complete,
        wire.InstallationPhase.INSTALLATION_PHASE_DISCARDED =>
          InstallationPhase.discarded,
        _ => throw const ArtifactProblem('Unknown installation state.'),
      },
      files: s.files,
      totalFiles: s.totalFiles,
      bytes: s.bytes.toInt(),
      totalBytes: s.totalBytes.toInt(),
      temporaryBytes: s.hasTemporaryBytes() ? s.temporaryBytes.toInt() : null,
      problem: s.hasProblem() ? s.problem : null,
      modId: s.hasModId() ? s.modId : null,
      versionId: s.hasVersionId() ? s.versionId : null,
    );

InstallationDraft installationDraft(wire.ArchiveInstallationDraft d) =>
    InstallationDraft(
      id: d.reference.id,
      workspaceId: d.reference.workspaceId,
      revision: d.reference.revision.toInt(),
      artifactId: d.artifact.id,
      archiveName: d.archiveName,
      manifest: InspectedArchive(d.manifest.sha256, d.manifest.format, [
        for (final e in d.manifest.entries)
          InspectedEntry(
            e.index,
            List.unmodifiable(e.components),
            e.directory,
            e.size.toInt(),
            e.hasCompressedSize() ? e.compressedSize.toInt() : null,
          ),
      ], d.manifest.totalSize.toInt()),
      root: List.unmodifiable(d.root),
      files: [
        for (final f in d.files)
          InstallationFile(f.index, List.unmodifiable(f.destination)),
      ],
      name: d.name,
      version: d.version,
      bytes: d.bytes.toInt(),
      canInstall: d.canInstall,
      choiceInstaller: d.choiceInstaller,
    );
