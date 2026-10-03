import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/mod_organization.pbgrpc.dart' as wire;
import 'mod_library_wire.dart' as mods;
import 'mod_organization_wire.dart' as mapping;
import 'mod_organization_models.dart';
import 'profile_mod_models.dart';
import 'generated/modconductor/v1/profile_mods.pbenum.dart' as selection;
export 'mod_organization_models.dart';

class ModOrganizationClient {
  ModOrganizationClient(ClientChannel channel, CallOptions options)
    : _client = wire.ModOrganizationOperationsClient(channel, options: options);
  final wire.ModOrganizationOperationsClient _client;

  Future<CategoriesPage> categories(
    String workspaceId, {
    String? parentId,
    String? afterId,
    int? expectedRevision,
  }) async {
    final reply = await _client.readCategories(
      wire.ReadCategoriesRequest(
        workspaceId: workspaceId,
        parentId: parentId,
        afterId: afterId,
        expectedRevision: expectedRevision == null
            ? null
            : Int64(expectedRevision),
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.CategoriesReply_Outcome.page => CategoriesPage(
        reply.page.revision.toInt(),
        List.unmodifiable(reply.page.entries.map(mapping.category)),
        List.unmodifiable(reply.page.ancestors.map(mapping.category)),
        reply.page.hasNextId() ? reply.page.nextId : null,
      ),
      wire.CategoriesReply_Outcome.fault => mods.reject(reply.fault),
      wire.CategoriesReply_Outcome.notSet => throw const FormatException(
        'Missing categories.',
      ),
    };
  }

  Future<int> createCategory(
    String workspaceId,
    int revision,
    String id,
    String label, {
    String? parentId,
  }) => _edit(
    wire.EditCategoryRequest(
      workspaceId: workspaceId,
      expectedRevision: Int64(revision),
      create_3: wire.CategoryDefinition(
        categoryId: id,
        label: label,
        parentId: parentId,
      ),
    ),
  );
  Future<int> updateCategory(
    String workspaceId,
    int revision,
    String id,
    String label, {
    String? parentId,
  }) => _edit(
    wire.EditCategoryRequest(
      workspaceId: workspaceId,
      expectedRevision: Int64(revision),
      update: wire.CategoryDefinition(
        categoryId: id,
        label: label,
        parentId: parentId,
      ),
    ),
  );
  Future<int> deleteCategory(String workspaceId, int revision, String id) =>
      _edit(
        wire.EditCategoryRequest(
          workspaceId: workspaceId,
          expectedRevision: Int64(revision),
          deleteId: id,
        ),
      );
  Future<int> _edit(wire.EditCategoryRequest request) async =>
      _changed(await _client.editCategory(request));
  Future<ModQueryPage> query(
    String profileId,
    ModQuery query, {
    ModQueryCursor? cursor,
    String? inspectedId,
  }) async {
    final reply = await _client.queryMods(
      wire.QueryModsRequest(
        profileId: profileId,
        query: mapping.query(query),
        cursor: cursor == null ? null : mapping.encodeCursor(cursor),
        inspectedModId: inspectedId,
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.ModQueryReply_Outcome.page => mapping.page(reply.page),
      wire.ModQueryReply_Outcome.fault => mods.reject(reply.fault),
      wire.ModQueryReply_Outcome.notSet => throw const FormatException(
        'Missing mod query.',
      ),
    };
  }

  Future<List<String>> loadOrderLayout(String profile) async {
    final reply = await _client.readLoadOrderLayout(
      wire.ReadLoadOrderLayoutRequest(profileId: profile),
    );
    return switch (reply.whichOutcome()) {
      wire.LoadOrderLayoutReply_Outcome.layout => List.unmodifiable(
        reply.layout.entries,
      ),
      wire.LoadOrderLayoutReply_Outcome.fault => mods.reject(reply.fault),
      wire.LoadOrderLayoutReply_Outcome.notSet => throw const FormatException(
        'Missing load order layout.',
      ),
    };
  }

  Future<void> saveLoadOrderLayout(String profile, List<String> entries) async {
    _changed(
      await _client.saveLoadOrderLayout(
        wire.SaveLoadOrderLayoutRequest(profileId: profile, entries: entries),
      ),
    );
  }

  Future<int> move(
    String profile,
    int revision,
    List<String> ids,
    ProfileModMove direction,
  ) async => _changed(
    await _client.changeModOrganization(
      wire.ChangeModOrganizationRequest(
        profileId: profile,
        expectedRevision: Int64(revision),
        modIds: ids,
        move: direction == ProfileModMove.up
            ? selection.ProfileModMove.PROFILE_MOD_MOVE_UP
            : selection.ProfileModMove.PROFILE_MOD_MOVE_DOWN,
      ),
    ),
  );

  Future<int> group(
    String profile,
    int revision,
    List<String> ids,
    String group,
  ) async => _changed(
    await _client.changeModOrganization(
      wire.ChangeModOrganizationRequest(
        profileId: profile,
        expectedRevision: Int64(revision),
        modIds: ids,
        groupId: group,
      ),
    ),
  );

  Future<int> place(
    String profile,
    int revision,
    List<String> ids,
    String target,
    OrganizationPlacement placement,
  ) async => _changed(
    await _client.changeModOrganization(
      wire.ChangeModOrganizationRequest(
        profileId: profile,
        expectedRevision: Int64(revision),
        modIds: ids,
        drop: wire.OrganizationDrop(
          targetId: target,
          placement: switch (placement) {
            OrganizationPlacement.before =>
              wire.OrganizationPlacement.ORGANIZATION_PLACEMENT_BEFORE,
            OrganizationPlacement.after =>
              wire.OrganizationPlacement.ORGANIZATION_PLACEMENT_AFTER,
            OrganizationPlacement.inside =>
              wire.OrganizationPlacement.ORGANIZATION_PLACEMENT_INSIDE,
          },
        ),
      ),
    ),
  );

  int _changed(wire.OrganizationChangeReply reply) =>
      switch (reply.whichOutcome()) {
        wire.OrganizationChangeReply_Outcome.changed =>
          reply.changed.revision.toInt(),
        wire.OrganizationChangeReply_Outcome.fault => mods.reject(reply.fault),
        wire.OrganizationChangeReply_Outcome.notSet =>
          throw const FormatException('Missing category change.'),
      };
}
