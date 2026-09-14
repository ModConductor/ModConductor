import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'bethesda_client.dart';
import 'profile_data_models.dart';
import 'profile_data_client.dart' show decodeProfileDataProblem;
import 'generated/modconductor/v1/plugin_order.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/profile_data.pb.dart' as profile;
import 'generated/modconductor/v1/bethesda_plugins.pb.dart' as headers;

class PluginSetting {
  const PluginSetting(this.name, this.enabled, this.lockedIndex, this.required);
  final String name;
  final bool? enabled;
  final int? lockedIndex;
  final bool required;
}

class PluginOrderIssue {
  const PluginOrderIssue(this.name, this.detail);
  final String name, detail;
}

class ProfilePluginOrder {
  const ProfilePluginOrder(
    this.reference,
    this.headers,
    this.entries,
    this.unknown,
    this.issues,
    this.full,
    this.light,
    this.fullLimit,
    this.saved,
    this.applied,
    this.externalChanged,
    this.pending,
    this.problem,
  );
  final ProfileDataRef reference;
  final PluginSnapshot headers;
  final List<PluginSetting> entries, unknown;
  final List<PluginOrderIssue> issues;
  final int full, light, fullLimit;
  final bool saved, applied, externalChanged, pending;
  final String problem;
}

enum PluginOrderAction { enable, disable, up, down, lock, unlock }

abstract interface class PluginOrderClient {
  Future<ProfilePluginOrder> read(
    String workspace,
    String profile,
    String headers,
  );
  Future<ProfilePluginOrder> change(
    ProfileDataRef expected,
    String headers,
    List<String> names,
    PluginOrderAction action,
  );
  Future<ProfilePluginOrder> useGameOrder(
    ProfileDataRef expected,
    String headers,
  );
}

class GrpcPluginOrderClient implements PluginOrderClient {
  GrpcPluginOrderClient(ClientChannel channel, CallOptions options)
    : _client = wire.PluginOrdersClient(channel, options: options);
  final wire.PluginOrdersClient _client;
  static profile.ProfileDataRef _ref(ProfileDataRef value) =>
      profile.ProfileDataRef(
        workspaceId: value.workspaceId,
        profileId: value.profileId,
        contextId: value.contextId,
        revision: Int64(value.revision),
      );
  @override
  Future<ProfilePluginOrder> read(
    String workspace,
    String profile,
    String headers,
  ) async => decode(
    await _client.readPluginOrder(
      wire.ReadPluginOrderRequest(
        workspaceId: workspace,
        profileId: profile,
        headersId: headers,
      ),
    ),
  );
  @override
  Future<ProfilePluginOrder> change(
    ProfileDataRef expected,
    String headers,
    List<String> names,
    PluginOrderAction action,
  ) async {
    final request = wire.ChangePluginOrderRequest(
      expected: _ref(expected),
      headersId: headers,
      names: names,
    );
    switch (action) {
      case PluginOrderAction.enable:
        request.enabled = true;
      case PluginOrderAction.disable:
        request.enabled = false;
      case PluginOrderAction.up:
        request.moveUp = true;
      case PluginOrderAction.down:
        request.moveUp = false;
      case PluginOrderAction.lock:
        request.locked = true;
      case PluginOrderAction.unlock:
        request.locked = false;
    }
    return decode(await _client.changePluginOrder(request));
  }

  @override
  Future<ProfilePluginOrder> useGameOrder(
    ProfileDataRef expected,
    String headers,
  ) async => decode(
    await _client.useGamePluginOrder(
      wire.UseGamePluginOrderRequest(
        expected: _ref(expected),
        headersId: headers,
      ),
    ),
  );
  static ProfilePluginOrder decode(wire.PluginOrderReply reply) {
    switch (reply.whichOutcome()) {
      case wire.PluginOrderReply_Outcome.problem:
        throw decodeProfileDataProblem(reply.problem);
      case wire.PluginOrderReply_Outcome.notSet:
        throw const FormatException('The plugin order response is missing.');
      case wire.PluginOrderReply_Outcome.order:
        final value = reply.order, reference = value.reference;
        return ProfilePluginOrder(
          ProfileDataRef(
            workspaceId: reference.workspaceId,
            profileId: reference.profileId,
            contextId: reference.contextId,
            revision: reference.revision.toInt(),
          ),
          GrpcBethesdaClient.decode(
            headers.BethesdaPluginsReply(snapshot: value.headers),
          ),
          List.unmodifiable(
            value.entries.map(
              (entry) => PluginSetting(
                entry.name,
                entry.hasEnabled() ? entry.enabled : null,
                entry.hasLockedIndex() ? entry.lockedIndex : null,
                entry.required,
              ),
            ),
          ),
          List.unmodifiable(
            value.unknown.map(
              (entry) => PluginSetting(entry.name, entry.enabled, null, false),
            ),
          ),
          List.unmodifiable(
            value.issues.map(
              (issue) => PluginOrderIssue(issue.name, issue.detail),
            ),
          ),
          value.full,
          value.light,
          value.fullLimit,
          value.saved,
          value.applied,
          value.externalChanged,
          value.pending,
          value.pendingProblem,
        );
    }
  }
}
