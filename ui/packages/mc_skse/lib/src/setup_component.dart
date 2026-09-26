part of 'section.dart';

class _SkyrimSetupComponentRow extends StatelessWidget {
  const _SkyrimSetupComponentRow({
    required this.item,
    required this.selection,
    required this.updateVersion,
    required this.busy,
    required this.locked,
    required this.onSelectAction,
    required this.onChooseEnbArchive,
    required this.onClearEnbArchive,
    required this.onOpenProjectPage,
  });

  final SkyrimSetupComponent item;
  final SkyrimSetupSelection selection;
  final String? updateVersion;
  final bool busy;
  final bool locked;
  final void Function(String, SkyrimSetupAction) onSelectAction;
  final VoidCallback onChooseEnbArchive;
  final VoidCallback onClearEnbArchive;
  final ValueChanged<String> onOpenProjectPage;

  @override
  Widget build(BuildContext context) {
    final action = _actionFor(selection, item.id);
    final selected = switch (action) {
      SkyrimSetupAction.install => true,
      SkyrimSetupAction.remove => false,
      _ => item.installed,
    };
    const skseIcon =
        'https://shared.fastly.steamstatic.com/community_assets/images/apps/365720/48eaa1815ac4beddc4d7c9fec6c2517f6f0b718e.jpg';
    const enbIcon = 'http://enbdev.com/header_logo.gif';
    const fnisIcon = 'https://images.nexusmods.com/mod-headers/1704/3038.jpg';
    final kind = switch (item.id) {
      'skse' => 'Script extender',
      'enb' => 'Graphics injector',
      _ => 'Animation tool',
    };
    return McComponentChoiceRow(
      key: ValueKey('setup-${item.id}'),
      name: item.name,
      kind: kind,
      current: item.installed ? 'Installed' : 'Not installed',
      installed: item.installed,
      selected: selected,
      updating: action == SkyrimSetupAction.update && updateVersion != null,
      updateVersion: updateVersion,
      iconUrl: switch (item.id) {
        'skse' => skseIcon,
        'enb' => enbIcon,
        'fnis' => fnisIcon,
        _ => null,
      },
      iconHeaders: item.id == 'enb'
          ? const {'Referer': 'http://enbdev.com/'}
          : null,
      iconFit: item.id == 'fnis' ? BoxFit.cover : BoxFit.contain,
      enabled: !busy && !locked,
      onToggle: () => onSelectAction(
        item.id,
        selected
            ? (item.installed
                  ? SkyrimSetupAction.remove
                  : SkyrimSetupAction.unchanged)
            : (item.installed
                  ? SkyrimSetupAction.unchanged
                  : SkyrimSetupAction.install),
      ),
      onOpenPage: () => onOpenProjectPage(item.id),
      onUpdate: item.installed && updateVersion != null
          ? () => onSelectAction(
              item.id,
              action == SkyrimSetupAction.update
                  ? SkyrimSetupAction.unchanged
                  : SkyrimSetupAction.update,
            )
          : null,
      onChooseArchive: item.id == 'enb' ? onChooseEnbArchive : null,
      onClearArchive: item.id == 'enb' ? onClearEnbArchive : null,
      archiveName: selection.enbArchivePath?.split(RegExp(r'[/\\]')).last,
      archiveRequired: item.id == 'enb' && selection.needsEnbArchive,
    );
  }
}
