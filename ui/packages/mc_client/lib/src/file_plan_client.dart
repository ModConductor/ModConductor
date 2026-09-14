import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/file_plans.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/mod_library.pb.dart' as modwire;
import 'file_plan_models.dart';
import 'file_plan_wire.dart' as mapping;
export 'file_plan_models.dart';

abstract interface class FilePlansClient {
  Future<FilePlanState> open(String profileId);
  Stream<FilePlanLoadEvent> acquire(String profileId, {required bool refresh});
  Future<FilePlanState> read(String snapshotId);
  Future<FilePlanPage> children(
    String snapshotId, {
    List<String>? parent,
    String filter = '',
    FilePlanCursor? cursor,
  });
  Future<FilePlanProblems> problems(
    String snapshotId, {
    FilePlanCursor? cursor,
  });
  Future<FilePlanInspection> inspect(
    String snapshotId,
    List<String> target, {
    FilePlanCursor? cursor,
  });
  Future<FilePlanInspection> inspectCopy(
    String snapshotId,
    ManagedFileCopy copy,
  );
  Future<FileVisibilityChange> change(
    String snapshotId,
    ManagedFileCopy copy, {
    required bool hidden,
  });
  FilePreviewRead preview(
    String snapshotId,
    FilePreviewSource source,
    FilePreviewRepresentation representation,
  );
  Future<ManagedTextDocument> openManagedText(
    String snapshotId,
    ManagedPreviewSource source,
  );
  Future<ManagedTextEdit> saveManagedText(
    String snapshotId,
    String id,
    ManagedPreviewSource source,
    String content,
  );
  Future<void> abandonManagedText(String id);
  Future<FileVisibilityHistory> history(
    String snapshotId,
    ManagedFileCopy copy, {
    int? beforeId,
  });
}

