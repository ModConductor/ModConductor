import 'package:mc_client/mc_client.dart';

class LoadOrderRow {
  const LoadOrderRow({
    required this.id,
    required this.name,
    required this.type,
    this.plugin,
    this.source,
    this.copy,
    this.parent,
  });
  final String id, name, type;
  final String? parent;
  final PluginEntry? plugin;
  final ProfileMod? source;
  final ManagedFileCopy? copy;
  bool get group => source != null;
  static String pluginId(String name) => 'plugin:${name.toLowerCase()}';
  static String sourceId(String id) => 'files:$id';
}

List<String> reconcileLoadOrder(
  List<String> layout,
  List<String> plugins,
  List<String> files,
) {
  final pluginSet = plugins.toSet(), fileSet = files.toSet();
  final slots = layout
      .where((id) => pluginSet.contains(id) || fileSet.contains(id))
      .toList();
  final present = slots.toSet();
  for (final id in [...plugins, ...files]) {
    if (present.add(id)) slots.add(id);
  }
  final pluginOrder = plugins.iterator, fileOrder = files.iterator;
  return [
    for (final id in slots)
      if (id.startsWith('plugin:'))
        (() {
          pluginOrder.moveNext();
          return pluginOrder.current;
        })()
      else
        (() {
          fileOrder.moveNext();
          return fileOrder.current;
        })(),
  ];
}
