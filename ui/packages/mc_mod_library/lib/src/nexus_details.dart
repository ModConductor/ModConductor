part of 'nexus_view.dart';

extension _NexusDetailsView on _ModNexusViewState {
  Widget detailsView(BuildContext c, bool compact, ModNexusDetails value) {
    if (value.reference.providerMod == null) {
      return SingleChildScrollView(
        child: McSection(
          title: 'Nexus Mods',
          children: [
            const McStatus(title: 'No Nexus mod linked'),
            gap(),
            McAction(
              label: 'Link Nexus mod',
              emphasis: McActionEmphasis.primary,
              onPressed: controller.busy ? null : linkForm,
            ),
          ],
        ),
      );
    }
    final metadata = value.metadata;
    final knownUpdates = metadata?.files.any((f) => f.update) == true;
    final installed = metadata?.files
        .where((f) => f.file.id == value.installedFile)
        .firstOrNull;
    final installedLabel = value.installedFile == null
        ? 'Not linked'
        : installed == null
        ? (value.installedVersion.isEmpty
              ? 'Linked file'
              : value.installedVersion)
        : '${installed.file.name} · ${value.installedVersion}';
    final public = McSection(
      title: 'Nexus Mods',
      children: [
        if (!value.current) ...[
          McStatus(
            title: metadata == null
                ? 'Details not checked'
                : value.freshness == 'unavailable'
                ? 'This mod is unavailable'
                : value.problem.isNotEmpty
                ? 'Last check failed'
                : 'Saved details',
            detail: value.problem.isEmpty ? null : value.problem,
            tone: value.problem.isEmpty
                ? McStatusTone.neutral
                : McStatusTone.error,
          ),
          gap(),
        ],
        if (value.current && knownUpdates) ...[
          Row(
            children: [
              const Expanded(child: McStatus(title: 'Update available')),
              const SizedBox(width: 8),
              McAction(
                label: 'View updates',
                emphasis: McActionEmphasis.primary,
                onPressed: () => controller.showFiles(true),
              ),
            ],
          ),
          gap(),
        ],
        if (metadata != null) ...[
          Text(metadata.name, style: Theme.of(c).textTheme.titleLarge),
          gap(8),
          Text(metadata.summary),
          gap(),
          Wrap(
            spacing: 40,
            children: [
              fact(c, 'Installed file', installedLabel),
              fact(c, 'Nexus version', metadata.version),
            ],
          ),
          Text(
            value.checked == null
                ? 'Not checked'
                : 'Last checked ${date(value.checked)}',
            style: Theme.of(c).textTheme.bodySmall,
          ),
          gap(),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            McAction(
              label: 'Open mod page',
              icon: Icons.open_in_new,
              onPressed: controller.busy ? null : controller.openPage,
            ),
            McAction(
              label: 'Link details',
              onPressed: controller.busy
                  ? null
                  : () => linkDetails(value, installedLabel),
            ),
          ],
        ),
        if (metadata != null)
          Material(
            color: Colors.transparent,
            child: ExpansionTile(
              title: const Text('Mod details'),
              tilePadding: EdgeInsets.zero,
              children: [
                fact(c, 'Author', metadata.author),
                fact(c, 'Uploader', metadata.uploader),
                fact(c, 'Updated', date(metadata.modified)),
              ],
            ),
          ),
      ],
    );
    final state = controller.interactions;
    final account = McSection(
      title: state?.accountName == null
          ? 'Nexus account'
          : '${state!.accountName} on Nexus Mods',
      children: [
        if (state?.problem != null) ...[
          McStatus(title: state!.problem!.message, tone: McStatusTone.error),
          gap(),
        ] else if (state?.tracking == null || state?.endorsement == null) ...[
          McStatus(
            title: state?.accountName == null
                ? 'Sign in to Nexus Mods'
                : 'Account state not checked',
          ),
          gap(),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            McAction(
              label: state?.tracking == true
                  ? 'Stop tracking'
                  : 'Start tracking',
              onPressed:
                  controller.busy ||
                      state?.busy == true ||
                      state?.tracking == null
                  ? null
                  : () => controller.change(
                      state!.tracking! ? 'untrack' : 'track',
                    ),
            ),
            McAction(
              label: state?.endorsement == 'endorsed'
                  ? 'Remove endorsement'
                  : 'Endorse',
              onPressed:
                  controller.busy ||
                      state?.busy == true ||
                      state?.endorsement == null ||
                      !value.current ||
                      metadata?.allowsRating != true ||
                      value.installedVersion.isEmpty
                  ? null
                  : () => controller.change(
                      state?.endorsement == 'endorsed' ? 'abstain' : 'endorse',
                    ),
            ),
          ],
        ),
      ],
    );
    final category = McSection(
      title: 'Category',
      children: [
        fact(
          c,
          'Nexus category',
          metadata?.category.isNotEmpty == true
              ? metadata!.category
              : 'Unknown',
        ),
        fact(
          c,
          'Workspace category',
          value.categoryId == null ? 'Not mapped' : value.category,
        ),
        McAction(
          label: 'Map category',
          onPressed:
              controller.busy ||
                  metadata?.categoryId == null ||
                  widget.organization == null
              ? null
              : categoryForm,
        ),
      ],
    );
    return SingleChildScrollView(
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [public, gap(), account, gap(), category],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: public),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(children: [account, gap(), category]),
                ),
              ],
            ),
    );
  }

  void linkDetails(ModNexusDetails value, String installed) => showDialog<void>(
    context: context,
    builder: (c) => McDialog(
      title: 'Nexus link',
      actions: [
        McAction(label: 'Close', onPressed: () => Navigator.pop(c)),
        McAction(
          label: 'Remove link',
          onPressed: () {
            Navigator.pop(c);
            controller.link(null, null);
          },
        ),
        McAction(
          label: 'Change link',
          onPressed: () {
            Navigator.pop(c);
            linkForm();
          },
        ),
      ],
      children: [
        Text(value.name),
        gap(),
        fact(c, 'Nexus mod', value.metadata?.name ?? 'Linked mod'),
        fact(c, 'Installed file', installed),
        if (value.installedFile != null)
          Text(value.manual ? 'Linked manually' : 'From downloaded archive'),
      ],
    ),
  );
}
