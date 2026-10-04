import 'package:flutter/material.dart';

import 'app_mark.dart';

class McAppHeader extends StatelessWidget {
  const McAppHeader({
    super.key,
    required this.appName,
    required this.actions,
    required this.navigation,
    this.workspaceName,
    this.workspacePath,
    this.workspaceNavigation,
  });

  final String appName;
  final String? workspaceName;
  final String? workspacePath;
  final List<Widget> actions;
  final Widget navigation;
  final Widget? workspaceNavigation;

  Widget _brand(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const McAppMark(size: 30),
      const SizedBox(width: 10),
      Text(appName, style: Theme.of(context).textTheme.titleMedium),
      if (workspaceName case final name?) ...[
        const SizedBox(width: 14),
        SizedBox(
          height: 20,
          child: VerticalDivider(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Tooltip(
            message: workspacePath ?? name,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ],
    ],
  );

  Widget _actions() => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: actions,
  );

  Widget _topRow(BuildContext context, BoxConstraints constraints) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1, 3);
    return constraints.maxWidth >= 1100 * scale
        ? Row(
            children: [
              Expanded(child: _brand(context)),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth - 300 * scale,
                ),
                child: _actions(),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_brand(context), const SizedBox(height: 8), _actions()],
          );
  }

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: LayoutBuilder(builder: _topRow),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: navigation,
        ),
        ?workspaceNavigation,
      ],
    ),
  );
}
