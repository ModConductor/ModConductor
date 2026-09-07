import 'generated/modconductor/v1/profile_mods.pb.dart' as wire;
import 'mod_library_wire.dart' as mapping;
import 'profile_mod_models.dart';

ProfileMod entry(wire.ProfileModView row) =>
    ProfileMod(mapping.entry(row.mod), selection(row.selection));

ProfileModSelection selection(wire.ProfileModSelection row) =>
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
