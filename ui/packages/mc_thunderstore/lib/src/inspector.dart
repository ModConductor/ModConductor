part of 'browser.dart';

extension _ThunderstoreInspector on _ThunderstoreBrowserState {
  String _installed(List<ThunderstoreInstalled> installed, [String? version]) {
    final versions = installed.map((entry) => entry.reference.version).toSet();
    if (versions.isEmpty) return 'Not in library';
    if (version != null && versions.contains(version))
      return '$version in library';
    return '${versions.join(', ')} in library';
  }

  List<String> _versions(ThunderstorePackageInfo value) {
    final sorted = value.versions.toList()
      ..sort((a, b) {
        final left = a.split('.').map((v) => int.tryParse(v) ?? 0).toList();
        final right = b.split('.').map((v) => int.tryParse(v) ?? 0).toList();
        for (var i = 0; i < left.length && i < right.length; i++) {
          final order = right[i].compareTo(left[i]);
          if (order != 0) return order;
        }
        return right.length.compareTo(left.length);
      });
    return sorted;
  }

  Widget _dependency(BuildContext context, ThunderstoreDependency value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _artwork(value.icon, 40),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.reference.package.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${value.reference.package.namespace} · ${value.reference.version}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value.available
                  ? _installed(value.installed, value.reference.version)
                  : 'Not available',
              style: TextStyle(
                fontSize: 12,
                color: value.available
                    ? null
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _inspector(BuildContext context) {
    final value = controller.details;
    return McInspector(
      title: controller.selected!.name,
      onClose: controller.running ? null : controller.closeDetails,
      footer: _acquisitionFooter(context),
      children: [
        if (controller.detailLoading) const LinearProgressIndicator(),
        if (controller.detailProblem != null) ...[
          McStatus(
            title: controller.detailProblem!.message,
            tone: McStatusTone.error,
          ),
          const SizedBox(height: 12),
        ],
        if (value != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _artwork(value.icon, 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.reference.package.namespace,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Valheim${value.categories.isEmpty ? '' : ' · ${value.categories.join(', ')}'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              McIconAction(
                label: 'Open Thunderstore page',
                icon: const Icon(Icons.open_in_new, size: 18),
                onPressed: () => unawaited(controller.openPage()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Tooltip(
            message: value.description,
            child: Text(
              value.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          if (value.deprecated) ...[
            const McStatus(
              title: 'Deprecated package',
              tone: McStatusTone.error,
            ),
            const SizedBox(height: 12),
          ],
          McChoice<String>(
            label: 'Version',
            value: value.reference.version,
            choices: _versions(value),
            describe: (version) =>
                version == value.latestVersion ? '$version (latest)' : version,
            enabled: !controller.running && !controller.detailLoading,
            onChanged: (version) => unawaited(
              controller.inspect(value.reference.package, version: version),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _installed(value.installed, value.reference.version),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Required dependencies',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (value.dependencies.isEmpty) const Text('None'),
          for (final dependency in value.dependencies) ...[
            _dependency(context, dependency),
            const SizedBox(height: 12),
          ],
        ],
        if (value == null && !controller.detailLoading)
          McAction(
            label: 'Retry',
            icon: Icons.refresh,
            onPressed: () =>
                unawaited(controller.inspect(controller.selected!)),
          ),
      ],
    );
  }
}
