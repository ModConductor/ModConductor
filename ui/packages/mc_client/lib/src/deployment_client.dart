import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/deployments.pbgrpc.dart' as wire;
import 'deployment_models.dart';
import 'completed_events.dart';
import 'deployment_wire.dart' as mapping;
export 'deployment_models.dart';

abstract interface class DeploymentsClient {
  Future<DeploymentState> read(String profileId);
  Future<SavedDeploymentsPage> saved(String profileId, {int? before});
  Stream<DeploymentEvent> prepare(
    String id,
    String profileId,
    String sourceToken, {
    bool retained = false,
    String? generationId,
  });
  Stream<DeploymentEvent> activate(
    String preparedId,
    String profileId,
    String sourceToken,
  );
  Stream<DeploymentEvent> recover(
    String receiptId,
    int revision, {
    required bool restore,
  });
  Future<DeploymentReceipt> receipt(String id);
}

class GrpcDeploymentsClient implements DeploymentsClient {
  GrpcDeploymentsClient(ClientChannel channel, CallOptions options)
    : _client = wire.DeploymentOperationsClient(channel, options: options);
  final wire.DeploymentOperationsClient _client;
  @override
  Future<DeploymentState> read(String profileId) async => mapping.stateReply(
    await _client.readDeployment(
      wire.ReadDeploymentRequest(profileId: profileId),
    ),
  );
  @override
  Future<SavedDeploymentsPage> saved(String profileId, {int? before}) async {
    final value = await _client.readSavedDeployments(
      wire.SavedDeploymentsRequest(
        profileId: profileId,
        before: before == null ? null : Int64(before),
      ),
    );
    return switch (value.whichOutcome()) {
      wire.SavedDeploymentsReply_Outcome.page => SavedDeploymentsPage(
        List.unmodifiable(value.page.entries.map(mapping.saved)),
        value.page.hasNextBefore() ? value.page.nextBefore.toInt() : null,
      ),
      wire.SavedDeploymentsReply_Outcome.fault => mapping.reject(value.fault),
      wire.SavedDeploymentsReply_Outcome.notSet => throw const FormatException(
        'Missing saved deployments.',
      ),
    };
  }

  @override
  Stream<DeploymentEvent> prepare(
    String id,
    String profileId,
    String sourceToken, {
    bool retained = false,
    String? generationId,
  }) => completedEvents(
    _client.prepareDeployment(
      wire.PrepareDeploymentRequest(
        id: id,
        profileId: profileId,
        sourceToken: sourceToken,
        retained: retained,
        generationId: generationId,
      ),
    ),
    (event) => event.hasFinished(),
    (event) => switch (event.whichEvent()) {
      wire.DeploymentPrepareEvent_Event.progress => mapping.progress(
        event.progress,
      ),
      wire.DeploymentPrepareEvent_Event.finished => DeploymentPrepared(
        mapping.preparedReply(event.finished),
      ),
      wire.DeploymentPrepareEvent_Event.notSet => throw const FormatException(
        'Missing deployment preparation event.',
      ),
    },
  );
  DeploymentEvent _event(wire.DeploymentRunEvent event) => switch (event
      .whichEvent()) {
    wire.DeploymentRunEvent_Event.progress => mapping.progress(event.progress),
    wire.DeploymentRunEvent_Event.finished => DeploymentFinished(
      mapping.receiptReply(event.finished),
    ),
    wire.DeploymentRunEvent_Event.notSet => throw const FormatException(
      'Missing deployment event.',
    ),
  };
  @override
  Stream<DeploymentEvent> activate(
    String preparedId,
    String profileId,
    String sourceToken,
  ) => completedEvents(
    _client.activateDeployment(
      wire.ActivateDeploymentRequest(
        preparedId: preparedId,
        profileId: profileId,
        sourceToken: sourceToken,
      ),
    ),
    (event) => event.hasFinished(),
    _event,
  );
  @override
  Stream<DeploymentEvent> recover(
    String receiptId,
    int revision, {
    required bool restore,
  }) => completedEvents(
    _client.recoverDeployment(
      wire.RecoverDeploymentRequest(
        receiptId: receiptId,
        revision: Int64(revision),
        restore: restore,
      ),
    ),
    (event) => event.hasFinished(),
    _event,
  );
  @override
  Future<DeploymentReceipt> receipt(String id) async => mapping.receiptReply(
    await _client.readDeploymentReceipt(
      wire.DeploymentReceiptRequest(receiptId: id),
    ),
  );
}
