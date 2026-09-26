import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'nexus_file_widgets.dart';

class NexusFilesView extends StatefulWidget {
  const NexusFilesView({
    super.key,
    required this.client,
    required this.workspace,
    required this.profile,
    required this.onBack,
    required this.onDownloaded,
  });
  final NexusClient client;
  final String workspace;
  final String profile;
  final VoidCallback onBack;
  final Future<void> Function(Artifact) onDownloaded;
  @override
  State<NexusFilesView> createState() => _NexusFilesViewState();
}

class _NexusFilesViewState extends State<NexusFilesView> {
  final number = TextEditingController();
  final pane = GlobalKey<ScaffoldState>();
  final model = McCollectionModel<int, NexusFile>(
    idOf: (f) => f.id,
    labelOf: (f) => f.name,
  );
  NexusMod? mod;
  NexusAccount? account;
  NexusProblem? problem;
  int? refusedFile;
  bool busy = false, inspected = false;
  final requests = <int, String>{};
  bool get refused => problem?.code == 'entitlement';
  bool get blocked => busy || model.selected == null || problem != null;
  @override
  void initState() {
    super.initState();
    _status();
  }

  Future<void> _status() async {
    try {
      final value = await widget.client.status();
      if (mounted) setState(() => account = value);
    } on NexusProblem catch (error) {
      if (mounted) setState(() => problem = error);
    }
  }

  @override
  void dispose() {
    number.dispose();
    model.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final id = int.tryParse(number.text.trim());
    if (busy || id == null || id <= 0) return;
    setState(() {
      busy = true;
      problem = null;
    });
    try {
      final value = await widget.client.mod(
        widget.workspace,
        widget.profile,
        id,
      );
      if (!mounted) return;
      model.apply(removed: model.ids.toList(), upserts: value.files);
      if (value.files.isNotEmpty) model.select(value.files.first.id);
      final changedMod = mod?.id != value.id;
      setState(() {
        mod = value;
        inspected = false;
        if (changedMod) requests.clear();
        refusedFile = null;
      });
    } on NexusProblem catch (error) {
      if (mounted) setState(() => problem = error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _download() async {
    final file = model.selected, selected = mod;
    if (blocked || file == null || selected == null) return;
    setState(() => busy = true);
    try {
      final id = requests.putIfAbsent(file.id, newOperationId);
      final artifact = await widget.client.download(
        widget.workspace,
        widget.profile,
        id,
        selected.id,
        file.id,
      );
      await widget.onDownloaded(artifact);
    } on NexusProblem catch (error) {
      if (mounted)
        setState(() {
          problem = error;
          if (error.code == 'entitlement') refusedFile = file.id;
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _page() async {
    final value = mod;
    if (value == null) return;
    try {
      await widget.client.openPage(widget.workspace, widget.profile, value.id);
    } on NexusProblem catch (error) {
      if (mounted) setState(() => problem = error);
    }
  }

  Widget _downloadAction() => McAction(
    label: 'Download',
    icon: Icons.download,
    emphasis: McActionEmphasis.primary,
    onPressed: blocked ? null : _download,
  );
  Widget _pageAction() => McAction(
    label: 'Open mod page',
    icon: Icons.open_in_new,
    onPressed: busy ? null : _page,
  );
  Widget _details(VoidCallback close) => NexusFileInspector(
    file: model.selected,
    modName: mod?.name,
    accountName: account?.name,
    onClose: close,
    downloadAction: _downloadAction,
    pageAction: _pageAction,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (c, constraints) {
      final narrow =
          constraints.maxWidth < 1100 * MediaQuery.textScalerOf(c).scale(1);
      void inspect() {
        setState(() => inspected = true);
        if (narrow) pane.currentState?.openEndDrawer();
      }

      return Scaffold(
        key: pane,
        backgroundColor: Colors.transparent,
        endDrawer: narrow
            ? Drawer(
                width: 440,
                child: SafeArea(child: _details(() => Navigator.pop(c))),
              )
            : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                McIconAction(
                  label: 'Back to Archives',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: number,
                    decoration: const InputDecoration(
                      labelText: 'Nexus mod number · Skyrim Special Edition',
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _lookup(),
                  ),
                ),
                const SizedBox(width: 12),
                McAction(
                  label: 'Find',
                  icon: Icons.search,
                  onPressed: busy || account?.name == null ? null : _lookup,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (account != null && account?.name == null) ...[
              const McStatus(title: 'Nexus Mods is not connected'),
              const SizedBox(height: 12),
            ],
            if (problem case final error?) ...[
              Row(
                children: [
                  Expanded(
                    child: McStatus(
                      title: error.message,
                      detail: error.retryAt == null
                          ? null
                          : 'Try again at ${TimeOfDay.fromDateTime(error.retryAt!).format(c)}.',
                    ),
                  ),
                  if (refused) _pageAction(),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: NexusFileCollection(
                      model: model,
                      modName: mod?.name,
                      narrow: narrow,
                      busy: busy,
                      downloadAction: _downloadAction,
                      onDetails: inspect,
                      onSelect: (file) {
                        setState(() {
                          if (file.id != refusedFile) problem = null;
                          inspected = true;
                        });
                        if (narrow) pane.currentState?.openEndDrawer();
                      },
                    ),
                  ),
                  if (inspected && !narrow) ...[
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 340,
                      child: _details(() => setState(() => inspected = false)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
