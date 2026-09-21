import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/generated_outputs.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/mod_library.pb.dart' as modwire;
import 'output_models.dart';
import 'completed_events.dart';
import 'output_wire.dart' as mapping;
export 'output_models.dart';

abstract interface class GeneratedOutputsClient {
  Future<OutputScope> read(
    String workspaceId,
    String profileId, {
    String? contextId,
  });
  Future<OutputLocation> add(
    String id,
    OutputScopeRef expected,
    String name,
    OutputLocationKind kind, {
    List<String>? target,
  });
  Future<OutputLocation> stopUsing(String id, int revision);
  Stream<OutputLoadEvent> observe(OutputScopeRef expected);
  Future<OutputPage> page(
    String snapshotId, {
    required OutputLocationKind kind,
    String? cursor,
    String filter = '',
  });
  Future<OutputPromotionPreview> preview(
    String snapshotId,
    List<OutputSelection> files,
    OutputAction action,
  );
  Future<OutputActionResult> apply(
    String id,
    String snapshotId,
    List<OutputSelection> files,
    OutputAction action,
  );
  Future<OutputActionResult> action(String id);
  Future<OutputActionResult> resume(String id);
}

class GrpcGeneratedOutputsClient implements GeneratedOutputsClient {
  GrpcGeneratedOutputsClient(ClientChannel channel, CallOptions options)
    : _client = wire.GeneratedOutputOperationsClient(channel, options: options);
  final wire.GeneratedOutputOperationsClient _client;
  @override
  Future<OutputScope> read(
    String workspaceId,
    String profileId, {
    String? contextId,
  }) async => mapping.scopeReply(
    await _client.readOutputs(
      wire.ReadOutputsRequest(
        workspaceId: workspaceId,
        profileId: profileId,
        contextId: contextId,
      ),
    ),
  );
  @override
  Future<OutputLocation> add(
    String id,
    OutputScopeRef expected,
    String name,
    OutputLocationKind kind, {
    List<String>? target,
  }) async => mapping.locationReply(
    await _client.addOutputLocation(
      wire.AddOutputLocationRequest(
        id: id,
        expected: mapping.reference(expected),
        name: name,
        kind: switch (kind) {
          OutputLocationKind.toolFolder =>
            wire.OutputLocationKind.OUTPUT_LOCATION_KIND_TOOL_FOLDER,
          OutputLocationKind.writableFile =>
            wire.OutputLocationKind.OUTPUT_LOCATION_KIND_WRITABLE_FILE,
        },
        target: target == null
            ? null
            : modwire.ModLogicalPath(components: target),
      ),
    ),
  );
  @override
  Future<OutputLocation> stopUsing(String id, int revision) async =>
      mapping.locationReply(
        await _client.stopUsingOutputLocation(
          wire.StopOutputLocationRequest(id: id, revision: Int64(revision)),
        ),
      );
  @override
  Stream<OutputLoadEvent> observe(OutputScopeRef expected) => completedEvents(
    _client.observeOutputs(
      wire.ObserveOutputsRequest(expected: mapping.reference(expected)),
    ),
    (event) => event.hasFinished(),
    (value) => switch (value.whichEvent()) {
      wire.OutputLoadEvent_Event.progress => OutputLoadProgress(
        value.progress.files,
        value.progress.bytes.toInt(),
      ),
      wire.OutputLoadEvent_Event.finished => OutputsObserved(
        mapping.snapshotReply(value.finished),
      ),
      wire.OutputLoadEvent_Event.notSet => throw const FormatException(
        'Missing output progress event.',
      ),
    },
  );
  @override
  Future<OutputPage> page(
    String snapshotId, {
    required OutputLocationKind kind,
    String? cursor,
    String filter = '',
  }) async {
    final value = await _client.readOutputPage(
      wire.OutputPageRequest(
        snapshotId: snapshotId,
        cursor: cursor,
        filter: filter,
        kind: switch (kind) {
          OutputLocationKind.toolFolder =>
            wire.OutputLocationKind.OUTPUT_LOCATION_KIND_TOOL_FOLDER,
          OutputLocationKind.writableFile =>
            wire.OutputLocationKind.OUTPUT_LOCATION_KIND_WRITABLE_FILE,
        },
      ),
    );
    return switch (value.whichOutcome()) {
      wire.OutputPageReply_Outcome.page => OutputPage(
        mapping.snapshot(value.page.snapshot),
        List.unmodifiable(value.page.entries.map(mapping.file)),
        value.page.matching,
        value.page.hasNextCursor() ? value.page.nextCursor : null,
        value.page.files,
        value.page.unreviewed,
      ),
      wire.OutputPageReply_Outcome.fault => mapping.reject(value.fault),
      wire.OutputPageReply_Outcome.notSet => throw const FormatException(
        'Missing output page.',
      ),
    };
  }

  @override
  Future<OutputPromotionPreview> preview(
    String snapshotId,
    List<OutputSelection> files,
    OutputAction action,
  ) async {
    final value = await _client.previewOutputPromotion(
      wire.OutputPromotionRequest(
        snapshotId: snapshotId,
        files: files.map(mapping.selection),
        action: mapping.action(action),
      ),
    );
    return switch (value.whichOutcome()) {
      wire.OutputPromotionReply_Outcome.preview => OutputPromotionPreview(
        value.preview.selected,
        List.unmodifiable(
          value.preview.replaced.map(
            (value) => List<String>.unmodifiable(value.components),
          ),
        ),
        value.preview.hasPreviousVersion()
            ? value.preview.previousVersion
            : null,
        value.preview.registeredSource,
      ),
      wire.OutputPromotionReply_Outcome.fault => mapping.reject(value.fault),
      wire.OutputPromotionReply_Outcome.notSet => throw const FormatException(
        'Missing output promotion preview.',
      ),
    };
  }

  @override
  Future<OutputActionResult> apply(
    String id,
    String snapshotId,
    List<OutputSelection> files,
    OutputAction action,
  ) async => mapping.actionReply(
    await _client.applyOutputAction(
      wire.ApplyOutputActionRequest(
        id: id,
        snapshotId: snapshotId,
        files: files.map(mapping.selection),
        action: mapping.action(action),
      ),
    ),
  );
  @override
  Future<OutputActionResult> action(String id) async => mapping.actionReply(
    await _client.readOutputAction(wire.OutputActionRequest(id: id)),
  );
  @override
  Future<OutputActionResult> resume(String id) async => mapping.actionReply(
    await _client.resumeOutputAction(wire.OutputActionRequest(id: id)),
  );
}
