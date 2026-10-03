part of 'browser.dart';

extension _InstalledModsPanel on _ModLibraryBrowserState {
  Widget _installedModsPanel(
    BuildContext context,
    bool compact,
    bool versionColumn,
  ) {
    final chosen = controller.selected;
    final inventory = controller.inventory;
    Future<void> move(ProfileModMove direction) async {
      await inventory.move(direction);
      if (mounted) _modsFocus.requestFocus();
    }

    OrganizationPlacement placement(McCollectionDropPosition position) =>
        switch (position) {
          McCollectionDropPosition.before => OrganizationPlacement.before,
          McCollectionDropPosition.after => OrganizationPlacement.after,
          McCollectionDropPosition.inside => OrganizationPlacement.inside,
        };
    final editSelection = controller.canEdit && controller.activity == null;
    final modActions = <Widget>[
      if (widget.inventoryExports != null &&
          widget.chooseExportLocation != null)
        McIconAction(
          key: const ValueKey('export-csv'),
          focusNode: _exportFocus,
          label: 'Export CSV',
          icon: const Icon(Icons.download_outlined),
          onPressed:
              inventory.connected &&
                  !inventory.loading &&
                  !inventory.changing &&
                  !inventory.stale &&
                  controller.workspaceRevision != null &&
                  inventory.queryIdentity != null
              ? () => unawaited(_export())
              : null,
        ),
      if (widget.onOpenNexus != null)
        McIconAction(
          label: 'Nexus Mods',
          icon: const Icon(Icons.public),
          onPressed:
              chosen?.kind == ModKind.regular &&
                  !deletion.busy &&
                  controller.activity == null
              ? () => widget.onOpenNexus!(chosen!)
              : null,
        ),
      if (widget.maintenance != null)
        McIconAction(
          label: 'Delete mod',
          icon: const Icon(Icons.delete_outline),
          onPressed:
              chosen?.kind == ModKind.regular &&
                  controller.canEdit &&
                  !deletion.busy
              ? () => unawaited(_delete(chosen!))
              : null,
        ),
      McIconMenu<_OrganizationAction>(
        label: 'Installed mods options',
        enabled: controller.organization != null,
        itemBuilder: (_) => [
          PopupMenuItem(
            value: inventory.query.view == OrganizationView.groups
                ? _OrganizationAction.flat
                : _OrganizationAction.group,
            child: Text(
              inventory.query.view == OrganizationView.groups
                  ? 'Show flat list'
                  : 'Group by separators',
            ),
          ),
          const PopupMenuItem(
            value: _OrganizationAction.categories,
            child: Text('Manage categories'),
          ),
        ],
        onSelected: (action) async {
          switch (action) {
            case _OrganizationAction.group:
              inventory.setQuery(
                inventory.query.copyWith(view: OrganizationView.groups),
              );
            case _OrganizationAction.flat:
              inventory.setQuery(
                inventory.query.copyWith(view: OrganizationView.flat),
              );
            case _OrganizationAction.categories:
              await manageCategories(
                context,
                controller.organization!,
                controller.workspaceId!,
              );
              if (mounted) await inventory.refreshCatalogue();
          }
        },
      ),
      McIconAction(
        key: const ValueKey('add-mod'),
        focusNode: _addFocus,
        label: 'Add mod folder',
        icon: const Icon(Icons.create_new_folder_outlined),
        onPressed:
            controller.canEdit &&
                controller.activity == null &&
                !inventory.changing
            ? () => _details()
            : null,
      ),
    ];
    return McCollection<ModRowId, OrganizedMod>(
      key: const ValueKey('installed-mods'),
      model: controller.mods,
      focusNode: _modsFocus,
      scrollController: _modsScroll,
      title: 'Installed mods',
      showTitle: false,
      compactFilter: compact,
      showTree: false,
      drawerLabel: (row) =>
          row.mod.kind == ModKind.separator ? row.mod.metadata.name : null,
      onContextMenu: _modContextMenu,
      dragScope:
          editSelection &&
              !inventory.changing &&
              !inventory.stale &&
              inventory.byPriority
          ? (controller.workspaceId, controller.profileId, inventory.revision)
          : null,
      canDrag: (row) => row.selection is! LockedProfileMod,
      canDrop: (ids, target, position) =>
          inventory.canPlace(ids, target, placement(position)),
      onDrop: (ids, target, position) =>
          unawaited(inventory.place(ids, target, placement(position))),
      nodeIcon: (_) => const SizedBox.shrink(),
      filterText: inventory.query.text,
      filterEnabled: inventory.connected,
      onFilterChanged: inventory.search,
      onSort: (_) => inventory.sort('Name'),
      filterLabel: 'Filter mods',
      filterActions: [
        ...modActions,
        TextButton(
          onPressed:
              controller.organization == null || controller.workspaceId == null
              ? null
              : () async {
                  final query = await showDialog<ModQuery>(
                    context: context,
                    builder: (_) => ModFilterDialog(
                      query: inventory.query,
                      client: controller.organization!,
                      workspace: controller.workspaceId!,
                    ),
                  );
                  if (mounted && query != null) inventory.setQuery(query);
                },
          child: Text(
            inventory.query.filters.isEmpty
                ? 'Filters'
                : 'Filters (${inventory.query.filters.length})',
          ),
        ),
      ],
      countLabel:
          '${inventory.enabledCount} enabled total · ${inventory.matchingMods} of ${inventory.total} mods · ${inventory.query.view == OrganizationView.groups ? '${inventory.matchingGroups} ${inventory.matchingGroups == 1 ? 'group' : 'groups'}' : '${inventory.matchingSeparators} separators'}${inventory.complete ? '' : ' · ${inventory.loaded} rows loaded'}',
      empty: 'No installed mods.',
      emptyContent:
          inventory.query.text.trim().isEmpty && inventory.query.filters.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  const Text('No mods match these filters.'),
                  TextButton(
                    onPressed: () => inventory.setQuery(
                      inventory.query.copyWith(text: '', filters: const []),
                    ),
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
            ),
      multiSelect: true,
      selectMultiple: false,
      onMoveUp: editSelection && inventory.canMove
          ? () => unawaited(move(ProfileModMove.up))
          : null,
      onMoveDown: editSelection && inventory.canMove
          ? () => unawaited(move(ProfileModMove.down))
          : null,
      onSelect: (row) => controller.select(row.entry),
      semanticLabel: (row) =>
          '${row.mod.metadata.name}, ${_kind(row.mod.kind)}${row.mod.metadata.version.isEmpty ? '' : ', version ${row.mod.metadata.version}'}, ${row.groupSize == null ? _status(row.mod.status) : '${row.groupSize!.matching} of ${row.groupSize!.total} mods'}',
      loading: inventory.loading,
      problem: inventory.problem,
      onLoad: inventory.canLoad ? () => unawaited(inventory.load()) : null,
      onCancel: inventory.cancel,
      onRefresh:
          inventory.connected && !inventory.loading && !inventory.changing
          ? () => unawaited(inventory.load(refresh: true))
          : null,
      footer: Text(
        '${controller.mods.selectedIds.length} selected',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      actions: const [],
      columns: [
        McColumn(
          '',
          (row) => switch (row.selection) {
            ManagedProfileMod(:final enabled) => Semantics(
              label: 'Enable ${row.mod.metadata.name}',
              child: Checkbox(
                value: enabled,
                onChanged:
                    editSelection &&
                        inventory.connected &&
                        !inventory.changing &&
                        !inventory.stale
                    ? (value) => unawaited(
                        inventory.enable(value!, onlyModId: row.mod.id),
                      )
                    : null,
              ),
            ),
            OrderedProfileMod() =>
              inventory.query.view == OrganizationView.groups
                  ? McCollectionExpander(
                      model: controller.mods,
                      id: (modId: row.mod.id),
                    )
                  : const ExcludeSemantics(
                      child: Icon(Icons.horizontal_rule, size: 19),
                    ),
            LockedProfileMod() => const ExcludeSemantics(
              child: Icon(Icons.lock_outline, size: 19),
            ),
          },
          width: 44,
          interactive: true,
        ),
        McColumn(
          'Mod',
          (row) => Padding(
            padding: EdgeInsets.only(left: row.groupId == null ? 0 : 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.mod.metadata.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!versionColumn && row.mod.metadata.version.isNotEmpty)
                  Text(
                    'Version ${row.mod.metadata.version}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          compare: (a, b) => a.mod.metadata.name.compareTo(b.mod.metadata.name),
        ),
        if (versionColumn)
          McColumn(
            'Category',
            (row) => Text(
              row.mod.metadata.categories
                  .map((category) => category.label)
                  .join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            width: 130,
          ),
      ],
    );
  }
}

String _kind(ModKind kind) => switch (kind) {
  ModKind.regular => 'Mod',
  ModKind.separator => 'Separator',
  ModKind.backup => 'Backup',
  ModKind.unmanaged => 'Unmanaged',
  ModKind.generatedOutput => 'Output',
};
String _status(InventoryStatus status) => switch (status) {
  InventoryStatus.ready => 'Ready',
  InventoryStatus.detached => 'Folder missing',
  InventoryStatus.changed => 'Source changed',
  InventoryStatus.unproved => 'Not verified',
  InventoryStatus.publishing => 'Save in progress',
};
