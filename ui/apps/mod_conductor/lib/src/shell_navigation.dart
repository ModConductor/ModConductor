part of 'app.dart';

extension _DesktopNavigation on _DesktopShell {
  Widget _navigation(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Wrap(
      spacing: 4,
      children: [
        for (final item in _Destination.values)
          Semantics(
            selected: destination == item,
            child: TextButton(
              key: ValueKey('nav-${item.name}'),
              autofocus: item == _Destination.workspaces,
              focusNode: switch (item) {
                _Destination.workspaces => workspacesFocus,
                _Destination.games => gamesFocus,
                _Destination.preferences => preferencesFocus,
              },
              style: TextButton.styleFrom(
                backgroundColor: destination == item
                    ? Theme.of(context).colorScheme.primary
                          .withValues(alpha: .12)
                    : null,
              ),
              onPressed: () => onNavigate(item),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  McIconLabel(
                    icon: Icon(switch (item) {
                      _Destination.workspaces => Icons.home_outlined,
                      _Destination.games => Icons.sports_esports_outlined,
                      _Destination.preferences => Icons.tune,
                    }, size: 18),
                    label: switch (item) {
                      _Destination.workspaces => labels.workspaces,
                      _Destination.games => 'Games',
                      _Destination.preferences => labels.preferences,
                    },
                  ),
                  if (item == _Destination.preferences && updateAvailable) ...[
                    const SizedBox(width: 8),
                    Semantics(
                      label: 'Update available',
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (requests case final requests?)
          ListenableBuilder(
            listenable: requests,
            builder: (context, _) => TextButton(
              key: const ValueKey('open-requests'),
              onPressed: onRequests,
              child: McIconLabel(
                icon: const Icon(Icons.move_to_inbox_outlined, size: 18),
                label: labels.openRequests(requests.count),
              ),
            ),
          ),
      ],
    ),
  );
}
