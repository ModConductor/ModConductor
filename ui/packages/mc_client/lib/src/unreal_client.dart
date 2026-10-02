import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'bepinex_client.dart';
import 'file_plan_wire.dart' as text;
import 'generated/modconductor/v1/bepinex.pb.dart' as shared;
import 'generated/modconductor/v1/unreal.pbgrpc.dart' as wire;

class UnrealLoaderState {
  const UnrealLoaderState({
    required this.workspace,
    required this.profile,
    required this.contextRevision,
    required this.selectionRevision,
    required this.id,
    required this.name,
    required this.version,
    required this.iconUrl,
    required this.iconHeaders,
    required this.enabled,
    required this.archiveRequired,
    required this.settingsFiles,
    required this.logAvailable,
    this.subtitle,
    this.mod,
    this.declaredVersion = '',
    this.declaredVersionLabel = '',
    this.declaredSource = '',
    this.upstreamLicense = '',
    this.upstreamCommit,
  });
  final String workspace, profile, id, name, version, iconUrl;
  final String? subtitle, mod;
  final String declaredVersion,
      declaredVersionLabel,
      declaredSource,
      upstreamLicense;
  final String? upstreamCommit;
  final Map<String, String> iconHeaders;
  final int contextRevision, selectionRevision;
  final bool enabled, archiveRequired, logAvailable;
  final List<String> settingsFiles;
}

class UnrealProgress {
  const UnrealProgress(
    this.stage,
    this.bytes,
    this.total,
    this.mod,
    this.problem,
    this.state,
  );
  final String stage;
  final int bytes;
  final int? total;
  final String? mod, problem;
  final UnrealLoaderState? state;
}

abstract interface class UnrealClient {
  Future<LoaderReply<UnrealLoaderState>> read(String workspace, String profile);
  Future<LoaderReply<UnrealLoaderState>> change(
    UnrealLoaderState state,
    bool enabled,
  );
  Stream<UnrealProgress> acquire(UnrealLoaderState state, String? archive);
  Future<LoaderReply<LoaderText>> settings(
    UnrealLoaderState state,
    String name,
  );
  Future<LoaderReply<LoaderText>> save(
    UnrealLoaderState state,
    String name,
    LoaderText original,
    String content,
  );
  Future<LoaderReply<LoaderText>> log(UnrealLoaderState state);
  Future<String?> openPage(UnrealLoaderState state);
}

class GrpcUnrealClient implements UnrealClient {
  GrpcUnrealClient(ClientChannel channel, CallOptions options)
    : _client = wire.UnrealClient(channel, options: options);
  final wire.UnrealClient _client;

  UnrealLoaderState _state(wire.UnrealLoaderInfo value) => UnrealLoaderState(
    workspace: value.workspaceId,
    profile: value.profileId,
    contextRevision: value.contextRevision.toInt(),
    selectionRevision: value.selectionRevision.toInt(),
    id: value.loaderId,
    name: value.name,
    version: value.version,
    iconUrl: value.iconUrl,
    iconHeaders: Map.unmodifiable(value.iconHeaders),
    enabled: value.enabled,
    archiveRequired: value.archiveRequired,
    settingsFiles: List.unmodifiable(value.settingsFiles),
    logAvailable: value.logAvailable,
    subtitle: value.hasSubtitle() ? value.subtitle : null,
    mod: value.hasModId() ? value.modId : null,
    declaredVersion: value.declaredVersion,
    declaredVersionLabel: value.declaredVersionLabel,
    declaredSource: value.declaredSource,
    upstreamLicense: value.upstreamLicense,
    upstreamCommit: value.hasUpstreamCommit() ? value.upstreamCommit : null,
  );
  LoaderReply<UnrealLoaderState> _reply(wire.UnrealLoaderReply value) =>
      value.hasProblem()
      ? LoaderProblem(value.problem)
      : LoaderValue(_state(value.loader));
  LoaderReply<LoaderText> _text(shared.LoaderTextReply value) =>
      value.hasProblem()
      ? LoaderProblem(value.problem)
      : LoaderValue(
          LoaderText(
            text.textDocument(value.text.document),
            List.unmodifiable(value.text.original),
          ),
        );
  Future<LoaderReply<T>> _call<T>(
    Future<LoaderReply<T>> Function() action,
  ) async {
    try {
      return await action();
    } on GrpcError catch (error) {
      return LoaderProblem(
        error.message ?? 'The loader request did not complete.',
      );
    }
  }

