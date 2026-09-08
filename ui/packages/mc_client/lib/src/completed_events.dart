// Drain terminal replies before decoding them. A typed fault must not cancel
// the HTTP/2 stream while its response trailers are still in flight.
Stream<T> completedEvents<S, T>(
  Stream<S> source,
  bool Function(S) isTerminal,
  T Function(S) decode,
) async* {
  S? terminal;
  var complete = false;
  await for (final event in source) {
    if (complete) {
      throw const FormatException('Events followed the completed operation.');
    }
    if (isTerminal(event)) {
      terminal = event;
      complete = true;
    } else {
      yield decode(event);
    }
  }
  if (!complete) {
    throw const FormatException('The operation did not return a result.');
  }
  yield decode(terminal as S);
}
