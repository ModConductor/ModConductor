import 'package:flutter/material.dart';

import 'actions.dart';
import 'theme.dart';

class McIdentityIcon extends StatelessWidget {
  const McIdentityIcon({
    super.key,
    required this.name,
    this.url,
    this.headers,
    this.fit = BoxFit.contain,
    this.size = 32,
  });

  final String name;
  final String? url;
  final Map<String, String>? headers;
  final BoxFit fit;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: url == null
        ? null
        : Image.network(
            url!,
            width: size,
            height: size,
            headers: headers,
            fit: fit,
            semanticLabel: name,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
  );
}

class McComponentChoiceRow extends StatelessWidget {
  const McComponentChoiceRow({
    super.key,
    required this.name,
    required this.kind,
    required this.current,
    required this.installed,
    required this.selected,
    required this.onToggle,
    required this.onOpenPage,
    this.iconUrl,
    this.iconHeaders,
    this.iconFit = BoxFit.contain,
    this.updating = false,
    this.onUpdate,
    this.updateVersion,
    this.onChooseArchive,
    this.onClearArchive,
    this.archiveName,
    this.archiveRequired = false,
    this.enabled = true,
  });

  final String name, kind, current;
  final String? iconUrl, archiveName, updateVersion;
  final Map<String, String>? iconHeaders;
  final BoxFit iconFit;
  final bool installed, selected, updating, archiveRequired, enabled;
  final VoidCallback onToggle, onOpenPage;
  final VoidCallback? onUpdate, onChooseArchive, onClearArchive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final identity = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          McIdentityIcon(
            name: name,
            url: iconUrl,
            headers: iconHeaders,
            fit: iconFit,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(kind, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );

    final currentState = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(current, style: Theme.of(context).textTheme.bodySmall),
      ),
    );

    final controls = SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            child: Semantics(
              label: '$name installed',
              child: Tooltip(
                message: 'Install or remove $name',
                child: Switch(
                  value: selected,
                  onChanged: enabled ? (_) => onToggle() : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          McIconAction(
            label: 'Open $name project page',
            icon: const Icon(Icons.open_in_new, size: 20),
            size: 40,
            onPressed: onOpenPage,
          ),
          if (onChooseArchive != null)
            McIconAction(
              label: archiveName == null
                  ? 'Choose ENBSeries archive'
                  : 'Change ENBSeries archive',
              icon: const Icon(Icons.folder_open_outlined, size: 20),
              size: 40,
              onPressed: enabled && selected ? onChooseArchive : null,
            ),
          if (installed && onUpdate != null) ...[
            const Spacer(),
            if (updateVersion != null) ...[
              Text(
                updateVersion!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
            ],
            SizedBox(
              height: 40,
              child: OutlinedButton(
                style: updateVersion == null
                    ? null
                    : OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                onPressed: enabled && selected ? onUpdate : null,
                child: Text(
                  updating
                      ? (updateVersion == null ? 'Undo update' : 'Undo')
                      : 'Update',
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final feedback = SizedBox(
      height: 30,
      child: Align(
        alignment: Alignment.centerLeft,
        child: archiveRequired && archiveName == null
            ? Text(
                'Choose an ENBSeries archive.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.error),
              )
            : archiveRequired && archiveName != null
            ? Row(
                children: [
                  Flexible(
                    child: Text(
                      archiveName!,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: McSpacing.small),
                  TextButton(
                    onPressed: enabled ? onClearArchive : null,
                    child: const Text('Remove file'),
                  ),
                ],
              )
            : installed && !selected
            ? Text(
                'Remove',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.error),
              )
            : null,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 33, child: identity),
                    Expanded(flex: 24, child: currentState),
                    Expanded(
                      flex: 43,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [controls, feedback],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identity,
                    const SizedBox(height: 7),
                    currentState,
                    const SizedBox(height: 10),
                    controls,
                    feedback,
                  ],
                ),
        );
      },
    );
  }
}

class McChangeEntry {
  const McChangeEntry(this.component, this.change, this.source);
  final String component, change, source;
}

class McChangeSummary extends StatelessWidget {
  const McChangeSummary({super.key, required this.changes});
  final List<McChangeEntry> changes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          children: const [
            _ChangeCell('Component', heading: true),
            _ChangeCell('Change', heading: true),
            _ChangeCell('Source', heading: true),
          ],
        ),
        for (final change in changes)
          TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            children: [
              _ChangeCell(change.component),
              _ChangeCell(change.change),
              _ChangeCell(change.source),
            ],
          ),
      ],
    );
  }
}

class _ChangeCell extends StatelessWidget {
  const _ChangeCell(this.text, {this.heading = false});
  final String text;
  final bool heading;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
    child: Text(
      text,
      style: heading
          ? Theme.of(context).textTheme.bodySmall
          : Theme.of(context).textTheme.bodyMedium,
    ),
  );
}
