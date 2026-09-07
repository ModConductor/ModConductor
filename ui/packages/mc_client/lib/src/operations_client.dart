import 'dart:async';
import 'dart:math';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/operations.pbgrpc.dart' as wire;

typedef RuntimeSummary = ({
  String architecture,
  bool nativeAot,
  String sqliteVersion,
});
typedef ConnectionReport = ({RuntimeSummary runtime, int heartbeats});

enum OperationPhase { running, completed, cancelled, interrupted, stale }

class RuntimeCheck {
  const RuntimeCheck({
    required this.id,
    required this.expectedRevision,
    required this.count,
    required this.phase,
    required this.progress,
    required this.resultRevision,
    this.result,
  });
  final String id;
  final int expectedRevision;
  final int count;
  final OperationPhase phase;
  final int progress;
  final int resultRevision;
  final RuntimeSummary? result;
  bool get terminal => phase != OperationPhase.running;
}

typedef OperationChange = ({int cursor, RuntimeCheck operation});
typedef OperationFeed = ({
  int cursor,
  int revision,
  bool resyncRequired,
  List<RuntimeCheck>? snapshot,
  List<OperationChange> changes,
});

RuntimeCheck _snapshot(wire.OperationSnapshot value) => RuntimeCheck(
  id: value.operationId,
  expectedRevision: value.expectedRevision.toInt(),
  count: value.heartbeatCount,
  phase: switch (value.phase) {
    wire.OperationPhase.OPERATION_PHASE_RUNNING => OperationPhase.running,
    wire.OperationPhase.OPERATION_PHASE_COMPLETED => OperationPhase.completed,
    wire.OperationPhase.OPERATION_PHASE_CANCELLED => OperationPhase.cancelled,
    wire.OperationPhase.OPERATION_PHASE_INTERRUPTED =>
      OperationPhase.interrupted,
    wire.OperationPhase.OPERATION_PHASE_STALE => OperationPhase.stale,
    _ => throw const FormatException('Unsupported operation state.'),
  },
  progress: value.progress,
  resultRevision: value.resultRevision.toInt(),
  result: value.hasResult()
      ? (
          architecture: value.result.architecture,
          nativeAot: value.result.nativeAot,
          sqliteVersion: value.result.sqliteVersion,
        )
      : null,
);

OperationFeed _feed(wire.OperationBatch value) => (
  cursor: value.cursor.toInt(),
  revision: value.revision.toInt(),
  resyncRequired: value.resyncRequired,
  snapshot: value.hasSnapshot
      ? List.unmodifiable(value.snapshot.map(_snapshot))
      : null,
  changes: List.unmodifiable(
    value.changes.map(
      (change) => (
        cursor: change.cursor.toInt(),
        operation: _snapshot(change.operation),
      ),
    ),
  ),
);

String newOperationId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256),
  ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

class OperationsClient {
  OperationsClient(ClientChannel channel, CallOptions options)
    : _client = wire.EngineOperationsClient(channel, options: options);
  final wire.EngineOperationsClient _client;

  Future<OperationFeed> state() async =>
      _feed(await _client.getState(wire.StateRequest(protocolMajor: 1)));

  Future<RuntimeCheck> begin({
    required String id,
    required int expectedRevision,
    int count = 5,
  }) async => _snapshot(
    await _client.beginRuntimeCheck(
      wire.RuntimeCheckRequest(
        operationId: id,
        expectedRevision: Int64(expectedRevision),
        heartbeatCount: count,
      ),
    ),
  );

  Future<RuntimeCheck> get(String id) async => _snapshot(
    await _client.getOperation(wire.OperationIdentity(operationId: id)),
  );
  Future<RuntimeCheck> cancel(String id) async => _snapshot(
    await _client.cancelOperation(wire.OperationIdentity(operationId: id)),
  );

  Stream<OperationFeed> watch({int? afterCursor}) async* {
    final request = wire.WatchRequest();
    if (afterCursor != null) request.afterCursor = Int64(afterCursor);
    final call = _client.watchOperations(
      request,
      options: CallOptions(timeout: const Duration(seconds: 30)),
    );
    try {
      await for (final batch in call) {
        yield _feed(batch);
      }
    } finally {
      await call.cancel();
    }
  }

  Future<RuntimeCheck> waitForResult(String id, {int? afterCursor}) async {
    await for (final batch in watch(afterCursor: afterCursor)) {
      RuntimeCheck? current;
      for (final snapshot in batch.snapshot ?? const <RuntimeCheck>[]) {
        if (snapshot.id == id) current = snapshot;
      }
      for (final change in batch.changes) {
        if (change.operation.id == id) current = change.operation;
      }
      if (batch.snapshot != null && current == null) current = await get(id);
      if (current != null && current.terminal) return current;
    }
    throw const FormatException(
      'The operation stream ended before the result.',
    );
  }

  Future<ConnectionReport> check() async {
    final before = await state();
    final id = newOperationId();
    var operation = await begin(id: id, expectedRevision: before.revision);
    if (!operation.terminal) {
      operation = await waitForResult(id, afterCursor: before.cursor);
    }
    final runtime = operation.result;
    if (operation.phase != OperationPhase.completed || runtime == null) {
      throw const FormatException('The runtime check did not complete.');
    }
    return (runtime: runtime, heartbeats: operation.progress);
  }
}
