import 'dart:typed_data';

import 'package:grpc/grpc.dart';

import 'artifact_client.dart';
import 'nexus_client.dart';
import 'generated/modconductor/v1/nxm.pbgrpc.dart' as wire;

class NexusIngress {
  const NexusIngress(this.endpoint, this.capability, this.processId);
  final String endpoint;
  final Uint8List capability;
  final int processId;
}

class NexusLink {
  const NexusLink(
    this.game,
    this.file,
    this.problem,
    this.signInRequired,
    this.artifact,
    this.detail,
  );
  final String game;
  final NexusFile? file;
  final String? problem;
  final String detail;
  final bool signInRequired;
  final Artifact? artifact;
}

class NxmClient {
  NxmClient(ClientChannel channel, CallOptions options)
    : _client = wire.NexusLinksClient(channel, options: options);
  final wire.NexusLinksClient _client;
  Future<NexusIngress> configure(int processId) async {
    try {
      final value = await _client.configureNexusIngress(
        wire.NexusIngressRequest(processId: processId),
      );
      return NexusIngress(
        value.endpoint,
        Uint8List.fromList(value.capability),
        value.processId,
      );
    } on GrpcError {
      throw const DesktopNexusProblem(
        'The Nexus link connection is unavailable.',
      );
    }
  }

  Future<NexusLink> read(
    String reference,
    String? workspace, {
    String? profile,
    bool download = false,
  }) async {
    try {
      final request = wire.NexusLinkRequest(
        reference: reference,
        workspaceId: workspace,
        profileId: profile,
      );
      final value = await (download
          ? _client.downloadNexusLink(request)
          : _client.readNexusLink(request));
      final f = value.file;
      return NexusLink(
        value.game,
        value.hasFile()
            ? NexusFile(
                f.id.toInt(),
                f.name,
                f.version,
                f.category,
                f.description,
                f.hasBytes() ? f.bytes.toInt() : null,
              )
            : null,
        value.problem.isEmpty ? null : value.problem,
        value.signInRequired,
        value.hasArtifact() ? GrpcArtifactsClient.decode(value.artifact) : null,
        value.problemDetail,
      );
    } on GrpcError {
      throw const DesktopNexusProblem(
        'This Nexus request could not be checked. Check the engine connection.',
      );
    }
  }

  Future<void> dismiss(String reference) async {
    try {
      await _client.dismissNexusLink(
        wire.NexusLinkRequest(reference: reference),
      );
    } on GrpcError {
      throw const DesktopNexusProblem(
        'The Nexus request could not be dismissed.',
      );
    }
  }
}

class DesktopNexusProblem implements Exception {
  const DesktopNexusProblem(this.message);
  final String message;
}