class GrpcFilePlansClient implements FilePlansClient {
  GrpcFilePlansClient(ClientChannel channel, CallOptions options)
    : _client = wire.FilePlanOperationsClient(channel, options: options);
  final wire.FilePlanOperationsClient _client;
  @override
  Future<FilePlanState> open(String profileId) async => mapping.reply(
    await _client.openFilePlan(wire.OpenFilePlanRequest(profileId: profileId)),
  );
  @override
  Stream<FilePlanLoadEvent> acquire(
    String profileId, {
    required bool refresh,
  }) => _client
      .acquireFilePlan(
        wire.AcquireFilePlanRequest(profileId: profileId, refresh: refresh),
      )
      .map(
        (event) => switch (event.whichEvent()) {
          wire.FilePlanLoadEvent_Event.progress => FilePlanProgress(
            event.progress.files,
            event.progress.totalFiles,
            event.progress.bytes.toInt(),
            event.progress.totalBytes.toInt(),
          ),
          wire.FilePlanLoadEvent_Event.finished => FilePlanLoaded(
            mapping.reply(event.finished),
          ),
          wire.FilePlanLoadEvent_Event.notSet => throw const FormatException(
            'Missing file acquisition event.',
          ),
        },
      );
  @override
  Future<FilePlanState> read(String snapshotId) async => mapping.reply(
    await _client.readFilePlan(wire.FilePlanRequest(snapshotId: snapshotId)),
  );
  @override
  Future<FilePlanPage> children(
    String snapshotId, {
    List<String>? parent,
    String filter = '',
    FilePlanCursor? cursor,
  }) async {
    final reply = await _client.readFilePlanChildren(
      wire.FilePlanChildrenRequest(
        snapshotId: snapshotId,
        parent: parent == null
            ? null
            : modwire.ModLogicalPath(components: parent),
        filter: filter,
        cursor: mapping.encodeCursor(cursor),
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.FilePlanPageReply_Outcome.page => FilePlanPage(
        mapping.state(reply.page.state),
        List.unmodifiable(reply.page.nodes.map(mapping.node)),
        reply.page.hasNext() ? mapping.decodeCursor(reply.page.next) : null,
      ),
      wire.FilePlanPageReply_Outcome.fault => mapping.reject(reply.fault),
      wire.FilePlanPageReply_Outcome.notSet => throw const FormatException(
        'Missing file page.',
      ),
    };
  }

  @override
  Future<FilePlanProblems> problems(
    String snapshotId, {
    FilePlanCursor? cursor,
  }) async {
    final reply = await _client.readFilePlanProblems(
      wire.FilePlanProblemsRequest(
        snapshotId: snapshotId,
        cursor: mapping.encodeCursor(cursor),
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.FilePlanProblemsReply_Outcome.problems => FilePlanProblems(
        List.unmodifiable(reply.problems.problems),
        reply.problems.hasNext()
            ? mapping.decodeCursor(reply.problems.next)
            : null,
      ),
      wire.FilePlanProblemsReply_Outcome.fault => mapping.reject(reply.fault),
      wire.FilePlanProblemsReply_Outcome.notSet => throw const FormatException(
        'Missing file problems.',
      ),
    };
  }

  @override
  Future<FilePlanInspection> inspect(
    String snapshotId,
    List<String> target, {
    FilePlanCursor? cursor,
  }) async => mapping.inspection(
    await _client.inspectFilePlanTarget(
      wire.InspectFilePlanRequest(
        snapshotId: snapshotId,
        target: modwire.ModLogicalPath(components: target),
        cursor: mapping.encodeCursor(cursor),
      ),
    ),
  );
  @override
  Future<FilePlanInspection> inspectCopy(
    String snapshotId,
    ManagedFileCopy copy,
  ) async => mapping.inspection(
    await _client.inspectSavedFile(
      wire.InspectSavedFileRequest(
        snapshotId: snapshotId,
        copy: mapping.encodeCopy(copy),
      ),
    ),
  );
  @override
  Future<FileVisibilityChange> change(
    String snapshotId,
    ManagedFileCopy copy, {
    required bool hidden,
  }) async {
    final reply = await _client.changeFileVisibility(
      wire.ChangeFileVisibilityRequest(
        snapshotId: snapshotId,
        copy: mapping.encodeCopy(copy),
        hidden: hidden,
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.FileVisibilityReply_Outcome.change => FileVisibilityChange(
        mapping.state(reply.change.state),
        reply.change.hasChanged() ? mapping.node(reply.change.changed) : null,
      ),
      wire.FileVisibilityReply_Outcome.fault => mapping.reject(reply.fault),
      wire.FileVisibilityReply_Outcome.notSet => throw const FormatException(
        'Missing file visibility result.',
      ),
    };
  }

  @override
  FilePreviewRead preview(
    String snapshotId,
    FilePreviewSource source,
    FilePreviewRepresentation representation,
  ) {
    final call = _client.previewFileSource(
      wire.FilePreviewRequest(
        snapshotId: snapshotId,
        source: mapping.encodeSource(source),
        representation: mapping.encodeRepresentation(representation),
      ),
      options: CallOptions(timeout: const Duration(days: 1)),
    );
    return FilePreviewRead(call.then(mapping.preview), call.cancel);
  }

  @override
  Future<ManagedTextDocument> openManagedText(
    String snapshotId,
    ManagedPreviewSource source,
  ) async {
    final encoded = mapping.encodeSource(source).managed;
    final reply = await _client.openManagedText(
      wire.OpenManagedTextRequest(snapshotId: snapshotId, source: encoded),
    );
    return switch (reply.whichOutcome()) {
      wire.ManagedTextReply_Outcome.document => ManagedTextDocument(
        mapping.decodeSource(
          wire.FilePreviewSource(managed: reply.document.source),
        ) as ManagedPreviewSource,
        mapping.textDocument(reply.document.document),
      ),
      wire.ManagedTextReply_Outcome.fault => mapping.reject(reply.fault),
      wire.ManagedTextReply_Outcome.notSet => throw const FormatException(
        'Missing managed text document.',
      ),
    };
  }

  @override
  Future<ManagedTextEdit> saveManagedText(
    String snapshotId,
    String id,
    ManagedPreviewSource source,
    String content,
  ) async {
    final encoded = mapping.encodeSource(source).managed;
    final reply = await _client.saveManagedText(
      wire.SaveManagedTextRequest(
        snapshotId: snapshotId,
        id: id,
        source: encoded,
        content: content,
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.ManagedTextEditReply_Outcome.edit => ManagedTextEdit(
        reply.edit.id,
        reply.edit.versionId,
        mapping.decodeSource(wire.FilePreviewSource(managed: reply.edit.source))
            as ManagedPreviewSource,
      ),
      wire.ManagedTextEditReply_Outcome.fault => mapping.reject(reply.fault),
      wire.ManagedTextEditReply_Outcome.notSet => throw const FormatException(
        'Missing managed text edit.',
      ),
    };
  }

  @override
  Future<void> abandonManagedText(String id) async {
    final reply = await _client.abandonManagedText(
      wire.AbandonManagedTextRequest(id: id),
    );
    switch (reply.whichOutcome()) {
      case wire.ManagedTextAbandonReply_Outcome.abandonedId:
        if (reply.abandonedId != id) {
          throw const FormatException('Wrong abandoned text edit.');
        }
      case wire.ManagedTextAbandonReply_Outcome.fault:
        mapping.reject(reply.fault);
      case wire.ManagedTextAbandonReply_Outcome.notSet:
        throw const FormatException('Missing abandoned text edit result.');
    }
  }

  @override
  Future<FileVisibilityHistory> history(
    String snapshotId,
    ManagedFileCopy copy, {
    int? beforeId,
  }) async {
    final reply = await _client.readFileVisibilityHistory(
      wire.FileVisibilityHistoryRequest(
        snapshotId: snapshotId,
        copy: mapping.encodeCopy(copy),
        beforeId: beforeId == null ? null : Int64(beforeId),
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.FileVisibilityHistoryReply_Outcome.history => FileVisibilityHistory(
        List.unmodifiable(reply.history.changes.map(mapping.audit)),
        reply.history.hasNextBeforeId()
            ? reply.history.nextBeforeId.toInt()
            : null,
      ),
      wire.FileVisibilityHistoryReply_Outcome.fault => mapping.reject(
        reply.fault,
      ),
      wire.FileVisibilityHistoryReply_Outcome.notSet =>
        throw const FormatException('Missing file history.'),
    };
  }
}
