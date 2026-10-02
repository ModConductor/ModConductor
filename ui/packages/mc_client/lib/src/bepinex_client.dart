import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/bepinex.pbgrpc.dart' as wire;
import 'file_plan_models.dart';
import 'file_plan_wire.dart' as text;
import 'thunderstore_models.dart';

class BepInExState {
  const BepInExState({
    required this.workspace,
    required this.profile,
    required this.contextRevision,
    required this.selectionRevision,
    required this.package,
    required this.enabled,
    required this.settingsAvailable,
    required this.logAvailable,
    this.mod,
  });
  final String workspace, profile;
  final int contextRevision, selectionRevision;
  final ThunderstoreVersionRef package;
  final String? mod;
  final bool enabled, settingsAvailable, logAvailable;
}

class LoaderText {
  const LoaderText(this.document, this.original);
  final TextDocument document;
  final List<int> original;
}

sealed class LoaderReply<T> {
  const LoaderReply();
}

final class LoaderValue<T> extends LoaderReply<T> {
  const LoaderValue(this.value);
  final T value;
}

final class LoaderProblem<T> extends LoaderReply<T> {
  const LoaderProblem(this.message);
  final String message;
}

abstract interface class BepInExClient {
  Future<LoaderReply<BepInExState>> read(String workspace, String profile);
  Future<LoaderReply<BepInExState>> change(BepInExState state, bool enabled);
  Future<LoaderReply<LoaderText>> settings(String workspace, String profile);
  Future<LoaderReply<LoaderText>> saveSettings(
    String workspace,
    String profile,
    LoaderText original,
    String content,
  );
  Future<LoaderReply<LoaderText>> log(String workspace, String profile);
}

class GrpcBepInExClient implements BepInExClient {
  GrpcBepInExClient(ClientChannel channel, CallOptions options)
    : _client = wire.BepInExClient(channel, options: options);
  final wire.BepInExClient _client;
  wire.LoaderRequest _request(String workspace, String profile) =>
      wire.LoaderRequest(workspaceId: workspace, profileId: profile);
  Future<LoaderReply<T>> _call<T>(
    Future<LoaderReply<T>> Function() call,
  ) async {
    try {
      return await call();
    } on GrpcError catch (error) {
      return LoaderProblem(
        error.message ?? 'The loader request did not complete.',
      );
    }
  }

  LoaderReply<BepInExState> _state(wire.LoaderReply reply) {
    if (reply.hasProblem()) return LoaderProblem(reply.problem);
    final state = reply.loader;
    final package = state.package;
    return LoaderValue(
      BepInExState(
        workspace: state.workspaceId,
        profile: state.profileId,
        contextRevision: state.contextRevision.toInt(),
        selectionRevision: state.selectionRevision.toInt(),
        package: ThunderstoreVersionRef(
          ThunderstorePackageRef(
            package.package.community,
            package.package.namespace,
            package.package.name,
          ),
          package.version,
        ),
        mod: state.hasModId() ? state.modId : null,
        enabled: state.enabled,
        settingsAvailable: state.settingsAvailable,
        logAvailable: state.logAvailable,
      ),
    );
  }

  LoaderReply<LoaderText> _text(wire.LoaderTextReply reply) =>
      reply.hasProblem()
      ? LoaderProblem(reply.problem)
      : LoaderValue(
          LoaderText(
            text.textDocument(reply.text.document),
            List.unmodifiable(reply.text.original),
          ),
        );
  @override
  Future<LoaderReply<BepInExState>> read(String workspace, String profile) =>
      _call(
        () async =>
            _state(await _client.readLoader(_request(workspace, profile))),
      );
  @override
  Future<LoaderReply<BepInExState>> change(BepInExState state, bool enabled) =>
      _call(
        () async => _state(
          await _client.changeLoader(
            wire.ChangeLoaderRequest(
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
  Future<LoaderReply<LoaderText>> settings(String workspace, String profile) =>
      _call(
        () async => _text(
          await _client.readLoaderSettings(_request(workspace, profile)),
        ),
      );
  @override
  Future<LoaderReply<LoaderText>> saveSettings(
    String workspace,
    String profile,
    LoaderText original,
    String content,
  ) => _call(
    () async => _text(
      await _client.saveLoaderSettings(
        wire.SaveLoaderSettingsRequest(
          workspaceId: workspace,
          profileId: profile,
          original: original.original,
          content: content,
        ),
      ),
    ),
  );
  @override
  Future<LoaderReply<LoaderText>> log(String workspace, String profile) =>
      _call(
        () async =>
            _text(await _client.readLoaderLog(_request(workspace, profile))),
      );
}
