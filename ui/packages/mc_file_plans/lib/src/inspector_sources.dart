part of 'inspector.dart';

class _FileCopyList extends StatelessWidget {
  const _FileCopyList({
    required this.copies,
    required this.selected,
    required this.view,
    required this.blocked,
    required this.stale,
    required this.profileName,
  });

  final List<InspectedFileCopy> copies;
  final InspectedFileCopy? selected;
  final FileInspectorController view;
  final bool blocked, stale;
  final String? profileName;

  String status(InspectedFileCopy copy) => [
    switch (copy.standing) {
      FileSourceStanding.winner => stale ? 'Previous winner' : 'Winner',
      FileSourceStanding.alternative => blocked ? 'Unresolved' : 'Alternative',
      FileSourceStanding.selected => 'Selected source',
      FileSourceStanding.previous => 'Previous saved version',
      FileSourceStanding.unavailable => 'Unavailable',
    },
    if (copy.hidden) 'Hidden',
    if (copy.copy != null && !copy.enabled && !copy.historical)
      profileName == null
          ? 'Disabled in this profile'
          : 'Disabled in $profileName',
  ].join(' · ');

  @override
  Widget build(BuildContext context) => RadioGroup<Object>(
    groupValue: selected == null
        ? null
        : FileInspectorController.key(selected!),
    onChanged: (value) {
      final row = copies
          .where((row) => FileInspectorController.key(row) == value)
          .firstOrNull;
      if (row != null) view.select(row);
    },
    child: Column(
      children: [
        for (final copy in copies) ...[
          RadioListTile<Object>(
            value: FileInspectorController.key(copy),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              copy.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      copy.source.kindLabel,
                      if (copy.versionLabel.isNotEmpty &&
                          copy.source is! QualifiedArchiveEntryPreviewSource)
                        copy.versionLabel,
                      if (copy.priority != null)
                        'Priority ${copy.priority! + 1}',
                      fileSize(copy.length),
                    ].join(' · '),
                  ),
                  if (status(copy).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(status(copy)),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
        ],
      ],
    ),
  );
}
