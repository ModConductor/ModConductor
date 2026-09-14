import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/loot_sort.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/profile_data.pb.dart' as profile;
import 'plugin_order_client.dart';
import 'profile_data_models.dart';

class LootMetadataView {
  const LootMetadataView(
    this.revision,
    this.masterlistCommit,
    this.preludeCommit,
    this.masterlistSha256,
    this.preludeSha256,
    this.fetchedAt,
  );
  final String revision, masterlistCommit, preludeCommit;
  final String masterlistSha256, preludeSha256;
  final DateTime fetchedAt;
}

class LootMoveView {
  const LootMoveView(this.plugin, this.current, this.proposed, this.reason);
  final String plugin, reason;
  final int current, proposed;
}

class LootMessageView {
  const LootMessageView(this.plugin, this.level, this.text);
  final String plugin, level, text;
}

class LootProposalView {
  const LootProposalView(
    this.id,
    this.expected,
    this.headersId,
    this.createdAt,
    this.current,
    this.sorted,
    this.moves,
    this.messages,
    this.metadata,
    this.helperVersion,
    this.liblootVersion,
    this.liblootRevision,
  );
  final String id, headersId, helperVersion, liblootVersion, liblootRevision;
  final ProfileDataRef expected;
  final DateTime createdAt;
  final List<String> current, sorted;
  final List<LootMoveView> moves;
  final List<LootMessageView> messages;
  final LootMetadataView metadata;
}

class LootStateView {
  const LootStateView(
    this.capabilityId,
    this.available,
    this.reason,
    this.metadata,
    this.proposal,
  );
  final String capabilityId, reason;
  final bool available;
  final LootMetadataView? metadata;
  final LootProposalView? proposal;
}

enum LootFailureKind {
  busy,
  stale,
  cancelled,
  unsupported,
  metadata,
  helper,
  response,
}

class LootFailure implements Exception {
  const LootFailure(this.kind, this.detail);
  final LootFailureKind kind;
  final String detail;
}

abstract interface class LootClient {
  Future<LootStateView> read();
  Future<LootStateView> preview(
    String workspace,
    String profile,
    String headers,
  );
  Future<ProfilePluginOrder> apply(
    String proposal,
    ProfileDataRef expected,
    String headers,
  );
  Future<LootStateView> dismiss(String proposal);
  Future<LootStateView> refreshMetadata();
}

class GrpcLootClient implements LootClient {
  GrpcLootClient(ClientChannel channel, CallOptions options)
    : _client = wire.LootSortingClient(channel, options: options);
  final wire.LootSortingClient _client;

  static profile.ProfileDataRef _ref(ProfileDataRef value) =>
      profile.ProfileDataRef(
        workspaceId: value.workspaceId,
        profileId: value.profileId,
        contextId: value.contextId,
        revision: Int64(value.revision),
      );

  @override
  Future<LootStateView> read() async =>
      _decode(await _client.readLootState(wire.ReadLootStateRequest()));
  @override
  Future<LootStateView> preview(
    String workspace,
    String profile,
    String headers,
  ) async => _decode(
    await _client.previewLootSort(
      wire.PreviewLootSortRequest(
        workspaceId: workspace,
        profileId: profile,
        headersId: headers,
      ),
    ),
  );
  @override
  Future<ProfilePluginOrder> apply(
    String proposal,
    ProfileDataRef expected,
    String headers,
  ) async => GrpcPluginOrderClient.decode(
    await _client.applyLootSort(
      wire.ApplyLootSortRequest(
        proposalId: proposal,
        expected: _ref(expected),
        headersId: headers,
      ),
    ),
  );
  @override
  Future<LootStateView> dismiss(String proposal) async => _decode(
    await _client.dismissLootSort(
      wire.DismissLootSortRequest(proposalId: proposal),
    ),
  );
  @override
  Future<LootStateView> refreshMetadata() async => _decode(
    await _client.refreshLootMetadata(wire.RefreshLootMetadataRequest()),
  );

  static LootMetadataView _metadata(wire.LootMetadataState value) =>
      LootMetadataView(
        value.revision,
        value.masterlistCommit,
        value.preludeCommit,
        value.masterlistSha256,
        value.preludeSha256,
        DateTime.fromMillisecondsSinceEpoch(value.fetchedUnixMs.toInt()),
      );

  static LootStateView _decode(wire.LootStateReply reply) {
    if (reply.whichOutcome() == wire.LootStateReply_Outcome.problem) {
      final problem = reply.problem;
      throw LootFailure(switch (problem.kind) {
        wire.LootProblemKind.LOOT_PROBLEM_KIND_BUSY => LootFailureKind.busy,
        wire.LootProblemKind.LOOT_PROBLEM_KIND_STALE => LootFailureKind.stale,
        wire.LootProblemKind.LOOT_PROBLEM_KIND_CANCELLED =>
          LootFailureKind.cancelled,
        wire.LootProblemKind.LOOT_PROBLEM_KIND_UNSUPPORTED =>
          LootFailureKind.unsupported,
        wire.LootProblemKind.LOOT_PROBLEM_KIND_METADATA =>
          LootFailureKind.metadata,
        wire.LootProblemKind.LOOT_PROBLEM_KIND_HELPER => LootFailureKind.helper,
        wire.LootProblemKind.LOOT_PROBLEM_KIND_RESPONSE =>
          LootFailureKind.response,
        _ => LootFailureKind.response,
      }, problem.detail);
    }
    if (reply.whichOutcome() != wire.LootStateReply_Outcome.state) {
      throw const FormatException('The LOOT response is missing.');
    }
    final state = reply.state;
    LootProposalView? proposal;
    if (state.hasProposal()) {
      final value = state.proposal, expected = value.expected;
      proposal = LootProposalView(
        value.id,
        ProfileDataRef(
          workspaceId: expected.workspaceId,
          profileId: expected.profileId,
          contextId: expected.contextId,
          revision: expected.revision.toInt(),
        ),
        value.headersId,
        DateTime.fromMillisecondsSinceEpoch(value.createdUnixMs.toInt()),
        List.unmodifiable(value.current),
        List.unmodifiable(value.sorted),
        List.unmodifiable(
          value.moves.map(
            (move) => LootMoveView(
              move.plugin,
              move.current,
              move.proposed,
              move.reason,
            ),
          ),
        ),
        List.unmodifiable(
          value.messages.map(
            (message) =>
                LootMessageView(message.plugin, message.level, message.text),
          ),
        ),
        _metadata(value.metadata),
        value.helperVersion,
        value.liblootVersion,
        value.liblootRevision,
      );
    }
    return LootStateView(
      state.capabilityId,
      state.available,
      state.reason,
      state.hasMetadata() ? _metadata(state.metadata) : null,
      proposal,
    );
  }
}
