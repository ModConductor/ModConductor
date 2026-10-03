part of 'load_order_controller.dart';

extension _LoadOrderFiles on LoadOrderController {
  Future<void> _readFiles(ModEntry source) async {
    final library = _library, version = source.currentVersionId, epoch = _epoch;
    if (library == null || version == null) return;
    _loading.add(source.id);
    try {
      final files = <LoadOrderRow>[];
      int? offset = 0;
      do {
        final page = await library.version(version, offset: offset!);
        if (_disposed || epoch != _epoch || _versions[source.id] != version) {
          return;
        }
        for (final file in page.entries) {
          final path = file.path.join('/');
          final isPlugin = _plugins.any(
            (plugin) =>
                [
                  if (plugin.winner != null) plugin.winner!,
                  ...plugin.alternatives,
                ].any(
                  (copy) =>
                      copy.modId == source.id &&
                      copy.versionId == version &&
                      copy.path.toLowerCase() == path.toLowerCase(),
                ),
          );
          if (isPlugin) continue;
          files.add(
            LoadOrderRow(
              id: 'copy:${source.id}:$version:${jsonEncode(file.path)}',
              parent: LoadOrderRow.sourceId(source.id),
              name: path,
              type: 'File',
              copy: ManagedFileCopy(source.id, version, file.path),
            ),
          );
        }
        offset = page.nextOffset;
      } while (offset != null);
      _files[source.id] = files;
      _project();
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error is LibraryException
            ? error.detail
            : 'Could not load the source files.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        _loading.remove(source.id);
        if (_versions[source.id] != version) _expanded();
        _notify();
      }
    }
  }
}
