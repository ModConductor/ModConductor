import 'mod_library_models.dart';

enum ProfileModRestriction { backup, unmanaged, automatic }

enum ProfileModMove { up, down }

sealed class ProfileModSelection {
  const ProfileModSelection(this.modId);
  final String modId;
  int? get priority;
}

class ManagedProfileMod extends ProfileModSelection {
  const ManagedProfileMod(super.modId, this.priority, this.enabled);
  @override
  final int priority;
  final bool enabled;
}

class OrderedProfileMod extends ProfileModSelection {
  const OrderedProfileMod(super.modId, this.priority);
  @override
  final int priority;
}

class LockedProfileMod extends ProfileModSelection {
  const LockedProfileMod(super.modId, this.restriction);
  final ProfileModRestriction restriction;
  @override
  int? get priority => null;
}

class ProfileMod {
  const ProfileMod(this.mod, this.selection);
  final ModEntry mod;
  final ProfileModSelection selection;
}

class ProfileModsDelta {
  const ProfileModsDelta(this.revision, this.changed, this.enabledCount);
  final int revision, enabledCount;
  final List<ProfileModSelection> changed;
}
