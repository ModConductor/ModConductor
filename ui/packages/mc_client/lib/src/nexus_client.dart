import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'artifact_client.dart';
import 'generated/modconductor/v1/nexus.pbgrpc.dart' as wire;

class NexusProblem implements Exception {
  const NexusProblem(this.code, this.message, [this.retryAt]);
  final String code, message;
  final DateTime? retryAt;
  @override
  String toString() => message;
}

class NexusAccount {
  const NexusAccount(
    this.configured,
    this.waiting,
    this.name,
    this.premium,
    this.problem, [
    this.profileImage,
  ]);
  final bool configured, waiting;
  final String? name;
  final bool? premium;
  final NexusProblem? problem;
  final Uri? profileImage;
}

class NexusFile {
  const NexusFile(
    this.id,
    this.name,
    this.version,
    this.category,
    this.description,
    this.bytes,
  );
  final int id;
  final String name, version, category, description;
  final int? bytes;
}

class NexusMod {
  const NexusMod(
    this.id,
    this.name,
    this.summary,
    this.files, {
    this.author = '',
    this.category = '',
    this.picture,
  });
  final int id;
  final String name, summary;
  final List<NexusFile> files;
  final String author, category;
  final Uri? picture;
}

class NexusDiscoveryMod {
  const NexusDiscoveryMod(
    this.id,
    this.name,
    this.summary,
    this.author,
    this.category,
    this.picture,
  );
  final int id;
  final String name, summary, author, category;
  final Uri? picture;
}

abstract interface class NexusClient {
  Future<NexusAccount> status();
  Stream<NexusAccount> watchStatus();
  Future<NexusAccount> signIn();
  Future<NexusAccount> cancel();
  Future<NexusAccount> connect();
  Future<NexusAccount> check();
  Future<NexusAccount> submitPersonalApiKey(String apiKey);
  Future<NexusMod> mod(String workspace, String profile, int id);
  Future<Artifact> download(
    String workspace,
    String profile,
    String artifactId,
    int modId,
    int fileId,
  );
  Future<void> openPage(String workspace, String profile, int modId);
  Future<List<NexusDiscoveryMod>> discovery(
    String workspace,
    String profile,
    String feed,
  );
  Future<void> openSearch(String workspace, String profile);
}

