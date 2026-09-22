import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'artifact_models.dart';
import 'installation_client.dart';
import 'maintenance_models.dart';
import 'mod_library_models.dart';
import 'generated/modconductor/v1/mod_updates.pbgrpc.dart' as update;
import 'generated/modconductor/v1/mod_deletion.pbgrpc.dart' as deletion;
import 'generated/modconductor/v1/mod_library.pb.dart' as mods;
import 'generated/modconductor/v1/archive_installation.pb.dart' as install;
export 'maintenance_models.dart';

abstract interface class MaintenanceClient {
  Future<UpdatePreview> prepareUpdate(
    InstallationDraft draft,
    ModEntry target,
    UpdateMode mode,
    List<List<String>> keep,
    String version,
  );
  Future<InstallationStatus> startUpdate(UpdatePreview preview, String id);
  Future<DeletionPreview> prepareDeletion(ModEntry target);
  Future<void> deleteMod(DeletionPreview preview);
}

class GrpcMaintenanceClient implements MaintenanceClient {
  GrpcMaintenanceClient(ClientChannel channel, CallOptions options)
    : _updates = update.ModUpdatesClient(channel, options: options),
      _deletions = deletion.ModDeletionClient(channel, options: options);
  final update.ModUpdatesClient _updates;
  final deletion.ModDeletionClient _deletions;
  Future<T> _call<T>(Future<T> future) async {
    try {
      return await future;
    } on GrpcError catch (error) {
      throw ArtifactProblem(error.message ?? 'The mod operation failed.');
    }
  }

  @override
  Future<UpdatePreview> prepareUpdate(
    InstallationDraft draft,
    ModEntry target,
    UpdateMode mode,
    List<List<String>> keep,
    String version,
  ) async {
    final value = await _call(
      _updates.prepareModUpdate(
        update.PrepareModUpdateRequest(
          draft: install.InstallationDraftReference(
            workspaceId: draft.workspaceId,
            id: draft.id,
            revision: Int64(draft.revision),
          ),
          modId: target.id,
          revision: Int64(target.revision),
          mode: mode == UpdateMode.merge
              ? update.ModUpdateMode.MOD_UPDATE_MODE_MERGE
              : update.ModUpdateMode.MOD_UPDATE_MODE_REPLACE,
          keep: keep.map((path) => mods.ModLogicalPath(components: path)),
          version: version,
        ),
      ),
    );
    return UpdatePreview(
      id: value.id,
      workspaceId: value.workspaceId,
      modId: value.modId,
      name: value.name,
      currentVersion: value.currentVersion,
      nextVersion: value.nextVersion,
      mode: value.mode == update.ModUpdateMode.MOD_UPDATE_MODE_MERGE
          ? UpdateMode.merge
          : UpdateMode.replace,
      files: [
        for (final file in value.files)
          UpdateFile(
            List.unmodifiable(file.path.components),
            switch (file.change) {
              update.ModUpdateChange.MOD_UPDATE_CHANGE_ADD => UpdateChange.add,
              update.ModUpdateChange.MOD_UPDATE_CHANGE_REPLACE =>
                UpdateChange.replace,
              update.ModUpdateChange.MOD_UPDATE_CHANGE_REMOVE =>
                UpdateChange.remove,
              update.ModUpdateChange.MOD_UPDATE_CHANGE_KEEP =>
                UpdateChange.keep,
              _ => throw const ArtifactProblem('Unknown update change.'),
            },
            file.hasExistingBytes() ? file.existingBytes.toInt() : null,
            file.hasIncomingBytes() ? file.incomingBytes.toInt() : null,
            [
              for (final path in file.existingPaths)
                List.unmodifiable(path.components),
            ],
            file.hasIncoming,
          ),
      ],
      keep: [for (final path in value.keep) List.unmodifiable(path.components)],
      requiredBytes: value.requiredBytes.toInt(),
      sourceNotices: List.unmodifiable(value.sourceNotices),
    );
  }

  @override
  Future<InstallationStatus> startUpdate(
    UpdatePreview preview,
    String id,
  ) async => installationStatus(
    await _call(
      _updates.startModUpdate(
        update.StartModUpdateRequest(
          workspaceId: preview.workspaceId,
          previewId: preview.id,
          id: id,
        ),
      ),
    ),
  );
  @override
  Future<DeletionPreview> prepareDeletion(ModEntry target) async {
    final value = await _call(
      _deletions.prepareModDeletion(
        deletion.PrepareModDeletionRequest(
          workspaceId: target.workspaceId,
          modId: target.id,
          revision: Int64(target.revision),
        ),
      ),
    );
    return DeletionPreview(
      workspaceId: value.workspaceId,
      modId: value.modId,
      revision: value.revision.toInt(),
      name: value.name,
      versions: value.versions,
      backups: List.unmodifiable(value.backups),
      external: List.unmodifiable(value.external),
      blocked: value.hasBlocked() ? value.blocked : null,
      profiles: [
        for (final profile in value.profiles)
          DeletionProfile(profile.id, profile.name),
      ],
      deployments: [
        for (final entry in value.deployments)
          DeletionDeployment(
            entry.contextId,
            entry.id,
            entry.name,
            entry.hasPreparedAtUnixMs()
                ? DateTime.fromMillisecondsSinceEpoch(
                    entry.preparedAtUnixMs.toInt(),
                    isUtc: true,
                  )
                : null,
            entry.active,
          ),
      ],
      files: [
        for (final file in value.files)
          DeletionFile(
            file.label,
            switch (file.kind) {
              deletion.ModDeletionFileKind.MOD_DELETION_FILE_KIND_PAYLOAD =>
                DeletionFileKind.payload,
              deletion.ModDeletionFileKind.MOD_DELETION_FILE_KIND_ARCHIVE =>
                DeletionFileKind.archive,
              deletion.ModDeletionFileKind.MOD_DELETION_FILE_KIND_TEMPORARY =>
                DeletionFileKind.temporary,
              deletion
                  .ModDeletionFileKind
                  .MOD_DELETION_FILE_KIND_GENERATION_LINK =>
                DeletionFileKind.generationLink,
              _ => throw const ArtifactProblem('Unknown deletion file type.'),
            },
            file.hasBytes() ? file.bytes.toInt() : null,
            file.shared,
          ),
      ],
    );
  }

  @override
  Future<void> deleteMod(DeletionPreview preview) async {
    await _call(
      _deletions.deleteMod(
        deletion.DeleteModRequest(
          workspaceId: preview.workspaceId,
          modId: preview.modId,
          revision: Int64(preview.revision),
        ),
      ),
    );
  }
}
