import 'package:flutter/foundation.dart';

class ModWorkbenchView extends ChangeNotifier {
  String _pane = 'load-order';
  String get pane => _pane;
  void select(String pane) {
    if (_pane == pane) return;
    _pane = pane;
    notifyListeners();
  }
}
