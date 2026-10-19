import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class ArchiveQueueController extends ChangeNotifier {
  ArchiveQueueController({
    required this.resolve,
    required this.refresh,
    required this.onInstalled,
  });

  final Artifact? Function(String) resolve;
  final Future<bool> Function() refresh;
  final ValueChanged<String> onInstalled;
  final List<String> _pending = [];
  Artifact? current;
  bool active = false, _committed = false, _disposed = false;
  int position = 0, total = 0, _epoch = 0;
  Object? _context;
  String? problem;

  void bind(Object context) {
    if (_context == context) return;
    _context = context;
    current = null;
    stop();
  }

  void start(List<Artifact> archives) {
    if (_disposed || active || archives.isEmpty) return;
    ++_epoch;
    problem = null;
    _pending
      ..clear()
      ..addAll(archives.map((archive) => archive.id));
    position = 0;
    total = archives.length;
    active = true;
    _advance();
  }

  void _advance() {
    if (_pending.isEmpty) {
      active = false;
    } else {
      final next = resolve(_pending.first);
      if (next == null ||
          (next.state != ArtifactState.ready &&
              next.state != ArtifactState.installed)) {
        active = false;
      } else {
        _pending.removeAt(0);
        current = next;
        ++position;
        _committed = false;
      }
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> committed(Artifact archive) async {
    if (_disposed || !identical(current, archive) || _committed) return;
    _committed = true;
    final epoch = _epoch;
    onInstalled(archive.id);
    bool refreshed;
    try {
      refreshed = await refresh();
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        problem = 'Installed mods could not be refreshed. The queue stopped.';
      }
      refreshed = false;
    }
    if (_disposed || epoch != _epoch || !active) return;
    if (!refreshed) {
      problem ??= 'Installed mods could not be refreshed. The queue stopped.';
      stop();
    } else {
      _advance();
    }
  }

  void interrupted(Artifact archive) {
    if (identical(current, archive)) stop();
  }

  void leave() {
    current = null;
    stop();
  }

  void stop() {
    ++_epoch;
    active = false;
    _pending.clear();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
