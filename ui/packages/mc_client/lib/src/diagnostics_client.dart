import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/diagnostics.pbgrpc.dart' as wire;

enum DiagnosticSeverity { information, warning, error }

enum DiagnosticFixability { notFixable, previewAvailable, ready, refused }

enum DiagnosticFault {
  notFound,
  expired,
  stale,
  foreign,
  notOwned,
  busy,
  oversized,
  unsupported,
  cancelled,
}

class DiagnosticsException implements Exception {
  const DiagnosticsException(this.fault);
  final DiagnosticFault fault;
}

class DiagnosticEvidence {
  const DiagnosticEvidence(this.label, this.value);
  final String label, value;
}

class DiagnosticCorrelation {
  const DiagnosticCorrelation(this.kind, this.id, this.revision);
  final String kind, id;
  final int? revision;
}

class DiagnosticFinding {
  const DiagnosticFinding({
    required this.id,
    required this.code,
    required this.severity,
    required this.workspaceName,
    required this.profileName,
    required this.gameName,
    required this.title,
    required this.summary,
    required this.detail,
    required this.area,
    required this.evidence,
    required this.nextAction,
    required this.fixability,
    required this.fixDetail,
    required this.correlations,
  });
  final String id,
      code,
      workspaceName,
      profileName,
      gameName,
      title,
      summary,
      area,
      nextAction,
      fixDetail;
  final String? detail;
  final DiagnosticSeverity severity;
  final DiagnosticFixability fixability;
  final List<DiagnosticEvidence> evidence;
  final List<DiagnosticCorrelation> correlations;
}

class DiagnosticSnapshot {
  const DiagnosticSnapshot(
    this.id,
    this.workspaceId,
    this.profileId,
    this.capturedAt,
    this.findings,
  );
  final String id, workspaceId, profileId;
  final DateTime capturedAt;
  final List<DiagnosticFinding> findings;
}

class DiagnosticPreview {
  const DiagnosticPreview(
    this.id,
    this.snapshotId,
    this.problemId,
    this.expiresAt,
    this.items,
    this.identifiers,
    this.result,
  );
  final String id, snapshotId, problemId, result;
  final DateTime expiresAt;
  final List<DiagnosticRemediationItem> items;
  final List<DiagnosticRemediationIdentifier> identifiers;
}

class DiagnosticRemediationItem {
  const DiagnosticRemediationItem(this.label, this.value);
  final String label, value;
}

class DiagnosticRemediationIdentifier {
  const DiagnosticRemediationIdentifier(this.label, this.value);
  final String label, value;
}

class DiagnosticApplyResult {
  const DiagnosticApplyResult(
    this.previewId,
    this.complete,
    this.result,
    this.detail,
  );
  final String previewId, result;
  final String? detail;
  final bool complete;
}

class DiagnosticSupportReport {
  const DiagnosticSupportReport(this.fileName, this.content);
  final String fileName;
  final Uint8List content;
}

abstract interface class DiagnosticsClient {
  Future<DiagnosticSnapshot> check({
    required String workspaceId,
    required String profileId,
    String? fileSnapshotId,
    String? deploymentId,
    int? deploymentRevision,
  });
  Future<DiagnosticPreview> preview(String snapshotId, String problemId);
  Future<DiagnosticApplyResult> apply(String previewId);
  Future<DiagnosticSupportReport> export(String snapshotId);
}

class GrpcDiagnosticsClient implements DiagnosticsClient {
  GrpcDiagnosticsClient(ClientChannel channel, CallOptions options)
    : _client = wire.DiagnosticOperationsClient(channel, options: options);
  final wire.DiagnosticOperationsClient _client;

  Never _reject(
    wire.DiagnosticFault value,
  ) => throw DiagnosticsException(switch (value) {
    wire.DiagnosticFault.DIAGNOSTIC_FAULT_NOT_FOUND => DiagnosticFault.notFound,
    wire.DiagnosticFault.DIAGNOSTIC_FAULT_EXPIRED => DiagnosticFault.expired,
    wire.DiagnosticFault.DIAGNOSTIC_FAULT_STALE => DiagnosticFault.stale,
    wire.DiagnosticFault.DIAGNOSTIC_FAULT_FOREIGN => DiagnosticFault.foreign,
    wire.DiagnosticFault.DIAGNOSTIC_FAULT_NOT_OWNED => DiagnosticFault.notOwned,
    wire.DiagnosticFault.DIAGNOSTIC_FAULT_BUSY => DiagnosticFault.busy,
    wire.DiagnosticFault.DIAGNOSTIC_FAULT_OVERSIZED =>
      DiagnosticFault.oversized,
    wire.DiagnosticFault.DIAGNOSTIC_FAULT_UNSUPPORTED =>
      DiagnosticFault.unsupported,
    wire.DiagnosticFault.DIAGNOSTIC_FAULT_CANCELLED =>
      DiagnosticFault.cancelled,
    wire.DiagnosticFault.DIAGNOSTIC_FAULT_NONE ||
    _ => DiagnosticFault.unsupported,
  });

