import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/link_setup.pbgrpc.dart' as wire;

enum NexusLinkDefault { unknown, modConductor, anotherApp, none }

class NexusLinkSetupStatus {
  const NexusLinkSetupStatus(
    this.windows,
    this.available,
    this.defaultApp,
    this.changed,
    this.problem,
    this.canRemove,
  );
  final bool windows, changed, canRemove;
  final bool? available;
  final NexusLinkDefault defaultApp;
  final String? problem;
}

class LinkSetupClient {
  LinkSetupClient(ClientChannel channel, CallOptions options)
    : _client = wire.NexusLinkSetupClient(channel, options: options);
  final wire.NexusLinkSetupClient _client;
  Future<NexusLinkSetupStatus> _call(Future<wire.LinkSetupReply> result) async {
    try {
      final v = await result;
      return NexusLinkSetupStatus(
        v.windows,
        v.hasAvailable() ? v.available : null,
        switch (v.defaultApp) {
          wire.LinkDefault.LINK_DEFAULT_MC => NexusLinkDefault.modConductor,
          wire.LinkDefault.LINK_DEFAULT_OTHER => NexusLinkDefault.anotherApp,
          wire.LinkDefault.LINK_DEFAULT_NONE => NexusLinkDefault.none,
          _ => NexusLinkDefault.unknown,
        },
        v.changed,
        v.hasProblem() ? v.problem : null,
        v.canRemove,
      );
    } on GrpcError {
      throw const LinkSetupProblem();
    }
  }

  Future<NexusLinkSetupStatus> read() =>
      _call(_client.readLinkSetup(wire.LinkSetupRequest()));
  Future<NexusLinkSetupStatus> add(String executable) => _call(
    _client.addLinkSetup(wire.AddLinkSetupRequest(executable: executable)),
  );
  Future<NexusLinkSetupStatus> remove() =>
      _call(_client.removeLinkSetup(wire.LinkSetupRequest()));
  Future<NexusLinkSetupStatus> openSettings() =>
      _call(_client.openLinkDefaults(wire.LinkSetupRequest()));
}

class LinkSetupProblem implements Exception {
  const LinkSetupProblem();
}
