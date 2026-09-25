import 'package:flutter/material.dart';

class McUiScale extends StatelessWidget {
  const McUiScale({super.key, required this.scale, required this.child});

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_McUiScaleValue>()?.scale ?? 1;

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
              child: _McUiScaleValue(scale: scale, child: child),
            ),
          ),
        );
      },
    );
  }
}

class _McUiScaleValue extends InheritedWidget {
  const _McUiScaleValue({required this.scale, required super.child});

  final double scale;

  @override
  bool updateShouldNotify(_McUiScaleValue oldWidget) =>
      scale != oldWidget.scale;
}
