import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

class ModNexusController extends ChangeNotifier {
  NexusMetadataClient? client;
  NexusClient? nexus;
  String? workspace;
  ModNexusDetails? details;
  ModNexusInteractions? interactions;
  NexusProblem? problem;
  bool viewing = false, files = false, updates = true, busy = false;
  int _epoch = 0;
  bool _disposed = false;
  final model = McCollectionModel<int, NexusMetadataFile>(
    idOf: (f) => f.file.id,
    labelOf: (f) => f.file.name,
  );
  final requests = <int, String>{};
  int? refusedFile;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void attach(
    NexusMetadataClient? client,
    NexusClient? nexus,
    String? workspace,
  ) {
    if (identical(this.client, client) &&
        identical(this.nexus, nexus) &&
        this.workspace == workspace) {
      return;
    }
    ++_epoch;
    this.client = client;
    this.nexus = nexus;
    this.workspace = workspace;
    details = null;
    interactions = null;
    viewing = false;
    busy = false;
    problem = null;
    requests.clear();
    model.apply(removed: model.ids.toList());
    _notify();
  }

  Future<void> _run(Future<void> Function(int) action) async {
    if (busy || client == null) return;
    final epoch = _epoch;
    busy = true;
    problem = null;
    _notify();
    try {
      await action(epoch);
    } on NexusProblem catch (error) {
      if (epoch == _epoch && !_disposed) problem = error;
    } finally {
      if (epoch == _epoch && !_disposed) {
        busy = false;
        _notify();
      }
    }
  }

  bool _current(int epoch) => !_disposed && epoch == _epoch;
  void _accept(ModNexusDetails value) {
    details = value;
    _files();
  }

  void _files() {
    final all = details?.metadata?.files ?? const <NexusMetadataFile>[];
    final visible = all
        .where(
          (f) =>
              details?.current != true ||
              (updates ? f.update : !f.update && f.downloadable),
        )
        .toList();
    final selected = model.selected?.file.id;
    model.apply(removed: model.ids.toList(), upserts: visible);
    if (visible.isNotEmpty) {
      model.select(
        visible.any((f) => f.file.id == selected)
            ? selected!
            : visible.first.file.id,
      );
    }
  }

  void showFiles(bool value) {
    files = value;
    _notify();
  }

  void chooseView(bool value) {
    updates = value;
    refusedFile = null;
    _files();
    _notify();
  }

  void select(int id) {
    model.select(id);
    refusedFile = null;
    problem = null;
    _notify();
  }

  void close() {
    viewing = false;
    _notify();
  }

  Future<void> open(ModEntry mod) async {
    if (busy || workspace == null) return;
    viewing = true;
    details = null;
    interactions = null;
    files = false;
    requests.clear();
    refusedFile = null;
    await _run((epoch) async {
      final value = await client!.read(workspace!, mod.id);
      if (!_current(epoch)) return;
      _accept(value);
      final state = await client!.interactions(value.reference);
      if (!_current(epoch)) return;
      interactions = state;
    });
  }

  Future<void> readAccount() => _run((epoch) async {
    final original = details;
    if (original == null) return;
    final state = await client!.interactions(original.reference);
    if (_current(epoch)) {
      interactions = state;
    }
  });

  Future<void> refresh() => _run((epoch) async {
    final original = details;
    if (original == null) return;
    final value = await client!.refresh(original.reference);
    if (!_current(epoch)) return;
    _accept(value);
    refusedFile = null;
    final state = await client!.interactions(value.reference);
    if (!_current(epoch)) return;
    interactions = state;
  });
  Future<void> link(int? mod, int? file) => _run((epoch) async {
    final original = details;
    if (original == null) return;
    final value = await client!.link(original.reference, mod, file);
    if (!_current(epoch)) return;
    _accept(value);
    requests.clear();
    refusedFile = null;
    final state = await client!.interactions(value.reference);
    if (_current(epoch)) interactions = state;
  });
  Future<void> map(String category) => _run((epoch) async {
    final original = details;
    if (original == null) return;
    final value = await client!.mapCategory(
      original.reference,
      category,
      original.metadata!.categoryId!,
    );
    if (_current(epoch)) _accept(value);
  });
  Future<void> change(String action) => _run((epoch) async {
    final original = details, state = interactions;
    if (original == null || state == null) return;
    final value = await client!.change(
      original.reference,
      state.revision,
      action,
    );
    if (_current(epoch)) {
      interactions = value;
    }
  });
  Future<Artifact?> download() async {
    Artifact? result;
    await _run((epoch) async {
      final original = details, file = model.selected;
      if (original == null ||
          file == null ||
          !original.current ||
          refusedFile == file.file.id) {
        return;
      }
      try {
        final artifact = await client!.download(
          original.reference,
          file.file.id,
          updates,
          requests.putIfAbsent(file.file.id, newOperationId),
        );
        if (_current(epoch)) result = artifact;
      } on NexusProblem catch (error) {
        if (_current(epoch) &&
            (error.code == 'entitlement' || error.code == 'forbidden')) {
          refusedFile = file.file.id;
        }
        rethrow;
      }
    });
    return result;
  }

  Future<void> openPage() => _run((_) async {
    final value = details?.reference;
    if (value?.providerMod == null) return;
    await nexus?.openPage(value!.workspace, value.providerMod!);
  });
  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    model.dispose();
    super.dispose();
  }
}
