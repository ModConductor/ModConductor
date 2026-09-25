import 'package:flutter/material.dart';

class McUiScale extends StatelessWidget {
  const McUiScale({super.key, required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (scale == 1) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final logicalViewport = viewport / scale;
        return FittedBox(
          fit: BoxFit.fill,
          child: SizedBox.fromSize(
            size: logicalViewport,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(size: logicalViewport),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
