import 'package:grpc/grpc.dart';
import 'package:mc_client/src/generated/modconductor/v1/migration.pbgrpc.dart'
    as wire;

enum MigrationManager { modOrganizer, vortex }

final class BackupProfile {
  const BackupProfile({
    required this.id,
    required this.name,
    required this.gameId,
  });

  final String id;
  final String name;
  final String gameId;
}

sealed class MigrationEvent {
  const MigrationEvent();
}

final class MigrationProgress extends MigrationEvent {
  const MigrationProgress(this.completed, this.total, this.message);
  final int completed;
  final int total;
  final String message;
}

final class MigrationResult extends MigrationEvent {
  const MigrationResult(this.workspaceId);
  final String workspaceId;
}

final class MigrationFailure extends MigrationEvent implements Exception {
  const MigrationFailure(this.detail);
  final String detail;
}

abstract interface class MigrationClient {
  Future<List<BackupProfile>> profiles(
    MigrationManager manager,
    String sourceFile,
  );

  Stream<MigrationEvent> migrate(
    String workspaceId,
    MigrationManager manager,
    String sourcePath, {
    String profileId = '',
    String stagingRoot = '',
    String downloadRoot = '',
  });
}

final class GrpcMigrationClient implements MigrationClient {
  GrpcMigrationClient(ClientChannel channel, CallOptions options)
    : _wire = wire.MigrationOperationsClient(
        channel,
        options: CallOptions(metadata: options.metadata),
      );

  final wire.MigrationOperationsClient _wire;

  static wire.MigrationManager _manager(MigrationManager manager) =>
      switch (manager) {
        MigrationManager.modOrganizer =>
          wire.MigrationManager.MIGRATION_MANAGER_MOD_ORGANIZER,
        MigrationManager.vortex =>
          wire.MigrationManager.MIGRATION_MANAGER_VORTEX,
      };

  @override
  Future<List<BackupProfile>> profiles(
    MigrationManager manager,
    String sourceFile,
  ) async {
    final response = await _wire.profiles(
      wire.ProfileRequest(manager: _manager(manager), sourceFile: sourceFile),
    );
    if (response.hasError()) throw MigrationFailure(response.error.detail);
    return [
      for (final profile in response.profiles)
        BackupProfile(
          id: profile.id,
          name: profile.name,
          gameId: profile.gameId,
        ),
    ];
  }

  @override
  Stream<MigrationEvent> migrate(
    String workspaceId,
    MigrationManager manager,
    String sourcePath, {
    String profileId = '',
    String stagingRoot = '',
    String downloadRoot = '',
  }) => _wire
      .migrate(
        wire.MigrationRequest(
          workspaceId: workspaceId,
          manager: _manager(manager),
          sourceFolder: sourcePath,
          profileId: profileId,
          stagingRoot: stagingRoot,
          downloadRoot: downloadRoot,
        ),
      )
      .map(
        (event) => switch (event.whichEvent()) {
          wire.MigrationEvent_Event.progress => MigrationProgress(
            event.progress.completed,
            event.progress.total,
            event.progress.message,
          ),
          wire.MigrationEvent_Event.error => MigrationFailure(
            event.error.detail,
          ),
          wire.MigrationEvent_Event.result => MigrationResult(
            event.result.workspaceId,
          ),
          wire.MigrationEvent_Event.notSet => const MigrationFailure(
            'Migration did not return a result.',
          ),
        },
      );
}
