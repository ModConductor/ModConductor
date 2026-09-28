import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/desktop.pbgrpc.dart' as wire;

enum DesktopIntentKind { show, workspace, archive, archives, profile }

class DesktopIntent {
  const DesktopIntent(this.kind, this.path, this.workspaceId, this.length);
  final DesktopIntentKind kind;
  final String path, workspaceId;
  final int length;
}

class DesktopProblem implements Exception {
  const DesktopProblem(this.detail);
  final String detail;
}

abstract interface class DesktopClient {
  Future<DesktopIntent> resolve(List<String> arguments);
}

class GrpcDesktopClient implements DesktopClient {
  GrpcDesktopClient(ClientChannel channel, CallOptions options)
    : _client = wire.DesktopOperationsClient(channel, options: options);
  final wire.DesktopOperationsClient _client;
  @override
  Future<DesktopIntent> resolve(List<String> arguments) async {
    try {
      final reply = await _client.resolveDesktopRequest(
        wire.ResolveDesktopRequestMessage(arguments: arguments),
      );
      if (reply.hasProblem()) throw DesktopProblem(reply.problem);
      if (!reply.hasIntent()) {
        throw const DesktopProblem('This request could not be checked.');
      }
      final value = reply.intent;
      final kind = switch (value.kind) {
        wire.DesktopIntentKind.DESKTOP_INTENT_KIND_SHOW =>
          DesktopIntentKind.show,
        wire.DesktopIntentKind.DESKTOP_INTENT_KIND_WORKSPACE =>
          DesktopIntentKind.workspace,
        wire.DesktopIntentKind.DESKTOP_INTENT_KIND_ARCHIVE =>
          DesktopIntentKind.archive,
        wire.DesktopIntentKind.DESKTOP_INTENT_KIND_ARCHIVES =>
          DesktopIntentKind.archives,
        wire.DesktopIntentKind.DESKTOP_INTENT_KIND_PROFILE =>
          DesktopIntentKind.profile,
        _ => throw const DesktopProblem('This request is not supported.'),
      };
      return DesktopIntent(
        kind,
        value.path,
        value.workspaceId,
        value.length.toInt(),
      );
    } on GrpcError {
      throw const DesktopProblem(
        'This request could not be checked. Check the engine connection.',
      );
    }
  }
}
