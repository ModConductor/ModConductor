import 'package:flutter/widgets.dart';

class McAppMark extends StatelessWidget {
  const McAppMark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/modconductor.png',
    package: 'mc_ui_foundation',
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
}
