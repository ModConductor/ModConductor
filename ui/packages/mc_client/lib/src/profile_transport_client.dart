import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/profile_transport.pbgrpc.dart' as wire;

class ProfileSourceRequirement {
  const ProfileSourceRequirement(
    this.index,
    this.modName,
    this.archiveName,
    this.sha256,
    this.length,
    this.provider,
  );
  final int index;
  final String modName, archiveName, sha256;
  final int length;
  final String? provider;
}

class ProfileTransportPreview {
  const ProfileTransportPreview(
    this.name,
    this.game,
    this.modCount,
    this.modFileCount,
    this.saveFileCount,
    this.saveBytes,
    this.sources,
  );
  final String name, game;
  final int modCount, modFileCount, saveFileCount, saveBytes;
  final List<ProfileSourceRequirement> sources;

  String get gameName =>
      game == 'skyrim-se-steam' ? 'Skyrim Special Edition' : game;
}

class ProfileTransportException implements Exception {
  const ProfileTransportException(this.detail);
  final String detail;
}

abstract interface class ProfileTransportClient {
  Future<ProfileTransportPreview> inspect(String path);
  Future<ProfileTransportPreview> previewExport(
    String workspace,
    String profile,
  );
  Future<void> export(
    String workspace,
    String profile,
    String destination, {
    required bool includeSaves,
  });
  Future<String> import(
    String path,
    String workspace,
    String gameProfile,
    String name, {
    Map<int, String> manualSources,
  });
}

class GrpcProfileTransportClient implements ProfileTransportClient {
  GrpcProfileTransportClient(ClientChannel channel, CallOptions options)
    : _client = wire.ProfileTransportOperationsClient(
        channel,
        options: CallOptions(metadata: options.metadata),
      );

  final wire.ProfileTransportOperationsClient _client;

  ProfileTransportPreview _preview(wire.ProfileTransportPreview value) =>
      ProfileTransportPreview(
        value.name,
        value.game,
        value.modCount,
        value.modFileCount,
        value.saveFileCount,
        value.saveBytes.toInt(),
        [
          for (final source in value.sources)
            ProfileSourceRequirement(
              source.modIndex,
              source.modName,
              source.archiveName,
              source.sha256,
              source.length.toInt(),
              source.hasProviderGame() ? source.providerGame : null,
            ),
        ],
      );

  @override
  Future<ProfileTransportPreview> inspect(String path) async {
    try {
      final value = await _client.inspectProfileTransport(
        wire.InspectProfileTransportRequest(path: path),
      );
      return _preview(value);
    } on GrpcError catch (error) {
      throw ProfileTransportException(
        error.message ?? 'The profile file could not be read.',
      );
    }
  }

  @override
  Future<ProfileTransportPreview> previewExport(
    String workspace,
    String profile,
  ) async {
    try {
      final value = await _client.previewExportProfileTransport(
        wire.PreviewExportProfileTransportRequest(
          workspaceId: workspace,
          profileId: profile,
        ),
      );
      return _preview(value);
    } on GrpcError catch (error) {
      throw ProfileTransportException(
        error.message ?? 'The profile could not be read.',
      );
    }
  }

  @override
  Future<void> export(
    String workspace,
    String profile,
    String destination, {
    required bool includeSaves,
  }) async {
    try {
      final value = await _client.exportProfileTransport(
        wire.ExportProfileTransportRequest(
          workspaceId: workspace,
          profileId: profile,
          destination: destination,
          includeSaves: includeSaves,
        ),
      );
      if (value.hasProblem()) throw ProfileTransportException(value.problem);
    } on GrpcError catch (error) {
      throw ProfileTransportException(
        error.message ?? 'The profile could not be exported.',
      );
    }
  }

  @override
  Future<String> import(
    String path,
    String workspace,
    String gameProfile,
    String name, {
    Map<int, String> manualSources = const {},
  }) async {
    try {
      final value = await _client.importProfileTransport(
        wire.ImportProfileTransportRequest(
          path: path,
          workspaceId: workspace,
          gameProfileId: gameProfile,
          profileName: name,
          manualSources: [
            for (final entry in manualSources.entries)
              wire.ManualProfileSource(modIndex: entry.key, path: entry.value),
          ],
        ),
      );
      if (value.hasProblem()) throw ProfileTransportException(value.problem);
      if (!value.hasProfileId()) {
        throw const ProfileTransportException(
          'The imported profile is unavailable.',
        );
      }
      return value.profileId;
    } on GrpcError catch (error) {
      throw ProfileTransportException(
        error.message ?? 'The profile could not be imported.',
      );
    }
  }
}
