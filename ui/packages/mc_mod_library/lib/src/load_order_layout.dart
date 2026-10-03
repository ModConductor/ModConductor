part of 'load_order_controller.dart';

extension _LoadOrderLayout on LoadOrderController {
  void _rememberLayout() {
    if (_disposed ||
        !_layoutRead ||
        reading ||
        writing ||
        _savingLayout ||
        listEquals(_layout, _persistedLayout)) {
      return;
    }
    final next = List<String>.of(_layout), epoch = _epoch;
    _savingLayout = true;
    unawaited(() async {
      try {
        await _organization!.saveLoadOrderLayout(_profile!, next);
        if (_disposed || epoch != _epoch) return;
        _persistedLayout = next;
      } on Exception {
        if (!_disposed && epoch == _epoch) {
          problem = 'Could not remember the organiser layout.';
          _notify();
        }
        return;
      } finally {
        if (!_disposed && epoch == _epoch) {
          _savingLayout = false;
          _notify();
        }
      }
      _rememberLayout();
    }());
  }
}
