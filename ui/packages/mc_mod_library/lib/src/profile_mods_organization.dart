part of 'profile_mods_controller.dart';

extension ProfileModsOrganization on ProfileModsController {
  Future<void> move(ProfileModMove direction) async {
    final client = _organization, profile = _profile, expected = revision;
    if (client == null || profile == null || expected == null || !canMove) {
      return;
    }
    final ids = model.selectedIds.map((id) => id.modId).toList();
    await _organize(() => client.move(profile, expected, ids, direction));
  }

  Future<void> group(List<String> ids, String separator) async {
    final client = _organization, profile = _profile, expected = revision;
    if (client == null ||
        profile == null ||
        expected == null ||
        changing ||
        stale) {
      return;
    }
    await _organize(() => client.group(profile, expected, ids, separator));
  }

  bool canPlace(
    List<ModRowId> ids,
    ModRowId target,
    OrganizationPlacement placement,
  ) {
    if (!connected ||
        changing ||
        stale ||
        !byPriority ||
        revision == null ||
        ids.isEmpty) {
      return false;
    }
    final rows = ids.map((id) => model[id]).toList(),
        destination = model[target];
    if (destination == null ||
        rows.any((row) => row == null || row.selection is LockedProfileMod)) {
      return false;
    }
    final headers = rows
        .where((row) => row!.mod.kind == ModKind.separator)
        .map((row) => row!.mod.id)
        .toSet();
    if (ids.contains(target) || headers.contains(destination.groupId)) {
      return false;
    }
    if (placement == OrganizationPlacement.inside) {
      return destination.mod.kind == ModKind.separator && headers.isEmpty;
    }
    final parent = headers.isNotEmpty ? null : destination.groupId;
    return rows
        .where((row) => !headers.contains(row!.groupId))
        .every((row) => row!.groupId == parent);
  }

  Future<void> place(
    List<ModRowId> ids,
    ModRowId target,
    OrganizationPlacement placement,
  ) async {
    if (!canPlace(ids, target, placement)) return;
    final client = _organization!, profile = _profile!, expected = revision!;
    await _organize(
      () => client.place(
        profile,
        expected,
        ids.map((id) => id.modId).toList(),
        target.modId,
        placement,
      ),
    );
  }

  Future<void> _organize(Future<int> Function() action) => _change(() async {
    final changed = await action();
    return ProfileModsDelta(changed, const [], enabledCount);
  }, revision!);
}
