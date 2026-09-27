import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'profile_mods_controller.dart';

enum _DiscoveryFeed {
  trending('Trending', 'trending'),
  latestAdded('Latest added', 'latest_added'),
  recentlyUpdated('Recently updated', 'latest_updated'),
  updates('Updates', ''),
  installed('Installed', ''),
  tracked('Tracked', 'tracked');

  const _DiscoveryFeed(this.label, this.provider);
  final String label, provider;
}

class _DiscoveryCard {
  const _DiscoveryCard(
    this.id,
    this.name,
    this.summary,
    this.author,
    this.category,
    this.picture,
  );
  final int id;
  final String name, summary, author, category;
  final Uri? picture;

  factory _DiscoveryCard.fromFeed(NexusDiscoveryMod mod) => _DiscoveryCard(
    mod.id,
    mod.name,
    mod.summary,
    mod.author,
    mod.category,
    mod.picture,
  );
  factory _DiscoveryCard.fromDetails(ModNexusDetails details) {
    final metadata = details.metadata;
    return _DiscoveryCard(
      details.reference.providerMod!,
      metadata?.name.isNotEmpty == true ? metadata!.name : details.name,
      metadata?.summary ?? '',
      metadata?.author ?? '',
      metadata?.category ?? '',
      null,
    );
  }
  _DiscoveryCard fromMod(NexusMod mod) => _DiscoveryCard(
    id,
    mod.name.isNotEmpty ? mod.name : name,
    mod.summary.isNotEmpty ? mod.summary : summary,
    mod.author.isNotEmpty ? mod.author : author,
    mod.category.isNotEmpty ? mod.category : category,
    mod.picture ?? picture,
  );
}

class NexusDiscoveryBrowser extends StatefulWidget {
  const NexusDiscoveryBrowser({
    super.key,
    required this.workspace,
    required this.profile,
    required this.nexus,
    required this.organization,
    required this.metadata,
    required this.inventory,
    required this.trackedChanges,
    required this.localChanges,
    required this.active,
    required this.onViewFiles,
  });

  final String workspace, profile;
  final NexusClient nexus;
  final ModOrganizationClient organization;
  final NexusMetadataClient metadata;
  final ProfileModsController inventory;
  final Listenable trackedChanges;
  final Listenable localChanges;
  final bool active;
  final ValueChanged<int> onViewFiles;

  @override
  State<NexusDiscoveryBrowser> createState() => _NexusDiscoveryBrowserState();
}

class _NexusDiscoveryBrowserState extends State<NexusDiscoveryBrowser> {
  _DiscoveryFeed selected = _DiscoveryFeed.trending;
  final models = <_DiscoveryFeed, McCollectionModel<int, _DiscoveryCard>>{
    for (final feed in _DiscoveryFeed.values)
      feed: McCollectionModel<int, _DiscoveryCard>(
        idOf: (card) => card.id,
        labelOf: (card) =>
            '${card.name} ${card.author} ${card.category} ${card.summary}',
      ),
  };
  final loaded = <_DiscoveryFeed>{};
  final loading = <_DiscoveryFeed>{};
  final problems = <_DiscoveryFeed, NexusProblem>{};
  final hydrating = <int>{};
  final hydrated = <int>{};
  final failedHydration = <int>{};
  final local = <int, ModNexusDetails>{};
  final updateIds = <int>{};
  final feedRequests = <_DiscoveryFeed, int>{};
  bool localLoading = false;
  bool localDirty = true;
  String? localProblem, actionProblem;
  NexusProblem? localNexusProblem;
  int epoch = 0, localRequest = 0;
  int? selectionRevision, catalogueRevision;

  @override
  void initState() {
    super.initState();
    selectionRevision = widget.inventory.revision;
    catalogueRevision = widget.inventory.catalogueRevision;
    widget.inventory.addListener(_inventoryChanged);
    widget.trackedChanges.addListener(_trackedChanged);
    widget.localChanges.addListener(_localChanged);
    if (widget.active) _activate();
  }

  void _inventoryChanged() {
    if (selectionRevision == widget.inventory.revision &&
        catalogueRevision == widget.inventory.catalogueRevision) {
      return;
    }
    selectionRevision = widget.inventory.revision;
    catalogueRevision = widget.inventory.catalogueRevision;
    _localChanged();
  }

