import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/profile_mods.pbgrpc.dart' as wire;
import 'mod_library_wire.dart' as mapping;
import 'profile_mod_models.dart';
import 'profile_mod_wire.dart' as profile;
export 'profile_mod_models.dart';

class ProfileModsClient {
  ProfileModsClient(ClientChannel channel, CallOptions options)
    : _client = wire.ProfileModOperationsClient(channel, options: options);
  final wire.ProfileModOperationsClient _client;

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
        List.unmodifiable(reply.delta.changed.map(profile.selection)),
        reply.delta.enabledCount,
      ),
      wire.ProfileModsChangeReply_Outcome.fault => mapping.reject(reply.fault),
      wire.ProfileModsChangeReply_Outcome.notSet => throw const FormatException(
        'Missing profile change.',
      ),
    };
  }
}
