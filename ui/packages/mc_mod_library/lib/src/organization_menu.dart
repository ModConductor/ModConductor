part of 'browser.dart';

extension _OrganizationMenu on _ModLibraryBrowserState {
  Future<void> _separator({bool group = false}) async {
    final members = group
        ? controller.mods.selectedIds.map((id) => id.modId).toList()
        : const <String>[];
    var name = '';
    final accepted = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group ? 'Group selected' : 'Add separator'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onChanged: (value) => name = value,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (name.trim().isNotEmpty) {
                Navigator.pop(context, name.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (!mounted || accepted == null) return;
    await controller.addSeparator(accepted, members: members);
  }

  Future<void> _modContextMenu(
    BuildContext context,
    OrganizedMod? row,
    Offset position,
  ) async {
    final inventory = controller.inventory;
    final selected = controller.mods.selectedIds;
    final canEdit =
        controller.canEdit &&
        controller.activity == null &&
        !inventory.changing &&
        !inventory.stale;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'separator',
          enabled: canEdit,
          child: const McIconLabel(
            flexible: true,
            icon: Icon(Icons.add, size: 18),
            label: 'Add separator',
          ),
        ),
        PopupMenuItem(
          value: 'group',
          enabled:
              canEdit &&
              selected.length > 1 &&
              selected.every(
                (id) => controller.mods[id]?.selection is ManagedProfileMod,
              ),
          child: const McIconLabel(
            flexible: true,
            icon: Icon(Icons.create_new_folder_outlined, size: 18),
            label: 'Group selected',
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'up',
          enabled: canEdit && inventory.canMove,
          child: const McIconLabel(
            flexible: true,
            icon: Icon(Icons.arrow_upward, size: 18),
            label: 'Move selected up',
          ),
        ),
        PopupMenuItem(
          value: 'down',
          enabled: canEdit && inventory.canMove,
          child: const McIconLabel(
            flexible: true,
            icon: Icon(Icons.arrow_downward, size: 18),
            label: 'Move selected down',
          ),
        ),
        PopupMenuItem(
          value: 'order',
          enabled: !inventory.byPriority,
          child: const Text('Show organization order'),
        ),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'separator':
        await _separator();
      case 'group':
        await _separator(group: true);
      case 'up':
        await inventory.move(ProfileModMove.up);
      case 'down':
        await inventory.move(ProfileModMove.down);
      case 'order':
        inventory.showPriority();
      case null:
        break;
    }
  }
}
