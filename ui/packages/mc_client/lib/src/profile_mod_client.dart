import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/profile_mods.pbgrpc.dart' as wire;
import 'mod_library_wire.dart' as mapping;
import 'profile_mod_models.dart';
export 'profile_mod_models.dart';

class ProfileModsClient {
  ProfileModsClient(ClientChannel channel, CallOptions options)
    : _client = wire.ProfileModOperationsClient(channel, options: options);
  final wire.ProfileModOperationsClient _client;

  Future<ProfileModsPage> read(
    String profileId, {
    String? afterModId,
    int? expectedRevision,
  }) async {
    final reply = await _client.readProfileMods(
      wire.ReadProfileModsRequest(
        profileId: profileId,
        afterModId: afterModId,
        expectedRevision: expectedRevision == null
            ? null
            : Int64(expectedRevision),
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.ProfileModsReply_Outcome.page => ProfileModsPage(
        reply.page.revision.toInt(),
        List.unmodifiable(reply.page.entries.map(_entry)),
        reply.page.hasNextModId() ? reply.page.nextModId : null,
        reply.page.total,
        reply.page.enabledCount,
      ),
      wire.ProfileModsReply_Outcome.fault => mapping.reject(reply.fault),
      wire.ProfileModsReply_Outcome.notSet => throw const FormatException(
        'Missing profile mods.',
      ),
    };
  }

  Future<ProfileModDetail> find(
    String profileId,
    String modId, {
    int? expectedRevision,
  }) async {
    final reply = await _client.readProfileMod(
      wire.ReadProfileModRequest(
        profileId: profileId,
        modId: modId,
        expectedRevision: expectedRevision == null
            ? null
            : Int64(expectedRevision),
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.ProfileModReply_Outcome.detail => ProfileModDetail(
        reply.detail.revision.toInt(),
        _entry(reply.detail.entry),
      ),
      wire.ProfileModReply_Outcome.fault => mapping.reject(reply.fault),
      wire.ProfileModReply_Outcome.notSet => throw const FormatException(
        'Missing profile mod.',
      ),
    };
  }

  Future<ProfileModsDelta> enable(
    String profileId,
    int revision,
    Iterable<String> ids,
    bool enabled,
  ) => _change(
    wire.ChangeProfileModsRequest(
      profileId: profileId,
      expectedRevision: Int64(revision),
      modIds: ids,
      enabled: enabled,
    ),
  );

  Future<ProfileModsDelta> move(
    String profileId,
    int revision,
    Iterable<String> ids,
    ProfileModMove direction,
  ) => _change(
    wire.ChangeProfileModsRequest(
      profileId: profileId,
      expectedRevision: Int64(revision),
      modIds: ids,
      move: switch (direction) {
        ProfileModMove.up => wire.ProfileModMove.PROFILE_MOD_MOVE_UP,
        ProfileModMove.down => wire.ProfileModMove.PROFILE_MOD_MOVE_DOWN,
      },
    ),
  );

  Future<ProfileModsDelta> _change(
    wire.ChangeProfileModsRequest request,
  ) async {
    final reply = await _client.changeProfileMods(request);
    return switch (reply.whichOutcome()) {
      wire.ProfileModsChangeReply_Outcome.delta => ProfileModsDelta(
        reply.delta.revision.toInt(),
        List.unmodifiable(reply.delta.changed.map(_selection)),
        reply.delta.enabledCount,
      ),
      wire.ProfileModsChangeReply_Outcome.fault => mapping.reject(reply.fault),
      wire.ProfileModsChangeReply_Outcome.notSet => throw const FormatException(
        'Missing profile change.',
      ),
    };
  }
}

ProfileMod _entry(wire.ProfileModView row) =>
    ProfileMod(mapping.entry(row.mod), _selection(row.selection));

ProfileModSelection _selection(wire.ProfileModSelection row) =>
    switch (row.whichState()) {
      wire.ProfileModSelection_State.managed => ManagedProfileMod(
        row.modId,
        row.managed.priority,
        row.managed.enabled,
      ),
      wire.ProfileModSelection_State.separator => OrderedProfileMod(
        row.modId,
        row.separator.priority,
      ),
      wire.ProfileModSelection_State.locked => LockedProfileMod(
        row.modId,
        switch (row.locked) {
          wire.ProfileModRestriction.PROFILE_MOD_RESTRICTION_BACKUP =>
            ProfileModRestriction.backup,
          wire.ProfileModRestriction.PROFILE_MOD_RESTRICTION_UNMANAGED =>
            ProfileModRestriction.unmanaged,
          wire.ProfileModRestriction.PROFILE_MOD_RESTRICTION_AUTOMATIC =>
            ProfileModRestriction.automatic,
          _ => throw const FormatException('Unknown profile mod restriction.'),
        },
      ),
      wire.ProfileModSelection_State.notSet => throw const FormatException(
        'Missing profile selection state.',
      ),
    };
