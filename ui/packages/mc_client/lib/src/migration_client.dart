import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/migration.pbgrpc.dart' as wire;

enum MigrationManager { modOrganizer }

sealed class MigrationEvent {
  const MigrationEvent();
}

final class MigrationProgress extends MigrationEvent {
  const MigrationProgress(this.completed, this.total, this.message);
  final int completed, total;
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
  Stream<MigrationEvent> migrate(
    String workspaceId,
    MigrationManager manager,
    String sourceFolder,
  );
}

final class GrpcMigrationClient implements MigrationClient {
  GrpcMigrationClient(ClientChannel channel, CallOptions options)
    : _wire = wire.MigrationOperationsClient(
        channel,
        options: CallOptions(metadata: options.metadata),
      );

  final wire.MigrationOperationsClient _wire;

  @override
  Stream<MigrationEvent> migrate(
    String workspaceId,
    MigrationManager manager,
    String sourceFolder,
  ) => _wire
      .migrate(
        wire.MigrationRequest(
          workspaceId: workspaceId,
          manager: switch (manager) {
            MigrationManager.modOrganizer =>
              wire.MigrationManager.MIGRATION_MANAGER_MOD_ORGANIZER,
          },
          sourceFolder: sourceFolder,
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
