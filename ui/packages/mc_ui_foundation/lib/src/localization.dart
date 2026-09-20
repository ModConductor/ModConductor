import 'package:flutter/widgets.dart';

class McUiLabels {
  const McUiLabels({
    required this.close,
    required this.cancel,
    required this.name,
    required this.enterName,
    required this.closeInspector,
    required this.closeFilter,
    required this.noItems,
    required this.noMatches,
    required this.expanded,
    required this.collapsed,
    required this.cancelLoad,
    required this.loadMore,
    required this.retry,
    required this.refreshCollection,
    required this.collapseItem,
    required this.expandItem,
    required this.available,
    required this.unavailable,
    required this.unsupported,
    required this.information,
    required this.error,
  });

  final String close;
  final String cancel;
  final String name;
  final String enterName;
  final String closeInspector;
  final String closeFilter;
  final String noItems;
  final String noMatches;
  final String expanded;
  final String collapsed;
  final String cancelLoad;
  final String loadMore;
  final String retry;
  final String Function(String) refreshCollection;
  final String Function(String) collapseItem;
  final String Function(String) expandItem;
  final String available;
  final String unavailable;
  final String unsupported;
  final String information;
  final String error;

  static final fallback = McUiLabels(
    close: 'Close',
    cancel: 'Cancel',
    name: 'Name',
    enterName: 'Enter a name.',
    closeInspector: 'Close inspector',
    closeFilter: 'Close filter',
    noItems: 'No items.',
    noMatches: 'No matches in loaded items.',
    expanded: 'Expanded',
    collapsed: 'Collapsed',
    cancelLoad: 'Cancel load',
    loadMore: 'Load more',
    retry: 'Retry',
    refreshCollection: (title) => 'Refresh $title',
    collapseItem: (label) => 'Collapse $label',
    expandItem: (label) => 'Expand $label',
    available: 'Available',
    unavailable: 'Unavailable',
    unsupported: 'Unsupported',
    information: 'Information',
    error: 'Error',
  );
}

class McUiLocalization extends InheritedWidget {
  const McUiLocalization({
    super.key,
    required this.labels,
    required super.child,
  });

  final McUiLabels labels;

  static McUiLabels labelsOf(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<McUiLocalization>();
    return result?.labels ?? McUiLabels.fallback;
  }

  @override
  bool updateShouldNotify(McUiLocalization oldWidget) =>
      labels != oldWidget.labels;
}