  void _localChanged() {
    localDirty = true;
    if (widget.active) {
      unawaited(_loadLocal(refreshUpdates: selected == _DiscoveryFeed.updates));
    }
  }

  void _trackedChanged() {
    loaded.remove(_DiscoveryFeed.tracked);
    if (widget.active && selected == _DiscoveryFeed.tracked) {
      unawaited(_loadFeed(_DiscoveryFeed.tracked, force: true));
    }
  }

  void _activate() {
    unawaited(_loadFeed(selected, force: selected == _DiscoveryFeed.tracked));
    if (localDirty || selected == _DiscoveryFeed.updates) {
      unawaited(_loadLocal(refreshUpdates: selected == _DiscoveryFeed.updates));
    }
  }

  @override
  void didUpdateWidget(NexusDiscoveryBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.inventory, widget.inventory)) {
      oldWidget.inventory.removeListener(_inventoryChanged);
      selectionRevision = widget.inventory.revision;
      catalogueRevision = widget.inventory.catalogueRevision;
      widget.inventory.addListener(_inventoryChanged);
      localDirty = true;
    }
    if (!identical(oldWidget.trackedChanges, widget.trackedChanges)) {
      oldWidget.trackedChanges.removeListener(_trackedChanged);
      widget.trackedChanges.addListener(_trackedChanged);
      loaded.remove(_DiscoveryFeed.tracked);
    }
    if (!identical(oldWidget.localChanges, widget.localChanges)) {
      oldWidget.localChanges.removeListener(_localChanged);
      widget.localChanges.addListener(_localChanged);
      localDirty = true;
    }
    if (oldWidget.workspace != widget.workspace ||
        oldWidget.profile != widget.profile ||
        !identical(oldWidget.nexus, widget.nexus) ||
        !identical(oldWidget.organization, widget.organization) ||
        !identical(oldWidget.metadata, widget.metadata)) {
      ++epoch;
      loaded.clear();
      loading.clear();
      problems.clear();
      hydrating.clear();
      hydrated.clear();
      failedHydration.clear();
      local.clear();
      updateIds.clear();
      feedRequests.clear();
      localLoading = false;
      localDirty = true;
      localProblem = null;
      localNexusProblem = null;
      for (final model in models.values) {
        model.clear();
      }
      if (widget.active) _activate();
    } else if (widget.active && !oldWidget.active) {
      _activate();
    } else if (widget.active && localDirty) {
      unawaited(_loadLocal(refreshUpdates: selected == _DiscoveryFeed.updates));
    }
  }

  @override
  void dispose() {
    ++epoch;
    widget.inventory.removeListener(_inventoryChanged);
    widget.trackedChanges.removeListener(_trackedChanged);
    widget.localChanges.removeListener(_localChanged);
    for (final model in models.values) {
      model.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFeed(_DiscoveryFeed feed, {bool force = false}) async {
    if (feed.provider.isEmpty ||
        (!force && (loading.contains(feed) || loaded.contains(feed)))) {
      return;
    }
    final scope = epoch;
    final request = feedRequests.update(
      feed,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    setState(() {
      loading.add(feed);
      problems.remove(feed);
      if (force && feed == _DiscoveryFeed.tracked) {
        models[feed]!.clear();
      }
    });
    try {
      final values = await widget.nexus.discovery(
        widget.workspace,
        widget.profile,
        feed.provider,
      );
      if (!mounted || scope != epoch || feedRequests[feed] != request) return;
      final model = models[feed]!;
      model.apply(
        removed: model.ids.toList(),
        upserts: values.map(_DiscoveryCard.fromFeed),
      );
      loaded.add(feed);
    } on NexusProblem catch (error) {
      if (mounted && scope == epoch && feedRequests[feed] == request) {
        problems[feed] = error;
      }
    } finally {
      if (mounted && scope == epoch && feedRequests[feed] == request) {
        setState(() => loading.remove(feed));
      }
    }
  }

  Future<void> _loadLocal({bool refreshUpdates = false}) async {
    final scope = epoch, request = ++localRequest;
    localDirty = false;
    setState(() {
      localLoading = true;
      localProblem = null;
      localNexusProblem = null;
    });
    try {
      final nextLocal = <int, ModNexusDetails>{};
      final nextUpdates = <int>{};
      var partial = false;
      NexusProblem? partialProblem;
      ModQueryCursor? cursor;
      do {
        final page = await widget.organization.query(
          widget.profile,
          const ModQuery(
            filters: [KindFilter(ModKind.regular)],
            sort: OrganizationSort.name,
          ),
          cursor: cursor,
        );
        if (!mounted || scope != epoch || request != localRequest) return;
        for (final entry in page.entries) {
          try {
            var details = await widget.metadata.read(
              widget.workspace,
              widget.profile,
              entry.mod.id,
            );
            if (!mounted || scope != epoch || request != localRequest) return;
            var currentUpdateEvidence = true;
            if (refreshUpdates && details.reference.providerMod != null) {
              try {
                details = await widget.metadata.refresh(details.reference);
                if (!mounted || scope != epoch || request != localRequest) {
                  return;
                }
              } on NexusProblem catch (error) {
                partial = true;
                partialProblem ??= error;
                currentUpdateEvidence = false;
              }
            }
            final id = details.reference.providerMod;
            if (id != null) {
              nextLocal[id] = details;
              if (currentUpdateEvidence &&
                  details.current &&
                  details.metadata?.files.any((file) => file.update) == true) {
                nextUpdates.add(id);
              }
            }
          } on NexusProblem catch (error) {
            partial = true;
            partialProblem ??= error;
          }
        }
        cursor = page.next;
      } while (cursor != null);
      if (!mounted || scope != epoch || request != localRequest) return;
      local
        ..clear()
        ..addAll(nextLocal);
      updateIds
        ..clear()
        ..addAll(nextUpdates);
      final installed = models[_DiscoveryFeed.installed]!;
      installed.apply(
        removed: installed.ids.toList(),
        upserts: nextLocal.values.map(_DiscoveryCard.fromDetails),
      );
      final updates = models[_DiscoveryFeed.updates]!;
      updates.apply(
        removed: updates.ids.toList(),
        upserts: nextUpdates.map(
          (id) => _DiscoveryCard.fromDetails(nextLocal[id]!),
        ),
      );
      localProblem = partial ? 'Some Nexus details are not available.' : null;
      localNexusProblem = partialProblem;
      loaded.add(_DiscoveryFeed.installed);
      loaded.add(_DiscoveryFeed.updates);
    } on Exception {
      if (mounted && scope == epoch && request == localRequest) {
        localDirty = true;
        localProblem = 'Could not load installed Nexus mods.';
      }
    } finally {
      if (mounted && scope == epoch && request == localRequest) {
        setState(() => localLoading = false);
      }
    }
  }

  Future<void> _hydrate(int id, _DiscoveryFeed feed) async {
    if (!hydrating.add(id)) return;
    final scope = epoch;
    try {
      final mod = await widget.nexus.mod(widget.workspace, widget.profile, id);
      if (!mounted || scope != epoch) return;
      hydrated.add(id);
      for (final model in models.values) {
        final existing = model[id];
        if (existing != null && existing.picture == null) {
          model.apply(upserts: [existing.fromMod(mod)]);
        }
      }
    } on NexusProblem catch (error) {
      if (mounted && scope == epoch) {
        failedHydration.add(id);
        problems[feed] = error;
        setState(() {});
      }
    } finally {
      hydrating.remove(id);
    }
  }

  void _select(_DiscoveryFeed value) {
    setState(() => selected = value);
    unawaited(_loadFeed(value, force: value == _DiscoveryFeed.tracked));
    if (value == _DiscoveryFeed.updates || localDirty) {
      unawaited(_loadLocal(refreshUpdates: value == _DiscoveryFeed.updates));
    }
  }

  Future<void> _search() async {
    try {
      await widget.nexus.openSearch(widget.workspace, widget.profile);
      if (mounted) setState(() => actionProblem = null);
    } on NexusProblem catch (error) {
      if (mounted) setState(() => actionProblem = error.message);
    }
  }

  Future<void> _page(int id) async {
    try {
      await widget.nexus.openPage(widget.workspace, widget.profile, id);
      if (mounted) setState(() => actionProblem = null);
    } on NexusProblem catch (error) {
      if (mounted) setState(() => actionProblem = error.message);
    }
  }

  Widget _card(_DiscoveryFeed feed, _DiscoveryCard card) {
    if (selected == feed &&
        (feed == _DiscoveryFeed.tracked ||
            feed == _DiscoveryFeed.installed ||
            feed == _DiscoveryFeed.updates) &&
        card.picture == null &&
        !hydrating.contains(card.id) &&
        !hydrated.contains(card.id) &&
        !failedHydration.contains(card.id)) {
      Future.microtask(() => _hydrate(card.id, feed));
    }
    final details = local[card.id];
    final update = updateIds.contains(card.id);
    return McPortraitCard(
      name: card.name.isEmpty ? 'Nexus mod ${card.id}' : card.name,
      author: card.author,
      summary: card.summary,
      category: card.category,
      image: card.picture,
      status: [
        if (update) 'Update available',
        if (details != null && !update) 'Installed',
        if (feed == _DiscoveryFeed.tracked) 'Tracked',
      ],
      actions: [
        McAction(
          label: update ? 'View update' : 'View files',
          onPressed: () => widget.onViewFiles(card.id),
        ),
        McAction(
          label: 'Open mod page',
          icon: Icons.open_in_new,
          onPressed: () => unawaited(_page(card.id)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(
        builder: (context, bounds) {
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nexus Mods',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Skyrim Special Edition',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
          final search = McAction(
            label: 'Search Nexus in browser',
            icon: Icons.search,
            emphasis: McActionEmphasis.primary,
            onPressed: _search,
          );
          return bounds.maxWidth < 700
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), search],
                )
              : Row(
                  children: [
                    Expanded(child: title),
                    search,
                  ],
                );
        },
      ),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<_DiscoveryFeed>(
            segments: [
              for (final feed in _DiscoveryFeed.values)
                ButtonSegment(value: feed, label: Text(feed.label)),
            ],
            selected: {selected},
            onSelectionChanged: (value) => _select(value.single),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        selected == _DiscoveryFeed.trending
            ? 'Nexus shows up to five trending mods. This feed excludes adult and unpublished mods.'
            : selected == _DiscoveryFeed.latestAdded ||
                  selected == _DiscoveryFeed.recentlyUpdated
            ? 'Nexus shows up to ten mods in this feed.'
            : 'Only mods for Skyrim Special Edition are shown.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      if (actionProblem != null)
        McActionFeedback(
          kind: McActionFeedbackKind.failure,
          message: actionProblem!,
        ),
      if ((selected == _DiscoveryFeed.installed ||
              selected == _DiscoveryFeed.updates) &&
          (localProblem != null || localNexusProblem != null))
        McStatus(
          title: localNexusProblem?.message ?? localProblem!,
          detail: localNexusProblem?.retryAt == null
              ? null
              : 'Try again at ${TimeOfDay.fromDateTime(localNexusProblem!.retryAt!.toLocal()).format(context)}.',
          tone: McStatusTone.error,
        ),
      Expanded(
        child: IndexedStack(
          index: selected.index,
          children: [
            for (final feed in _DiscoveryFeed.values)
              ExcludeFocus(
                excluding: selected != feed,
                child: McCardGrid<int, _DiscoveryCard>(
                  model: models[feed]!,
                  card: (card) => _card(feed, card),
                  filterLabel: 'Filter shown mods',
                  loading:
                      loading.contains(feed) ||
                      ((feed == _DiscoveryFeed.installed ||
                              feed == _DiscoveryFeed.updates) &&
                          localLoading),
                  problem: problems[feed] == null
                      ? null
                      : problems[feed]!.retryAt == null
                      ? problems[feed]!.message
                      : '${problems[feed]!.message} Try again at ${TimeOfDay.fromDateTime(problems[feed]!.retryAt!.toLocal()).format(context)}.',
                  empty: problems.containsKey(feed)
                      ? 'This feed is not available. Search Nexus in your browser.'
                      : 'No mods in this collection.',
                  onActivate: (card) => widget.onViewFiles(card.id),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