  shared.LoaderRequest _request(UnrealLoaderState state) =>
      shared.LoaderRequest(
        workspaceId: state.workspace,
        profileId: state.profile,
      );
  @override
  Future<LoaderReply<UnrealLoaderState>> read(
    String workspace,
    String profile,
  ) => _call(
    () async => _reply(
      await _client.readUnrealLoader(
        shared.LoaderRequest(workspaceId: workspace, profileId: profile),
      ),
    ),
  );
  @override
  Future<LoaderReply<UnrealLoaderState>> change(
    UnrealLoaderState state,
    bool enabled,
  ) => _call(
    () async => _reply(
      await _client.changeUnrealLoader(
        shared.ChangeLoaderRequest(
          workspaceId: state.workspace,
          profileId: state.profile,
          contextRevision: Int64(state.contextRevision),
          selectionRevision: Int64(state.selectionRevision),
          enabled: enabled,
        ),
      ),
    ),
  );
  @override
  Stream<UnrealProgress> acquire(
    UnrealLoaderState state,
    String? archive,
  ) async* {
    final call = _client.acquireUnrealLoader(
      wire.AcquireUnrealLoaderRequest(
        workspaceId: state.workspace,
        profileId: state.profile,
        contextRevision: Int64(state.contextRevision),
        archivePath: archive,
      ),
    );
    try {
      await for (final value in call) {
        yield UnrealProgress(
          value.stage,
          value.bytes.toInt(),
          value.hasTotal() ? value.total.toInt() : null,
          value.hasModId() ? value.modId : null,
          value.hasProblem() ? value.problem : null,
          value.hasLoader() ? _state(value.loader) : null,
        );
      }
    } on GrpcError catch (error) {
      yield UnrealProgress(
        'stopped',
        0,
        null,
        null,
        error.message ?? 'The loader acquisition stopped.',
        null,
      );
    } finally {
      await call.cancel();
    }
  }

  @override
  Future<LoaderReply<LoaderText>> settings(
    UnrealLoaderState state,
    String name,
  ) => _call(
    () async => _text(
      await _client.readUnrealText(
        wire.UnrealTextRequest(
          workspaceId: state.workspace,
          profileId: state.profile,
          name: name,
        ),
      ),
    ),
  );
  @override
  Future<LoaderReply<LoaderText>> save(
    UnrealLoaderState state,
    String name,
    LoaderText original,
    String content,
  ) => _call(
    () async => _text(
      await _client.saveUnrealText(
        wire.SaveUnrealTextRequest(
          workspaceId: state.workspace,
          profileId: state.profile,
          name: name,
          original: original.original,
          content: content,
        ),
      ),
    ),
  );
  @override
  Future<LoaderReply<LoaderText>> log(UnrealLoaderState state) => _call(
    () async => _text(
      await _client.readUnrealText(
        wire.UnrealTextRequest(
          workspaceId: state.workspace,
          profileId: state.profile,
          log: true,
        ),
      ),
    ),
  );
  @override
  Future<String?> openPage(UnrealLoaderState state) async {
    try {
      final value = await _client.openUnrealLoaderPage(_request(state));
      return value.problem.isEmpty ? null : value.problem;
    } on GrpcError catch (error) {
      return error.message ?? 'The loader page could not open.';
    }
  }
}
