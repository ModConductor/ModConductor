import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'bethesda_client.dart';
import 'generated/modconductor/v1/archive_policy.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/profile_data.pb.dart' as profile;
import 'profile_data_client.dart' show decodeProfileDataProblem;
import 'profile_data_models.dart';

enum ArchiveState { active, inactive, unavailable, unsupported }

class ArchivePolicyEntry {
  const ArchivePolicyEntry({
    required this.name,
    required this.position,
    required this.state,
    required this.required,
    required this.explicit,
    required this.iniKey,
    required this.iniPosition,
    required this.associatedPlugin,
    required this.reasons,
    required this.source,
    required this.format,
    required this.problem,
  });
  final String name;
  final int? position, iniPosition;
  final ArchiveState state;
  final bool required, explicit;
  final String iniKey, associatedPlugin, format, problem;
  final List<String> reasons;
  final PluginSource? source;
}

class ArchivePolicyView {
  const ArchivePolicyView({
    required this.reference,
    required this.snapshotId,
    required this.observedAt,
    required this.stale,
    required this.entries,
    required this.problems,
    required this.blockingProblems,
    required this.saved,
    required this.applied,
    required this.pending,
    required this.pendingProblem,
    required this.invalidation,
  });
  final ProfileDataRef reference;
  final String snapshotId;
  final DateTime observedAt;
  final bool stale, saved, applied, pending;
  final List<ArchivePolicyEntry> entries;
  final List<String> problems, blockingProblems;
  final String pendingProblem, invalidation;
}

abstract interface class ArchivePolicyClient {
  Future<ArchivePolicyView> scan(
    String workspace,
    String profile,
    String headers,
  );
  Future<ArchivePolicyView> read(
    String workspace,
    String profile,
    String snapshot,
  );
  Future<void> apply(String id, ProfileDataRef expected, String snapshot);
  Future<void> restore(String id, ProfileDataRef expected);
}

class GrpcArchivePolicyClient implements ArchivePolicyClient {
  GrpcArchivePolicyClient(ClientChannel channel, CallOptions options)
    : _client = wire.ArchivePoliciesClient(channel, options: options);
  final wire.ArchivePoliciesClient _client;

  static profile.ProfileDataRef _reference(ProfileDataRef value) =>
      profile.ProfileDataRef(
        workspaceId: value.workspaceId,
        profileId: value.profileId,
        contextId: value.contextId,
        revision: Int64(value.revision),
      );

  @override
  Future<ArchivePolicyView> scan(
    String workspace,
    String profileId,
    String headers,
  ) async => _decode(
    await _client.scanArchivePolicy(
      wire.ScanArchivePolicyRequest(
        workspaceId: workspace,
        profileId: profileId,
        headersId: headers,
      ),
    ),
  );

  @override
  Future<ArchivePolicyView> read(
    String workspace,
    String profileId,
    String snapshot,
  ) async => _decode(
    await _client.readArchivePolicy(
      wire.ReadArchivePolicyRequest(
        workspaceId: workspace,
        profileId: profileId,
        snapshotId: snapshot,
      ),
    ),
  );

  @override
  Future<void> apply(String id, ProfileDataRef expected, String snapshot) =>
      _finish(
        _client.applyArchivePolicy(
          wire.ApplyArchivePolicyRequest(
            id: id,
            expected: _reference(expected),
            snapshotId: snapshot,
          ),
        ),
      );

  @override
  Future<void> restore(String id, ProfileDataRef expected) => _finish(
    _client.restoreArchivePolicy(
      wire.RestoreArchivePolicyRequest(id: id, expected: _reference(expected)),
    ),
  );

  static Future<void> _finish(Stream<profile.ProfileDataEvent> events) async {
    var finished = false;
    await for (final event in events) {
      if (event.hasProblem()) throw decodeProfileDataProblem(event.problem);
      if (event.hasResult()) finished = true;
    }
    if (!finished) {
      throw const FormatException('The archive change did not finish.');
    }
  }

  static ArchivePolicyView _decode(wire.ArchivePolicyReply reply) {
    if (reply.hasProblem()) throw decodeProfileDataProblem(reply.problem);
    if (!reply.hasPolicy()) {
      throw const FormatException('The archive view is missing.');
    }
    final value = reply.policy, reference = value.reference;
    return ArchivePolicyView(
      reference: ProfileDataRef(
        workspaceId: reference.workspaceId,
        profileId: reference.profileId,
        contextId: reference.contextId,
        revision: reference.revision.toInt(),
      ),
      snapshotId: value.snapshotId,
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        value.observedAtUnixMs.toInt(),
        isUtc: true,
      ),
      stale: value.stale,
      entries: List.unmodifiable(value.entries.map(_entry)),
      problems: List.unmodifiable(value.problems),
      blockingProblems: List.unmodifiable(value.blockingProblems),
      saved: value.saved,
      applied: value.applied,
      pending: value.pending,
      pendingProblem: value.pendingProblem,
      invalidation: value.invalidation,
    );
  }

  static ArchivePolicyEntry _entry(wire.ArchivePolicyEntry value) =>
      ArchivePolicyEntry(
        name: value.name,
        position: value.hasPosition() ? value.position : null,
        state: switch (value.state) {
          wire.ArchivePolicyState.ARCHIVE_POLICY_STATE_ACTIVE =>
            ArchiveState.active,
          wire.ArchivePolicyState.ARCHIVE_POLICY_STATE_INACTIVE =>
            ArchiveState.inactive,
          wire.ArchivePolicyState.ARCHIVE_POLICY_STATE_UNAVAILABLE =>
            ArchiveState.unavailable,
          wire.ArchivePolicyState.ARCHIVE_POLICY_STATE_UNSUPPORTED =>
            ArchiveState.unsupported,
          _ => throw const FormatException('The archive state is unsupported.'),
        },
        required: value.required,
        explicit: value.explicit,
        iniKey: value.iniKey,
        iniPosition: value.hasIniPosition() ? value.iniPosition : null,
        associatedPlugin: value.associatedPlugin,
        reasons: List.unmodifiable(value.reasons),
        source: value.hasSource()
            ? PluginSource(
                value.source.name,
                value.source.version,
                value.source.path,
                value.source.modId,
                value.source.versionId,
                value.source.gameFile,
              )
            : null,
        format: value.format,
        problem: value.problem,
      );
}
