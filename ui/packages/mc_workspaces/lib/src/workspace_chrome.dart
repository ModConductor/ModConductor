import 'package:flutter/widgets.dart';

class WorkspaceChrome {
  const WorkspaceChrome({
    required this.name,
    required this.path,
    required this.actions,
    required this.navigation,
  });

  final String name;
  final String path;
  final List<Widget> actions;
  final Widget? navigation;
}

typedef WorkspaceFrameBuilder = Widget Function(
  BuildContext context,
  WorkspaceChrome? chrome,
  Widget body,
);