  DiagnosticSnapshot _snapshot(
    wire.DiagnosticSnapshot value,
  ) => DiagnosticSnapshot(
    value.id,
    value.workspaceId,
    value.profileId,
    DateTime.parse(value.capturedAt),
    List.unmodifiable(
      value.findings.map(
        (finding) => DiagnosticFinding(
          id: finding.id,
          code: finding.code,
          severity: switch (finding.severity) {
            wire.DiagnosticSeverity.DIAGNOSTIC_SEVERITY_INFORMATION =>
              DiagnosticSeverity.information,
            wire.DiagnosticSeverity.DIAGNOSTIC_SEVERITY_WARNING =>
              DiagnosticSeverity.warning,
            wire.DiagnosticSeverity.DIAGNOSTIC_SEVERITY_ERROR =>
              DiagnosticSeverity.error,
            _ => DiagnosticSeverity.error,
          },
          workspaceName: finding.workspaceName,
          profileName: finding.profileName,
          gameName: finding.gameName,
          title: finding.title,
          summary: finding.summary,
          detail: finding.hasDetail() ? finding.detail : null,
          area: finding.area,
          evidence: List.unmodifiable(
            finding.evidence.map(
              (item) => DiagnosticEvidence(item.label, item.value),
            ),
          ),
          nextAction: finding.nextAction,
          fixability: switch (finding.fixability) {
            wire.DiagnosticFixability.DIAGNOSTIC_FIXABILITY_NOT_FIXABLE =>
              DiagnosticFixability.notFixable,
            wire.DiagnosticFixability.DIAGNOSTIC_FIXABILITY_PREVIEW_AVAILABLE =>
              DiagnosticFixability.previewAvailable,
            wire.DiagnosticFixability.DIAGNOSTIC_FIXABILITY_READY =>
              DiagnosticFixability.ready,
            wire.DiagnosticFixability.DIAGNOSTIC_FIXABILITY_REFUSED =>
              DiagnosticFixability.refused,
            _ => DiagnosticFixability.refused,
          },
          fixDetail: finding.fixDetail,
          correlations: List.unmodifiable(
            finding.correlations.map(
              (item) => DiagnosticCorrelation(
                item.kind,
                item.id,
                item.hasRevision() ? item.revision.toInt() : null,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Future<DiagnosticSnapshot> check({
    required String workspaceId,
    required String profileId,
    String? fileSnapshotId,
    String? deploymentId,
    int? deploymentRevision,
  }) async {
    final request = wire.DiagnosticRequest(
      workspaceId: workspaceId,
      profileId: profileId,
    );
    if (fileSnapshotId != null) request.fileSnapshotId = fileSnapshotId;
    if (deploymentId != null) request.deploymentId = deploymentId;
    if (deploymentRevision != null) {
      request.deploymentRevision = Int64(deploymentRevision);
    }
    final reply = await _client.checkDiagnostics(request);
    return switch (reply.whichOutcome()) {
      wire.DiagnosticSnapshotReply_Outcome.snapshot => _snapshot(
        reply.snapshot,
      ),
      wire.DiagnosticSnapshotReply_Outcome.fault => _reject(reply.fault),
      wire.DiagnosticSnapshotReply_Outcome.notSet =>
        throw const FormatException('Diagnostics returned no result.'),
    };
  }

  @override
  Future<DiagnosticPreview> preview(String snapshotId, String problemId) async {
    final reply = await _client.previewDiagnosticChange(
      wire.DiagnosticPreviewRequest(
        snapshotId: snapshotId,
        problemId: problemId,
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.DiagnosticPreviewReply_Outcome.preview => DiagnosticPreview(
        reply.preview.id,
        reply.preview.snapshotId,
        reply.preview.problemId,
        DateTime.parse(reply.preview.expiresAt),
        List.unmodifiable(
          reply.preview.items.map(
            (item) => DiagnosticRemediationItem(item.label, item.value),
          ),
        ),
        List.unmodifiable(
          reply.preview.identifiers.map(
            (item) => DiagnosticRemediationIdentifier(item.label, item.value),
          ),
        ),
        reply.preview.result,
      ),
      wire.DiagnosticPreviewReply_Outcome.fault => _reject(reply.fault),
      wire.DiagnosticPreviewReply_Outcome.notSet => throw const FormatException(
        'Diagnostics returned no preview.',
      ),
    };
  }

  @override
  Future<DiagnosticApplyResult> apply(String previewId) async {
    final reply = await _client.applyDiagnosticChange(
      wire.DiagnosticApplyRequest(previewId: previewId),
    );
    return switch (reply.whichOutcome()) {
      wire.DiagnosticApplyReply_Outcome.result => DiagnosticApplyResult(
        reply.result.previewId,
        reply.result.complete,
        reply.result.result,
        reply.result.hasDetail() ? reply.result.detail : null,
      ),
      wire.DiagnosticApplyReply_Outcome.fault => _reject(reply.fault),
      wire.DiagnosticApplyReply_Outcome.notSet => throw const FormatException(
        'Diagnostics returned no change result.',
      ),
    };
  }

  @override
  Future<DiagnosticSupportReport> export(String snapshotId) async {
    final reply = await _client.exportDiagnosticSupport(
      wire.DiagnosticSnapshotReference(snapshotId: snapshotId),
    );
    return switch (reply.whichOutcome()) {
      wire.DiagnosticSupportReply_Outcome.report => DiagnosticSupportReport(
        reply.report.fileName,
        Uint8List.fromList(reply.report.content),
      ),
      wire.DiagnosticSupportReply_Outcome.fault => _reject(reply.fault),
      wire.DiagnosticSupportReply_Outcome.notSet => throw const FormatException(
        'Diagnostics returned no report.',
      ),
    };
  }
}