class GrpcNexusClient implements NexusClient {
  GrpcNexusClient(ClientChannel channel, CallOptions options)
    : _client = wire.NexusClient(channel, options: options);
  final wire.NexusClient _client;
  NexusProblem _problem(wire.NexusFailure value) => NexusProblem(
    value.code,
    value.message,
    value.hasRetryAtUnixMs()
        ? DateTime.fromMillisecondsSinceEpoch(value.retryAtUnixMs.toInt())
        : null,
  );
  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on NexusProblem {
      rethrow;
    } catch (_) {
      throw const NexusProblem(
        'connection',
        'The engine connection could not complete the Nexus request.',
      );
    }
  }

  Future<NexusAccount> _account(
    Future<wire.NexusAccountStatus> Function() action,
  ) => _call(() async {
    final v = await action();
    return NexusAccount(
      v.configured,
      v.waiting,
      v.hasAccountName() ? v.accountName : null,
      v.hasPremium() ? v.premium : null,
      v.hasFailure() ? _problem(v.failure) : null,
      v.hasProfileImageUrl() ? Uri.tryParse(v.profileImageUrl) : null,
    );
  });
  @override
  Future<NexusAccount> status() =>
      _account(() => _client.readNexusStatus(wire.NexusStatusRequest()));
  @override
  Stream<NexusAccount> watchStatus() => _client
      .watchNexusStatus(wire.NexusStatusRequest())
      .asyncMap(
        (value) async => NexusAccount(
          value.configured,
          value.waiting,
          value.hasAccountName() ? value.accountName : null,
          value.hasPremium() ? value.premium : null,
          value.hasFailure() ? _problem(value.failure) : null,
          value.hasProfileImageUrl()
              ? Uri.tryParse(value.profileImageUrl)
              : null,
        ),
      );
  @override
  Future<NexusAccount> signIn() =>
      _account(() => _client.beginNexusSignIn(wire.NexusStatusRequest()));
  @override
  Future<NexusAccount> cancel() =>
      _account(() => _client.cancelNexusSignIn(wire.NexusStatusRequest()));
  @override
  Future<NexusAccount> connect() =>
      _account(() => _client.connectNexus(wire.NexusStatusRequest()));
  @override
  Future<NexusAccount> check() =>
      _account(() => _client.checkNexusAccount(wire.NexusStatusRequest()));
  @override
  Future<NexusAccount> submitPersonalApiKey(String apiKey) => _account(
    () => _client.submitNexusPersonalApiKey(
      wire.NexusPersonalApiKeyRequest(apiKey: apiKey),
    ),
  );
  @override
  Future<NexusMod> mod(String workspace, String profile, int id) =>
      _call(() async {
        final reply = await _client.readNexusMod(
          wire.NexusModRequest(
            workspaceId: workspace,
            profileId: profile,
            modId: Int64(id),
          ),
        );
        if (reply.hasFailure()) throw _problem(reply.failure);
        if (!reply.hasMod()) {
          throw const NexusProblem(
            'response',
            'The engine returned an incomplete Nexus response.',
          );
        }
        final v = reply.mod;
        return NexusMod(
          v.id.toInt(),
          v.name,
          v.summary,
          [
            for (final f in v.files)
              NexusFile(
                f.id.toInt(),
                f.name,
                f.version,
                f.category,
                f.description,
                f.hasBytes() ? f.bytes.toInt() : null,
              ),
          ],
          author: v.author,
          category: v.category,
          picture: v.hasPictureUrl() ? Uri.tryParse(v.pictureUrl) : null,
        );
      });
  @override
  Future<Artifact> download(
    String workspace,
    String profile,
    String artifactId,
    int modId,
    int fileId,
  ) => _call(() async {
    final reply = await _client.downloadNexusFile(
      wire.NexusDownloadRequest(
        workspaceId: workspace,
        profileId: profile,
        artifactId: artifactId,
        modId: Int64(modId),
        fileId: Int64(fileId),
      ),
    );
    if (reply.hasFailure()) throw _problem(reply.failure);
    if (!reply.hasArtifact()) {
      throw const NexusProblem(
        'response',
        'The engine returned an incomplete download response.',
      );
    }
    return GrpcArtifactsClient.decode(reply.artifact);
  });
  @override
  Future<void> openPage(String workspace, String profile, int modId) =>
      _call(() async {
        await _client.openNexusModPage(
          wire.NexusModRequest(
            workspaceId: workspace,
            profileId: profile,
            modId: Int64(modId),
          ),
        );
      });

  @override
  Future<List<NexusDiscoveryMod>> discovery(
    String workspace,
    String profile,
    String feed,
  ) => _call(() async {
    final reply = await _client.readNexusDiscovery(
      wire.NexusDiscoveryRequest(
        workspaceId: workspace,
        profileId: profile,
        feed: feed,
      ),
    );
    if (reply.hasFailure()) throw _problem(reply.failure);
    if (!reply.hasCards()) {
      throw const NexusProblem('response', 'The Nexus feed is incomplete.');
    }
    return List.unmodifiable(
      reply.cards.mods.map(
        (mod) => NexusDiscoveryMod(
          mod.id.toInt(),
          mod.name,
          mod.summary,
          mod.author,
          mod.category,
          mod.hasPictureUrl() ? Uri.tryParse(mod.pictureUrl) : null,
        ),
      ),
    );
  });

  @override
  Future<void> openSearch(String workspace, String profile) => _call(() async {
    await _client.openNexusSearch(
      wire.NexusDiscoveryRequest(workspaceId: workspace, profileId: profile),
    );
  });
}
